// Plarail to Lego adapter rail
// A short track segment (4 Lego studs long) with Plarail connections on the ends
// and Lego-compatible tube connections on the bottom.

/* [Dimensions] */
// --- Base Dimensions ---
length = 53.0; // Total track length excluding joint
width = 38.0;  // Standard Plarail width
height = 8.0;  // Overall thickness

// --- Plarail Track Parameters ---
groove_width = 8.0;
groove_depth = 3.5;
groove_distance = 28.0; // Distance between the centers of the two grooves

// --- Plarail Joint Parameters (Wedge Shape) ---
joint_thickness = 8.0; // Same thickness as main body
joint_z_offset = 0.0; // Offset from the bottom
joint_base_width = 9.0;     // Width at the narrow root
joint_tip_width = 12.5;     // Width at the wide tip
joint_length = 11.0;        // Total extension length
joint_clearance = 0.3;      // Tolerance for female socket

// --- Lego Connection Parameters ---
lego_pitch = 8.0;
lego_cavity_min_x = -14.5;  // Left limit, clears the female joint cutout
lego_cavity_max_x = 25.5;   // Right limit (-14.5 + 40.0 = 25.5), ensures exactly 40mm length cavity
lego_tube_od = 6.4;         // Tube outer diameter (Lego standard ~ 6.51mm, slightly less for tolerance)
lego_tube_id = 4.9;         // Tube inner diameter (Lego standard ~ 4.8mm)
lego_tube_height = 1.8;     // Insertion depth (cylinder height) for Lego compatibility

/* [Hidden] */
$fn = 60; // Smoothness for cylinders

// --- Main Module ---
module plarail_lego_adapter() {
    difference() {
        union() {
            // --- BASE SHAPE MINUS BOTTOM CAVITY ---
            difference() {
                union() {
                    // STEP 1: Main body
                    translate([-length/2, -width/2, 0])
                        cube([length, width, height]);
                    
                    // STEP 2: Add Plarail Male Joint
                    translate([length/2, 0, joint_z_offset])
                        plarail_joint_positive();
                }
                
                // STEP 1.5 & 8: Unified Bottom Cavity (Lego + Male Joint Hollow)
                // Mathematically guarantees exactly a 1mm wall at the joint root while connecting cavities.
                translate([0, 0, -0.1])
                    linear_extrude(height=lego_tube_height + 0.1)
                        offset(delta=-1.0)
                            union() {
                                translate([lego_cavity_min_x - 1.0, -width/2 - 1.1])
                                    square([(length/2) - (lego_cavity_min_x - 1.0), width + 2.2]);
                                translate([length/2, 0])
                                    plarail_joint_base2D(0);
                            }
            }
                
            // STEP 3: Add Lego Tubes inside the already-hollowed cavity
            // 4x3 array shifted to center perfectly in the 40mm cavity
            for(x = [-6.5 : 8 : 17.5]) {
                for(y = [-8 : 8 : 8]) {
                    translate([x, y, 0])
                        cylinder(h = lego_tube_height, d = lego_tube_od);
                }
            }
        }
        
        // --- REMAINING SUBTRACTIONS ---
        
        // STEP 4: Lego Tube Inner Holes
        for(x = [-6.5 : 8 : 17.5]) {
            for(y = [-8 : 8 : 8]) {
                translate([x, y, -0.1])
                    cylinder(h = lego_tube_height + 0.2, d = lego_tube_id);
            }
        }
        
        // STEP 5: Plarail Wheel Grooves (Top)
        for (y = [-groove_distance/2, groove_distance/2]) {
            translate([-length/2 - 5, y - groove_width/2, height - groove_depth])
                cube([length + 10 + joint_length + 5, groove_width, groove_depth + 1]); 
        }
        
        // STEP 5.1: Plarail Wheel Grooves (Bottom)
        // Enables trains to ride on the bottom surface. Digs up to 1.8mm depth to match the Lego connection cavity.
        // Only created on the female joint side (left) to prevent cutting through the Lego connection's right enclosing wall.
        // Extended by +1.0mm into the Lego cavity to ensure a clean visual connection without preview wall artifacts.
        for (y = [-groove_distance/2, groove_distance/2]) {
            translate([-length/2 - 5, y - groove_width/2, -0.1])
                cube([lego_cavity_min_x - (-length/2 - 5) + 1.0, groove_width, lego_tube_height + 0.1]); 
        }
        
        // STEP 5.5: Unified Center and Male Joint Hollow
        // Uses a single 2D polygon offset to mathematically guarantee exactly a 1mm wall, avoiding separating walls from union block boundaries.
        center_hollow_width = groove_distance - groove_width - 2.0; 
        hollow_start_x = -length/2 + joint_length + joint_clearance + 1.0;
        translate([0, 0, height - 3.5])
            linear_extrude(height=3.5 + 1.0)
                offset(delta=-1.0)
                    polygon([
                        [hollow_start_x - 1.0, -(center_hollow_width + 2.0)/2],
                        [length/2, -(center_hollow_width + 2.0)/2],
                        [length/2, -joint_base_width/2],
                        [length/2 + joint_length, -joint_tip_width/2],
                        [length/2 + joint_length, joint_tip_width/2],
                        [length/2, joint_base_width/2],
                        [length/2, (center_hollow_width + 2.0)/2],
                        [hollow_start_x - 1.0, (center_hollow_width + 2.0)/2]
                    ]);
                    
        // STEP 6: Plarail Female Joint Cutout
        // Female joint remains full thickness cutout as standard.
        translate([-length/2, 0, joint_z_offset])
            plarail_joint_negative();
            
        // STEP 7: Male Joint Flex Slit
        // 1.5mm wide, 6mm long slit at the center tip of the male joint to allow flexing
        translate([length/2 + joint_length - 6.0, -1.5/2, -0.1])
            cube([6.0 + 0.2, 1.5, height + 0.2]);
            
        // STEP 9: Female Joint Flex Slits
        // 1.5mm wide, 6mm long slits going into the wheel groove floors.
        // This frees the female socket's prongs (and the adjacent wall) to flex outward during rail insertion.
        for (y_sign = [-1, 1]) {
            translate([-length/2 - 0.1, y_sign * (groove_distance/2 - groove_width/2) + (y_sign > 0 ? 0 : -1.5), -0.1])
                cube([6.0 + 0.1, 1.5, height + 0.2]);
        }
        
        // STEP 10: Non-slip Wheel Groove Texture (Top)
        // Cuts 0.4mm wide, 0.2mm deep fine transverse grooves across the top wheel tracks for traction. 
        // A 0.8mm pitch exactly mimics the authentic traction texture of Plarail tracks.
        for (y = [-groove_distance/2, groove_distance/2]) {
            for (x = [-length/2 + 1 : 0.8 : length/2]) {
                translate([x, y - groove_width/2, height - groove_depth - 0.2])
                    cube([0.4, groove_width, 0.2 + 0.1]);
            }
        }
    }
}

// --- Helper Modules ---

module plarail_joint_base2D(clr=0) {
    // clr governs the clearance for the female part.
    offset(delta=clr)
        polygon(points=[
            [0, joint_base_width/2],
            [joint_length, joint_tip_width/2],
            [joint_length, -joint_tip_width/2],
            [0, -joint_base_width/2]
        ]);
}

// Positive male joint
module plarail_joint_positive() {
    linear_extrude(height=joint_thickness)
        plarail_joint_base2D(0);
}

// Negative female joint cutout
module plarail_joint_negative() {
    clr = joint_clearance;
    // We add clearance in 2D and then extrude with extra Z clearance to fully punch through
    translate([-0.1, 0, -0.1])
        linear_extrude(height=joint_thickness + 0.5)
            plarail_joint_base2D(clr);
}

// Render
plarail_lego_adapter();
