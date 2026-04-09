

// TUBUS GRAND EXPEDITION Front Rack Extension
// Hook-and-notch flush joint design with deep 5 o'clock outer wrap.
// Fixed the bridge integration so the top and bottom merge seamlessly
// with the hook ring.

/* [Which part to render] */
part = 4; // [0:assembly, 1:leg_left, 2:leg_right, 3:deck_beam, 4:print_layout]

/* [Dimensions] */
rack_outer_width = 102;
tube_dia         = 12;
rack_length      = 110;
clip_length      = 25;
clip_y_offset    = 5.5;
deck_w           = 150;
deck_height      = 120;
beam_thick       = 3.5;
beam_w           = 45;

/* [Component Design] */
leg_w     = 12;    // Width of the flat leg face (Uniform 12mm, matching top cylinder)
leg_t     = 6;     // Thickness of the leg (Increased to 6)
side_dim  = 12;    // Side beam diameter/width (matches hook)
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
                
                // Top "Head" (12mm cylinder flush with side beam)
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
        
        // 1. Cut the D-shaped bore for the side beam peg
        translate([tx, fy, leg_top_z])
            rotate([90, 0, 0])
                linear_extrude(height=leg_t + 2, center=true)
                    d_profile(is_right, true, 0.15);
        
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

// Core tapered profile of the side beam (used for subtraction and generation)
// Re-introduced to eliminate stress concentration and provide a tapered D-profile socket.
module side_beam_core(is_right, clearance=0, is_cutter=false) {
    center_len = rack_length - beam_w; // 59
    peg_len = rack_length + beam_w + (is_cutter ? 2.0 : 0); // 149 (plus 2mm for clean cuts)
    taper_in  = 5.0; // Taper length inside the clip (10mm -> 7mm)
    
    // Custom 10mm start-profile (Radius 5.0, linearly shifted center to match 12mm->7mm taper cone)
    // 12mm pipe: r=6.0, y=0.
    // 7mm peg:   r=3.5, y=-1.0.
    // We want physical 10mm diameter (r=5.0). Drop of 1.0 out of 2.5 (40% distance).
    // So y = 0 + 0.4 * (-1.0) = -0.4.
    // This custom profile perfectly blends the cylinders WHILE maintaining the exact same flat bottom chord!
    r_10 = 5.0;
    y_10 = -0.4;
    
    union() {
        // Straight middle section (12mm) - acts as a flat structural stopper against the deck board face
        linear_extrude(height=center_len, center=true)
            d_profile(is_right, false, clearance);
            
        // Top Taper (starts sharply at 10mm to create a load-bearing shoulder, maintaining perfectly flush flat bottom)
        translate([0, 0, center_len/2])
            hull() {
                linear_extrude(height=0.01) d_profile(is_right, false, clearance, r_10, y_10);
                translate([0, 0, taper_in])  linear_extrude(height=0.01) d_profile(is_right, true, clearance);
            }
            
        // Bottom Taper (starts sharply at 10mm, perfectly maintaining flat bottom, tapers to 7mm inside)
        translate([0, 0, -center_len/2])
            hull() {
                linear_extrude(height=0.01) d_profile(is_right, false, clearance, r_10, y_10);
                translate([0, 0, -taper_in])  linear_extrude(height=0.01) d_profile(is_right, true, clearance);
            }
            
        // Pegs (7mm)
        if (is_cutter) {
            linear_extrude(height=peg_len, center=true)
                d_profile(is_right, true, clearance);
        } else {
            // Physical peg generation: slightly shortened for the chamfer ends
            linear_extrude(height=peg_len - 0.8, center=true)
                d_profile(is_right, true, clearance);
                
            // Chamfered peg ends (10 slices per side for a subtle 0.4mm edge break)
            for(i=[0:0.04:0.36]) {
                translate([0, 0, (peg_len/2 - 0.4) + i])
                    linear_extrude(height=0.042)
                        d_profile(is_right, true, clearance-i);
                        
                translate([0, 0, -(peg_len/2) + i])
                    linear_extrude(height=0.042)
                        d_profile(is_right, true, clearance-(0.4 - i));
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

// Deck beam (Restored original design)
module deck_beam() {
    z = leg_top_z;
    difference() {
        union() {
            // Right hook (with 45° chamfer)
            translate([top_x,0,z]) rotate([90,0,0])
                difference() {
                    translate([0,0,-beam_w/2])
                        linear_extrude(height=beam_w) eccentric_partial_ring(hook_inner, hook_outer, hook_R[0], hook_R[1], -1.0, 0);
                    translate([0, 0, -beam_w/2 - 0.01])
                        difference() { cylinder(r=hook_outer+5, h=0.51); cylinder(r1=hook_outer-0.5, r2=hook_outer, h=0.51); }
                    translate([0, 0, beam_w/2 - 0.5])
                        difference() { cylinder(r=hook_outer+5, h=0.51); cylinder(r1=hook_outer, r2=hook_outer-0.5, h=0.51); }
                }
            // Left hook (with 45° chamfer)
            translate([-top_x,0,z]) rotate([90,0,0])
                difference() {
                    translate([0,0,-beam_w/2])
                        linear_extrude(height=beam_w) eccentric_partial_ring(hook_inner, hook_outer, hook_L[0], hook_L[1], -1.0, 0);
                    translate([0, 0, -beam_w/2 - 0.01])
                        difference() { cylinder(r=hook_outer+5, h=0.51); cylinder(r1=hook_outer-0.5, r2=hook_outer, h=0.51); }
                    translate([0, 0, beam_w/2 - 0.5])
                        difference() { cylinder(r=hook_outer+5, h=0.51); cylinder(r1=hook_outer, r2=hook_outer-0.5, h=0.51); }
                }
            // Bridge (with 45° chamfer applied only to the bridge plate)
            difference() {
                hull() {
                    translate([ top_x,0,z+hook_outer-beam_thick/2]) cube([0.1,beam_w,beam_thick], center=true);
                    translate([-top_x,0,z+hook_outer-beam_thick/2]) cube([0.1,beam_w,beam_thick], center=true);
                }
                for(yy=[beam_w/2, -beam_w/2])
                    for(zz=[z+hook_outer, z+hook_outer-beam_thick])
                        translate([0, yy, zz])
                            rotate([45,0,0])
                                cube([deck_w+10, 0.71, 0.71], center=true);
            }
        }

        // Tapered Hook bore (precisely matching the side beam profile!)
        // 0.2mm positive clearance makes the hole perfectly sized for easy fit.
        // We subtract the core from the inner face (-Y) only. The rear use-case
        // will just rotate the identical physical part 180 degrees around Z!
        for (xs=[-1,1]) {
            is_right = (xs == 1);
            translate([xs*top_x, -rack_length/2, z])
                rotate([90,0,0])
                    side_beam_core(is_right, 0.2, true);
        }

        // Straddle cutouts: fork the deck hooks to clear the legs
        for (xs=[-1,1]) {
            translate([xs*top_x, 0, z])
                // 13mm wide (X), 6.6mm gap (Y), 40mm tall (Z)
                cube([13, leg_t + 0.6, 40], center=true);
        }

        // Two strap slots, positioned further towards the outer edges
        // Added top and bottom chamfers (tapers) for easy strap insertion!
        for (sx=[-1, 1]) {
            z_cent = z + hook_outer - beam_thick/2;
            translate([sx * 35, 0, z_cent]) {
                // Bottom Taper
                hull() {
                    translate([ 15, 0, -beam_thick/2 - 0.1]) cylinder(r=2.8, h=0.1);
                    translate([-15, 0, -beam_thick/2 - 0.1]) cylinder(r=2.8, h=0.1);
                    translate([ 15, 0, -beam_thick/2 + 0.8]) cylinder(r=2, h=0.1);
                    translate([-15, 0, -beam_thick/2 + 0.8]) cylinder(r=2, h=0.1);
                }
                // Straight Body
                hull() {
                    translate([ 15, 0, -beam_thick/2 + 0.7]) cylinder(r=2, h=2.1);
                    translate([-15, 0, -beam_thick/2 + 0.7]) cylinder(r=2, h=2.1);
                }
                // Top Taper
                hull() {
                    translate([ 15, 0, beam_thick/2 - 0.8]) cylinder(r=2, h=0.1);
                    translate([-15, 0, beam_thick/2 - 0.8]) cylinder(r=2, h=0.1);
                    translate([ 15, 0, beam_thick/2]) cylinder(r=2.8, h=0.1);
                    translate([-15, 0, beam_thick/2]) cylinder(r=2.8, h=0.1);
                }
            }
        }
    }
}

// ============================================================
// Assembly
// ============================================================
module assembly() {
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
    
    // 2 Deck Beams (fully snapped onto the side beams)
    translate([0, 0, 0]) {
        color("Coral") translate([0, beam_y_positions[0], 0]) deck_beam();
        color("Gold")  translate([0, beam_y_positions[1], 0]) rotate([0,0,180]) deck_beam();
    }
}

if (part==0) render(){assembly();}
else if (part==1) single_leg(false, true);
else if (part==2) side_beam(false);
else if (part==3) deck_beam();
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
    
    // Deck beams
    translate([0, 150, 0]) deck_beam();
    translate([0, -150, 0]) deck_beam();
}
