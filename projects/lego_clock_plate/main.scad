/*
 * LEGO-Compatible Clock Baseplate (Double-sided compatible)
 * Designed for 3D printing a clock face that can be decorated with LEGO.
 */

// --- Parameters ---
studs_x = 16;        // Number of studs in X direction
studs_y = 16;        // Number of studs in Y direction
plate_h = 3.2;       // Total height of the plate body (standard LEGO = 3.2mm)
hole_dia = 8.0;      // Diameter of the center hole for the clock shaft
stud_dia = 4.96;      // Standard LEGO stud diameter
stud_h = 1.7;        // Standard LEGO stud height
pitch = 8.0;         // Distance between centers
tolerance = 0.2;     // Tolerance for the overall size

// Mounting area (top and bottom)
top_mount_dia = 15.0;   // Diameter of the flat area on top (flush with studs)
mount_solid_dia = 20.0; // Solid area around center hole on the bottom

// Underside dimensions
wall_th = 1.2;       // Side wall thickness
floor_th = 1.2;      // Top surface thickness
tube_od = 6.38;      // Underside tube outer diameter
tube_id = 5.2;       // Underside tube inner diameter (+0.4mm)

$fn = 64;

// --- Calculated Values ---
total_width = studs_x * pitch - tolerance;
total_depth = studs_y * pitch - tolerance;
hollow_h = plate_h - floor_th;

module lego_clock_plate() {
    difference() {
        union() {
            // 1. Main Plate Body (Shell)
            difference() {
                // Outer box
                translate([-total_width/2, -total_depth/2, 0])
                    cube([total_width, total_depth, plate_h]);
                
                // Hollow out the bottom
                translate([0, 0, -0.1])
                difference() {
                    translate([-total_width/2 + wall_th, -total_depth/2 + wall_th, 0])
                        cube([total_width - wall_th*2, total_depth - wall_th*2, hollow_h + 0.1]);
                    
                    // Keep center area solid for mounting strength
                    cylinder(d = mount_solid_dia, h = hollow_h + 0.2);
                }
            }

            // 2. Top Flat Mounting Surface (Flush with studs)
            cylinder(d = top_mount_dia, h = plate_h + stud_h);
            
            // 3. Studs (Top)
            for (x = [0 : studs_x - 1]) {
                for (y = [0 : studs_y - 1]) {
                    pos_x = (x - (studs_x - 1) / 2) * pitch;
                    pos_y = (y - (studs_y - 1) / 2) * pitch;
                    
                    dist = sqrt(pow(pos_x, 2) + pow(pos_y, 2));
                    // Remove studs that overlap with the top mounting surface
                    if (dist > (top_mount_dia / 2 + stud_dia / 2)) {
                        translate([pos_x, pos_y, plate_h])
                            cylinder(d = stud_dia, h = stud_h);
                    }
                }
            }

            // 4. Tubes (Bottom)
            for (x = [0 : studs_x - 2]) {
                for (y = [0 : studs_y - 2]) {
                    pos_x = (x - (studs_x - 2) / 2) * pitch;
                    pos_y = (y - (studs_y - 2) / 2) * pitch;
                    
                    dist = sqrt(pow(pos_x, 2) + pow(pos_y, 2));
                    if (dist > (mount_solid_dia / 2 - 1)) {
                        translate([pos_x, pos_y, 0])
                        difference() {
                            cylinder(d = tube_od, h = hollow_h);
                            translate([0, 0, -0.1])
                                cylinder(d = tube_id, h = hollow_h + 0.2);
                        }
                    }
                }
            }
        }
        
        // 5. Center hole for clock movement
        translate([0, 0, -1])
            cylinder(d = hole_dia, h = plate_h + stud_h + 2);

        // 6. Recess on the bottom (15mm dia, 1mm deep)
        translate([0, 0, -0.1])
            cylinder(d = 15.0, h = 1.0 + 0.1);
    }
}

// Render the plate
render() { lego_clock_plate(); }

// --- Visualization ---
// Clock movement dummy: 5.5cm x 5.5cm, 1.6cm thickness
movement_size = 55; 
movement_thick = 16; 

%translate([0, 0, -movement_thick / 2])
    cube([movement_size, movement_size, movement_thick], center = true);
