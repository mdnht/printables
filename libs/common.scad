// common.scad - Shared utility library for all projects
//
// Usage:
//   use <../../libs/common.scad>
//
// Provides: rounded_box, cylinder_with_hole, chamfer_box

// Rounded rectangular box
// Parameters:
//   size  - [x, y, z] dimensions
//   r     - corner radius
//   fn    - number of fragments for curves
module rounded_box(size, r = 2, fn = 32) {
    x = size[0];
    y = size[1];
    z = size[2];
    hull() {
        for (dx = [r, x - r], dy = [r, y - r]) {
            translate([dx, dy, 0])
                cylinder(r = r, h = z, $fn = fn);
        }
    }
}

// Hollow cylinder (tube)
// Parameters:
//   h          - height
//   r_outer    - outer radius
//   r_inner    - inner radius
//   fn         - number of fragments
module cylinder_with_hole(h, r_outer, r_inner, fn = 32) {
    difference() {
        cylinder(h = h, r = r_outer, $fn = fn);
        translate([0, 0, -0.1])
            cylinder(h = h + 0.2, r = r_inner, $fn = fn);
    }
}

// Box with chamfered (angled) top edges
// Parameters:
//   size    - [x, y, z] dimensions
//   chamfer - chamfer size
module chamfer_box(size, chamfer = 1) {
    x = size[0];
    y = size[1];
    z = size[2];
    hull() {
        cube([x, y, z - chamfer]);
        translate([chamfer, chamfer, 0])
            cube([x - 2 * chamfer, y - 2 * chamfer, z]);
    }
}

// M-size screw hole (vertical, countersunk optional)
// Parameters:
//   d          - nominal diameter (e.g. 3 for M3)
//   h          - depth of hole
//   countersink - if true, adds countersink at top
//   fn         - number of fragments
module screw_hole(d, h, countersink = false, fn = 32) {
    r = d / 2;
    union() {
        translate([0, 0, -0.1])
            cylinder(h = h + 0.2, r = r, $fn = fn);
        if (countersink) {
            translate([0, 0, h - d])
                cylinder(h = d + 0.1, r1 = r, r2 = r * 2, $fn = fn);
        }
    }
}
