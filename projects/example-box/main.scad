// example-box/main.scad
// A simple parametric storage box that demonstrates shared library usage.
//
// Build with:
//   python ../../scripts/bundle.py main.scad -o ../../dist/example-box.scad

use <../../libs/common.scad>

/* [Box Dimensions] */
// Width of the box (mm)
box_width  = 60;
// Depth of the box (mm)
box_depth  = 40;
// Height of the box body (mm)
box_height = 30;
// Wall thickness (mm)
wall = 2;
// Corner radius (mm)
corner_radius = 3;

/* [Lid] */
// Include lid in render
show_lid = true;
// Gap between lid and box (mm)
lid_gap = 0.2;
// Lid height (mm)
lid_height = 8;

/* [Hidden] */
$fn = 48;

// ── Main assembly ───────────────────────────────────────────────────────────

// Box body
color("SteelBlue")
    box_body();

// Lid (offset upward for preview)
if (show_lid) {
    color("LightSteelBlue")
        translate([0, 0, box_height + 5])
            lid();
}

// ── Modules ─────────────────────────────────────────────────────────────────

module box_body() {
    difference() {
        // Outer shell
        rounded_box([box_width, box_depth, box_height], r = corner_radius);
        // Inner cavity
        translate([wall, wall, wall])
            rounded_box(
                [box_width  - 2 * wall,
                 box_depth  - 2 * wall,
                 box_height - wall + 0.1],
                r = max(corner_radius - wall, 0.5)
            );
        // Lid channel (top rim cutout for lip fit)
        translate([wall, wall, box_height - lid_height / 2])
            rounded_box(
                [box_width  - 2 * wall,
                 box_depth  - 2 * wall,
                 lid_height / 2 + 0.1],
                r = max(corner_radius - wall, 0.5)
            );
    }
}

module lid() {
    lip_h = lid_height / 2;
    difference() {
        union() {
            // Lid top plate
            rounded_box([box_width, box_depth, wall], r = corner_radius);
            // Lid inner lip
            translate([wall + lid_gap, wall + lid_gap, -lip_h])
                rounded_box(
                    [box_width  - 2 * (wall + lid_gap),
                     box_depth  - 2 * (wall + lid_gap),
                     lip_h],
                    r = max(corner_radius - wall - lid_gap, 0.5)
                );
        }
    }
}
