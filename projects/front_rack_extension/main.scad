

// TUBUS GRAND EXPEDITION Front Rack Extension
// Hook-and-notch flush joint design with deep 5 o'clock outer wrap.
// Fixed the bridge integration so the top and bottom merge seamlessly
// with the hook ring.

/* [Which part to render] */
part = 0; // [0:assembly, 1:leg_left, 2:leg_right, 3:deck_board, 4:print_layout, 5:spacer, 6:exploded_assembly]

/* [Dimensions] */
rack_outer_width = 102;
tube_dia         = 12;
rack_length      = 90;
clip_length      = 24;
clip_y_offset    = 5.5;
deck_w           = 150;
deck_height      = 130;
beam_thick       = 3.5;
beam_w           = 45;

/* [Component Design] */
board_w   = 18;    // Width of each deck board (shrunk to 18mm, outer edge aligns perfectly with clip)
leg_w     = 14;    // Width of the flat leg face (Uniform 14mm, matching top cylinder)
leg_t     = 6;     // Thickness of the leg (Increased to 6)
side_dim  = 14;    // Side beam outer dimension/head (matches hook)
sq_size   = 5.5;     // Square side beam width/height (reduced for stronger hook walls)
joint_h   = 22;    // Height of the joint head (now redundant but kept for any offset needs)
bolt_d    = 4.4;   // Bolt hole diameter (M4 loose fit)
nut_w     = 7.2;   // Nut width (flat-to-flat)
nut_h     = 3.4;   // Nut height

/* [Hook Joint] */
hook_wall  = 2.5;
hook_clear = 0.2;
notch_r    = side_dim/2 - hook_wall;
hook_inner = notch_r + hook_clear;
hook_outer = side_dim / 2;

// Hook wrap angles (math convention, CCW from +X)
// Right hook: wraps outer(+X) side from 5'oclock(-60°) seamlessly to inner bridge(180°)
// Left hook: wraps inner bridge(0°) seamlessly to outer(-X) side 7'oclock(240°)
hook_R = [-60, 180];
hook_L = [0, 240];

/* [Calculated] */
rack_w    = rack_outer_width - tube_dia;
bot_x     = rack_w / 2;
top_x     = (deck_w/2) - (tube_dia/2);
leg_top_z = deck_height - side_dim/2;
leg_angle_mag = atan2(top_x - bot_x, leg_top_z);
inner_gap = (rack_length - leg_t - 2*board_w) / 3;
beam_y_positions = [rack_length/2, -rack_length/2];
$fn = 40;

function vlen(v) = sqrt(v[0]*v[0]+v[1]*v[1]+v[2]*v[2]);
function vnorm(v) = v / vlen(v);

// Fan-shaped 2D sector polygon
module sector2d(a0, a1, r=50) {
    polygon(concat([[0,0]],
        [for(a=[a0:5:a1]) [r*cos(a), r*sin(a)]],
        [[r*cos(a1), r*sin(a1)]]));
}

// Eccentric partial ring: annular sector with independent inner/outer shifting
module eccentric_partial_ring(ri, ro, a0, a1, shift_in_y=0, shift_out_y=0) {
    intersection() {
        difference() { 
            translate([0, shift_out_y]) circle(r=ro); 
            translate([0, shift_in_y]) circle(r=ri); 
        }
        sector2d(a0, a1);
    }
}

// Keyed D-shape profile for the side beam (thin peg or thick pipe)
module d_profile(is_right, use_notch, clearance=0, custom_r=0, custom_y=0) {
    ha = is_right ? hook_R : hook_L;
    offset(r=clearance) {
        intersection() {
            // Select either the inner 7mm peg, the outer 12mm pipe, or a custom one
            if (custom_r > 0) {
                translate([0, custom_y]) circle(r=custom_r);
            } else if (use_notch) {
                translate([0, -1.0]) circle(r=notch_r);
            } else {
                circle(r=hook_outer);
            }
            
            // The convex hull of the OUTER C-clip profile
            // This provides the exact straight line connecting the OUTER tips of the clip!
            hull() {
                intersection() {
                    circle(r=hook_outer);
                    sector2d(ha[0], ha[1]);
                }
            }
        }
    }
}

// Tube clip (bottom snap fit to rack with eccentric strength profile + 45° chamfer)
module tube_clip(len, flush_front=false, flush_back=false) {
    cor = tube_dia/2 + 3.0;  // 9.0mm outer radius
    cir = tube_dia/2 + 0.15; // 6.15mm inner radius
    chamf = 0.5;
    rotate([90,0,0]) translate([0,0,-len/2])
        difference() {
            linear_extrude(height=len)
                eccentric_partial_ring(cir, cor, -38, 218, 0, 1.5);
            // Front face chamfer (cone at eccentric outer center)
            if (!flush_front) {
                translate([0, 1.5, -0.01])
                    difference() {
                        cylinder(r=cor+5, h=chamf+0.01);
                        cylinder(r1=cor-chamf, r2=cor, h=chamf+0.01);
                    }
            }
            // Back face chamfer
            if (!flush_back) {
                translate([0, 1.5, len-chamf])
                    difference() {
                        cylinder(r=cor+5, h=chamf+0.01);
                        cylinder(r1=cor, r2=cor-chamf, h=chamf+0.01);
                    }
            }
        }
}

// Reusable U-shape cutout with stress relief for hooks and spacers
module u_cutout_2d() {
    // Zero clearance: hole exactly matches the side beam profile
    let( cw = sq_size, cy = sq_size/2 ) {
        polygon([
            [ cw/2,  cy],
            [-cw/2,  cy],
            [-cw/2, -side_dim],
            [ cw/2, -side_dim]
        ]);
        // Stress relief cylinders at the sharp inner corners
        // Allows the hook arms to flex outward easily during snap-fit
        for (sx=[-1,1]) {
            translate([sx * cw/2, cy])
                circle(r=0.7, $fn=24);
        }
    }
}

// Circular hook profile with an open bottom to drop onto the square peg
module circular_hook_2d(is_right) {
    ang = is_right ? -leg_angle_mag : leg_angle_mag;
    difference() {
        // Original outer circular shape
        circle(d=side_dim);
        
        // Single clean cutout forming an open U-shape for the square beam
        rotate(ang) u_cutout_2d();
    }
}

// The 2D profile of the side beam with a matching circular belly plug
module side_beam_profile_2d(clearance=0) {
    union() {
        // The main square
        square([sq_size + clearance*2, sq_size + clearance*2], center=true);
        // The rounded bottom plug to fill the gap seamlessly
        intersection() {
            translate([0, -side_dim/2])
                square([sq_size + clearance*2, side_dim], center=true);
            circle(d=side_dim + clearance*2);
        }
    }
}

// Single Leg module (Front/Rear, Left/Right)
module single_leg(is_right, is_front) {
    s  = is_right ? 1 : -1;
    sy = is_front ? 1 : -1;
    bx = bot_x * s;
    tx = top_x * s;
    fy = (rack_length/2) * sy;
    leg_angle = atan2(tx - bx, leg_top_z);
    difference() {
        union() {
            // Bottom Clip: Alighed flush with the INNER leg side for easy flat-bed printing
            translate([bx, fy + sy * (clip_length/2 - leg_t/2), 0])
                tube_clip(clip_length, flush_front=(sy == -1), flush_back=(sy == 1));
            
            // Leg Shaft & Integrated Head (Single hull for perfect tangency and no gaps)
            color("Silver")
            hull() {
                // Lower end (at clip)
                translate([bx, fy, 0]) rotate([0, leg_angle, 0]) 
                    cube([leg_w, leg_t, 0.1], center=true);
                
                // Top "Head" (circular outer shape, matching earlier style)
                translate([tx, fy, leg_top_z])
                    rotate([90, 0, 0])
                        cylinder(d=side_dim, h=leg_t, center=true);
            }
            
            // Front/rear reinforcement gusset at clip-leg junction
            // Simple: create vertical gusset, then tilt to match leg angle → auto 90°
            color("green") {
                gusset_h = 13;    // Height along the leg
                gusset_depth = 12; // Extends outward in Y from leg face
                translate([bx, fy-1*sy, 0])
                    rotate([0, leg_angle, 0])
                        hull() {
                            // Base: wide in Y
                            translate([0, sy*(leg_t/2 + gusset_depth/2), 0])
                                cube([leg_w, gusset_depth + 0.1, 0.1], center=true);
                            // Top: tapers to leg face
                            translate([0, sy*(leg_t/2), gusset_h])
                                cube([leg_w, 0.1, 0.1], center=true);
                        }
            }
        }
        
        // 1. Cut the bore for the side beam peg
        translate([tx, fy, leg_top_z])
            rotate([90, 0, 0])
                linear_extrude(height=leg_t + 2, center=true)
                    rotate(is_right ? -leg_angle_mag : leg_angle_mag)
                        side_beam_profile_2d(0.15);
        
        // 3. Ensure the leg's shaft is hollowed out for the Rack Pipe at the bottom
        translate([bx, fy + sy * (clip_length/2 - leg_t/2), 0])
            rotate([90, 0, 0])
                cylinder(d=tube_dia + 0.3, h=clip_length + 0.1, center=true);
                
        // 4. Slits for weight reduction and ribbed strength (3 segments)
        // This adds solid cross-bridges between the slits to prevent buckling
        for(i=[0:2]) {
            let(
                z_start = 20,
                z_end   = leg_top_z - 18,
                bridge_t = 6,
                slit_len = (z_end - z_start - bridge_t*2) / 3,
                cz1 = z_start + i * (slit_len + bridge_t),
                cz2 = cz1 + slit_len,
                cx1 = bx + (tx - bx) * (cz1 / leg_top_z),
                cx2 = bx + (tx - bx) * (cz2 / leg_top_z)
            ) {
                hull() {
                    translate([cx1, fy, cz1]) rotate([90, 0, 0]) cylinder(d=4, h=leg_t + 2, center=true);
                    translate([cx2, fy, cz2]) rotate([90, 0, 0]) cylinder(d=4, h=leg_t + 2, center=true);
                }
            }
        }
    }
}

// Core profile of the side beam (uniform square + rounded belly)
module side_beam_core(is_right, clearance=0, is_cutter=false) {
    ang = is_right ? leg_angle_mag : -leg_angle_mag;
    // Dynamically match the exact outer boundary of the end boards (no protrusion)
    outer_board_y = rack_length/2 + leg_t/2 + board_w/2;
    peg_len = (outer_board_y + board_w/2) * 2 + (is_cutter ? 2.0 : 0);
    ang = is_right ? -leg_angle_mag : leg_angle_mag;
    
    if (is_cutter) {
        linear_extrude(height=peg_len, center=true)
            rotate(ang)
                side_beam_profile_2d(clearance);
    } else {
        difference() {
            // Physical geometry with a subtle 0.4mm edge chamfer at the ends
            hull() {
                linear_extrude(height=peg_len - 0.8, center=true)
                    rotate(ang)
                        side_beam_profile_2d(0);
                linear_extrude(height=peg_len, center=true)
                    rotate(ang)
                        side_beam_profile_2d(-0.4);
            }
            
            // Side-notches (横からのザグリ) for ALL deck boards and spacers
            let ( 
                inner_y = (rack_length/2 - leg_t/2) - inner_gap - board_w/2,
                gap_front = (rack_length/2 - leg_t/2) - inner_gap/2,
                gap_center = 0,
                gap_rear = -((rack_length/2 - leg_t/2) - inner_gap/2),
                
                // Shift offsets to match the supportless inward-shifted tab placement
                // Boards map to +7 globally. Spacers map to (-len/2 + 2) globally.
                notch_positions = [
                    // Boards: local Z = -target_global_Y
                    -( outer_board_y - 7 ), // Outer Front (Target Y is outer_y - 7)
                    -( inner_y - 7 ),       // Inner Front (Target Y is inner_y - 7)
                    -( -inner_y + 7 ),      // Inner Rear (Target Y is -inner_y + 7)
                    -( -outer_board_y + 7 ),// Outer Rear (Target Y is -outer_y + 7)
                    
                    // Spacers: local Z = -target_global_Y
                    -( gap_front - (inner_gap/2 - 2) ),  // Front Spacer
                    -( gap_center - (inner_gap/2 - 2) ), // Center Spacer
                    -( gap_rear + (inner_gap/2 - 2) )    // Rear Spacer (tab flipped for perfect symmetry)
                ]
            ) {
                for (bz = notch_positions) {
                    // Cut out a depth wedge (deep at the top catch, shallow at bottom)
                    // The catch ledge is at local Y = -1.4, depth goes to 0 at Y = -5.6
                    rotate([0, 0, ang]) {
                        for (sx = [-1, 1]) {
                            translate([0, 0, bz]) 
                                scale([sx, 1, 1])
                                    linear_extrude(height=5.2, center=true)
                                        polygon([
                                            [2.25, -1.4], // 0.1mm clearance above the -1.5mm ledge
                                            [4.0,  -1.4],
                                            [4.0,  -5.6], // Fully clear the bottom
                                            [2.75, -5.6]
                                        ]);
                        }
                    }
                }
            }
        }
    }
}

// Side Beam (Connecting Front and Rear legs, slides through leg holes)
module side_beam(is_right) {
    color("LightSteelBlue")
        translate([is_right ? top_x : -top_x, 0, leg_top_z])
            rotate([90,0,0])
                side_beam_core(is_right, 0, false);
}

// A spacer to cover the exposed side beam in the gaps
module side_beam_spacer(len, flip_tab=false) {
    union() {
        difference() {
            cylinder(d=side_dim, h=len, center=true);
            
            // 45 deg chamfer logic for the spacer ends
            for (zz=[-len/2, len/2]) {
                if (zz < 0) {
                    translate([0,0,zz]) difference() { cylinder(r=hook_outer+5, h=0.51, center=true); cylinder(r1=hook_outer-0.5, r2=hook_outer, h=0.51, center=true); }
                } else {
                    translate([0,0,zz]) difference() { cylinder(r=hook_outer+5, h=0.51, center=true); cylinder(r1=hook_outer, r2=hook_outer-0.5, h=0.51, center=true); }
                }
            }
            
            // U-Cut for snap-fitting the spacer onto the side beam from above
            linear_extrude(height=len+1, center=true)
                u_cutout_2d();
        }
        
        // Snap-fit tabs
        for (lx=[-1, 1]) {
            // Shift tab to perfectly touch one side for supportless upright printing
            translate([0, 0, flip_tab ? -len/2 + 2 : len/2 - 2])
                // Wedge-shaped tab exactly matching the depth-wedge of the notch
                scale([lx, 1, 1])
                    linear_extrude(height=4, center=true)
                        polygon([
                            [3.5, -1.4],  // Anchor deeply into wall (top)
                            [3.5, -5.6],  // Anchor deeply into wall (bottom)
                            [2.75, -5.6], // Tapers exactly to the zero-clearance wall boundary
                            [2.25, -1.4]  // Exact inward protrusion locking tightly into the pocket
                        ]);
        }
    }
}

// A single simple deck board
module deck_board() {
    z = leg_top_z;
    difference() {
        union() {
            // Right hook (with 45° chamfer on both sides)
            translate([top_x,0,z]) rotate([90,0,0])
                difference() {
                    translate([0,0,-board_w/2])
                        linear_extrude(height=board_w) circular_hook_2d(true);
                    translate([0, 0, -board_w/2 - 0.01])
                        difference() { cylinder(r=hook_outer+5, h=0.51); cylinder(r1=hook_outer-0.5, r2=hook_outer, h=0.51); }
                    translate([0, 0, board_w/2 - 0.5])
                        difference() { cylinder(r=hook_outer+5, h=0.51); cylinder(r1=hook_outer, r2=hook_outer-0.5, h=0.51); }
                }
            // Left hook (with 45° chamfer on both sides)
            translate([-top_x,0,z]) rotate([90,0,0])
                difference() {
                    translate([0,0,-board_w/2])
                        linear_extrude(height=board_w) circular_hook_2d(false);
                    translate([0, 0, -board_w/2 - 0.01])
                        difference() { cylinder(r=hook_outer+5, h=0.51); cylinder(r1=hook_outer-0.5, r2=hook_outer, h=0.51); }
                    translate([0, 0, board_w/2 - 0.5])
                        difference() { cylinder(r=hook_outer+5, h=0.51); cylinder(r1=hook_outer, r2=hook_outer-0.5, h=0.51); }
                }
            // Bridge (with 45° chamfer applied to both sides)
            difference() {
                hull() {
                    translate([ top_x,0,z+hook_outer-beam_thick/2]) cube([0.1,board_w,beam_thick], center=true);
                    translate([-top_x,0,z+hook_outer-beam_thick/2]) cube([0.1,board_w,beam_thick], center=true);
                }
                for(yy=[board_w/2, -board_w/2])
                    for(zz=[z+hook_outer, z+hook_outer-beam_thick])
                        translate([0, yy, zz])
                            rotate([45,0,0])
                                cube([deck_w+10, 0.71, 0.71], center=true);
            }
        }
        
        // Ensure the U-cutouts and stress reliefs penetrate through the overlying bridge!
        for (xs=[-1, 1]) {
            is_right = (xs == 1);
            ang = is_right ? -leg_angle_mag : leg_angle_mag;
            translate([xs*top_x, 0, z]) 
                rotate([90,0,0])
                    linear_extrude(height=board_w + 2, center=true)
                        rotate(ang)
                            u_cutout_2d();
        }
    }
    
    // Snap-fit tabs from the sides (横からの切り欠きに引っ掛ける爪)
    for (xs=[-1, 1]) {
        is_right = (xs == 1);
        ang = is_right ? -leg_angle_mag : leg_angle_mag;
        translate([xs*top_x, 0, z]) 
            rotate([90,0,0]) 
                rotate(ang) {
                for (lx=[-1, 1]) {
                    // The beam notch ledge starts at Y = -1.4.
                    // Shift tab to perfectly touch one side (+7mm) for supportless upright printing
                    // This shifts the tab INWARD (towards legs) for the outer deck boards.
                    translate([0, 0, 7])
                        // Wedge-shaped tab exactly matching the depth-wedge of the notch
                        scale([lx, 1, 1])
                            linear_extrude(height=4, center=true)
                                polygon([
                                    [3.5, -1.4],  // Anchor deeply into wall (top)
                                    [3.5, -5.6],  // Anchor deeply into wall (bottom)
                                    [2.75, -5.6], // Tapers exactly to the zero-clearance wall boundary
                                    [2.25, -1.4]  // Exact inward protrusion locking tightly into the pocket
                                ]);
                }
            }
    }
}

// ============================================================
// Assembly
// ============================================================
module assembly(explode=0) {
    // 4 Legs (positioned at Z=0 base)
    single_leg(false, true);  // Left Front
    single_leg(false, false); // Left Rear
    single_leg(true, true);   // Right Front
    single_leg(true, false);  // Right Rear
    
    // 2 Side Beams (fully seated into the legs)
    translate([0, 0, 0]) {
        side_beam(false); // Left
        side_beam(true);  // Right
    }
    
    // 4 Deck Boards 
    let(
        outer_y = rack_length/2 + leg_t/2 + board_w/2,
        inner_y = (rack_length/2 - leg_t/2) - inner_gap - board_w/2
    ) {
        translate([0, 0, explode]) color("Coral") {
            translate([0,  outer_y, 0]) deck_board(); // Outer Front
            translate([0,  inner_y, 0]) deck_board(); // Inner Front
            translate([0, -inner_y, 0]) rotate([0,0,180]) deck_board(); // Inner Rear (Rotated for symmetry)
            translate([0, -outer_y, 0]) rotate([0,0,180]) deck_board(); // Outer Rear (Rotated for symmetry)
        }
        
        // 6 Spacers covering the side beams in the 3 inner gaps
        let(
            gap_front = (rack_length/2 - leg_t/2) - inner_gap/2,
            gap_center = 0,
            gap_rear = -gap_front
        ) {
            translate([0, 0, explode]) color("Goldenrod") {
                for (is_r = [false, true]) {
                    ang = is_r ? -leg_angle_mag : leg_angle_mag;
                    for (gy = [gap_front, gap_center, gap_rear]) {
                        translate([is_r ? top_x : -top_x, gy, leg_top_z]) 
                            rotate([90,0,0])
                                rotate([0, 0, ang]) // Simulates the user 'rolling' the universal spacer to fit the slanted beam
                                    side_beam_spacer(inner_gap, flip_tab=(gy == gap_rear));
                    }
                }
            }
        }
    }
}

if (part==0) render(){assembly();}
else if (part==1) single_leg(false, true);
else if (part==2) side_beam(false);
else if (part==3) deck_board();
else if (part==5) side_beam_spacer(inner_gap, false);
else if (part==6) render(){assembly(explode=30);}
else if (part==4) {
    // Print Layout: optimized for no supports
    // Legs lying on their flush inner Y-face
    for(i=[0,1]) for(j=[0,1])
        translate([i*30 - 15, j*130 - 65, 0]) {
            if (j==1) {
                // Front legs: inner flat face rotated to Z=0
                translate([100, 0, rack_length/2 + leg_t/2]) 
                    rotate([90, 0, 0]) single_leg(i==1, true);
            } else {
                // Rear legs: inner flat face rotated to Z=0
                translate([0, 0, rack_length/2 + leg_t/2]) 
                    rotate([270, 0, 0]) single_leg(i==1, false);
            }
        }
    
    // Beams lying flat
    translate([60, -30, side_dim/2]) rotate([0,0,90]) side_beam(false);
    translate([60, 30, side_dim/2]) rotate([0,0,90]) side_beam(true);
    
    // 4 Deck boards perfectly laid out for printing
    for (i=[0:3]) {
        translate([0, 150 + i * 25, 0]) deck_board();
    }
    
    // 6 Spacers printed standing upright on their flat cylindrical face
    for (is_r = [0:1]) {
        for (j = [0:2]) {
            translate([80 + is_r * 25, j * 30 - 30, inner_gap/2])
                side_beam_spacer(inner_gap, is_r==1); 
        }
    }
}
