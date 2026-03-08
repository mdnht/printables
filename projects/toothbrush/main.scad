// Electric Toothbrush Holder
// Assumed neck diameter: approx 8mm

/* [Basic Settings] */
// Number of toothbrush slots
num_slots = 3;          // [1:1:10]
// Number of interdental brush / floss holes (0 to Number of slots + 1)
num_floss_holes = 2;    // [0:1:11]

// Diameter of toothbrush holes (mm)
neck_dia = 7.0;         // [5.0:0.1:15.0]
// Diameter of floss / interdental brush holes (mm)
floss_hole_dia = 5.0;   // [3.0:0.1:10.0]

/* [Mounting Settings] */
// Magnet sheet or double-sided tape thickness (mm). Set to 0.0 for a flat back.
tape_magnet_thickness = 1.0; // [0.0:0.1:3.0]

// Diameter of screw holes (mm). Set to 0.0 if you don't use screws.
screw_hole_dia = 0.0; // [0.0:0.1:10.0]

/* [Hidden] */
// Slot width for insertion/removal is slightly narrower than the hole diameter to create a catch
slot_width = neck_dia - 0.5;

// Space between brushes (mm)
slot_spacing = 30;

// Smoothness of circles
$fn = 60;

// --- Parameters ---
holder_thickness = 3.0; // Thickness of the horizontal holder part
holder_depth = 25.0;    // Depth protruding forward (mm)
body_length = (num_slots + 1) * slot_spacing; // Total width

back_thickness = 3.0;   // Thickness of the backplate (slightly thicker to include magnet recess)
back_height = 30.0;     // Height of the backplate for attaching the magnet
magnet_margin = 5.0;    // Margin around the magnet recess

fillet_r = 5.0;         // Fillet radius for all corners

// Helper module to create a board with rounded corners (XY plane: for holder, back corners remain square)
module holder_shape(size, r, center = false) {
    x = size[0]; y = size[1]; z = size[2];
    translate(center ? [-x/2, -y/2, -z/2] : [0,0,0])
        union() {
            // Back side
            translate([0, 0, 0]) cube([x, y-r, z]);
            // Front rounded corners
            hull() {
                translate([r, y-r, 0]) cylinder(h=z, r=r);
                translate([x-r, y-r, 0]) cylinder(h=z, r=r);
            }
        }
}

// Helper module for backplate: rounded corners (XZ plane, top corners remain square)
module backplate_shape(size, r, center = false) {
    x = size[0]; y = size[1]; z = size[2];
    translate(center ? [-x/2, -y/2, -z/2] : [0,0,0])
        union() {
            // Top side
            translate([0, 0, r]) cube([x, y, z-r]);
            // Bottom rounded corners
            hull() {
                translate([r, 0, r]) rotate([-90, 0, 0]) cylinder(h=y, r=r);
                translate([x-r, 0, r]) rotate([-90, 0, 0]) cylinder(h=y, r=r);
            }
        }
}

// Fillet to smoothly connect the inner joint of the L-shape
module L_fillet(length, r) {
    difference() {
        translate([0, r/2, -r/2]) cube([length, r, r], center=true);
        translate([0, r, -r]) rotate([0, 90, 0]) cylinder(h=length+0.1, r=r, center=true);
    }
}

// Module to chamfer the top and bottom edges of a hole (Chamfer C=1.0, 45 degrees)
module chamfered_hole(dia, h, chamfer = 1.0) {
    // Straight through-hole
    translate([0, 0, -1]) cylinder(h = h + 2, d = dia);
    // Top chamfer (around Z=h)
    translate([0, 0, h - chamfer]) cylinder(h = chamfer + 1, d1 = dia, d2 = dia + 2 * (chamfer + 1));
    // Bottom chamfer (around Z=0)
    translate([0, 0, -1]) cylinder(h = chamfer + 1, d1 = dia + 2 * (chamfer + 1), d2 = dia);
}

module toothbrush_holder() {
    difference() {
        // L-shaped base combining the backplate attached to the wall and the protruding holder
        union() {
            // 1. Horizontal holder part with slots
            translate([0, back_thickness + holder_depth / 2, holder_thickness / 2])
                holder_shape([body_length, holder_depth, holder_thickness], r=fillet_r, center = true);
            
            // 2. Vertical backplate for attaching the magnet
            translate([0, back_thickness / 2, holder_thickness - back_height / 2])
                backplate_shape([body_length, back_thickness, back_height], r=fillet_r, center = true);
                
            // 3. Fillet connecting the inner joint smoothly
            translate([0, back_thickness, 0])
                L_fillet(body_length, fillet_r);
        }
        
        // 4. Recess on the back for embedding the magnet sheet or tape
        // Recess from the Y=0 side (surface touching the wall)
        if (tape_magnet_thickness > 0) {
            translate([0, tape_magnet_thickness / 2 - 0.1, holder_thickness - back_height / 2])
                backplate_shape([body_length - magnet_margin * 2, tape_magnet_thickness + 0.2, back_height - magnet_margin * 2], r=max(fillet_r - magnet_margin, 0.1), center = true);
        }
        
        // 4.5 Screw holes
        if (screw_hole_dia > 0) {
            screw_x_offset = body_length / 2 - 10; // Placed 10mm from both ends
            screw_z_offset = holder_thickness - back_height / 2; // Center of the backplate
            
            for (x_pos = [-screw_x_offset, screw_x_offset]) {
                // Through hole
                translate([x_pos, -1, screw_z_offset])
                    rotate([-90, 0, 0])
                    cylinder(h = back_thickness + 2, d = screw_hole_dia);
                
                // Countersink (screw head on Y=back_thickness side, pointing towards Y=0)
                countersink_depth = screw_hole_dia * 0.6;
                translate([x_pos, back_thickness - countersink_depth + 0.01, screw_z_offset])
                    rotate([-90, 0, 0])
                    cylinder(h = countersink_depth, d1 = screw_hole_dia, d2 = screw_hole_dia + countersink_depth * 2.0);
            }
        }
        
        // Cut out slots for hanging brushes
        for (i = [0 : num_slots - 1]) {
            x_pos = -body_length / 2 + slot_spacing + (i * slot_spacing);
            
            // Round hole: Chamfered hole for the neck
            translate([x_pos, back_thickness + holder_depth * 0.4, 0])
                chamfered_hole(dia = neck_dia, h = holder_thickness, chamfer = 1.0);
            
            // Slot: Opening straight forward from the round hole
            translate([x_pos, back_thickness + holder_depth * 0.4 + holder_depth / 2, holder_thickness / 2])
                cube([slot_width, holder_depth, holder_thickness + 2], center = true);
                
            // Chamfer at the slot entrance
            translate([x_pos - slot_width / 2 - fillet_r, back_thickness + holder_depth - fillet_r, -1])
                difference() {
                    cube([fillet_r + 0.1, fillet_r + 0.1, holder_thickness + 2]);
                    translate([0, 0, -1]) cylinder(h = holder_thickness + 4, r = fillet_r);
                }
            translate([x_pos + slot_width / 2 - 0.1, back_thickness + holder_depth - fillet_r, -1])
                difference() {
                    cube([fillet_r + 0.1, fillet_r + 0.1, holder_thickness + 2]);
                    translate([fillet_r + 0.1, 0, -1]) cylinder(h = holder_thickness + 4, r = fillet_r);
                }
        }
        
        // 5. Place holes for floss / interdental brushes in empty spaces (both ends and between holders)
        // Up to (num_slots + 1) holes can be placed
        if (num_floss_holes > 0) {
            actual_holes = min(num_floss_holes, num_slots + 1);
            for (k = [0 : actual_holes - 1]) {
                // 1st hole is at the left end (midpoint between plate edge and left edge of the first toothbrush hole)
                // 2nd hole is at the right end (midpoint between plate edge and right edge of the last toothbrush hole)
                // 3rd and subsequent holes are between holders (midpoint between toothbrush holes)
                x_pos = (k == 0) ? -body_length / 2 + slot_spacing / 2 - neck_dia / 4 :
                        (k == 1) ?  body_length / 2 - slot_spacing / 2 + neck_dia / 4 :
                        -body_length / 2 + slot_spacing * 1.5 + (k - 2) * slot_spacing;
                
                // Position slightly forward (Y direction) to avoid interference with brush handles
                translate([x_pos, back_thickness + holder_depth * 0.65, 0])
                    chamfered_hole(dia = floss_hole_dia, h = holder_thickness, chamfer = 1.0);
            }
        }
    }
}

// Execute rendering
// Draw the main body (integrated)
color("WhiteSmoke") toothbrush_holder();

