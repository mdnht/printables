// TUBUS GRAND EXPEDITION Front Rack Extension
// Hook-and-notch flush joint design with deep 5 o'clock outer wrap.
// Fixed the bridge integration so the top and bottom merge seamlessly
// with the hook ring.

/* [Which part to render] */
part = 0; // [0:assembly, 1:leg_left, 2:leg_right, 3:deck_beam]

/* [Dimensions] */
rack_outer_width = 102;
tube_dia         = 12;
rack_length      = 100;
deck_w           = 150;
deck_height      = 120;
beam_thick       = 3.5;
beam_w           = 25;
leg_tube_dia     = 12;

/* [Hook Joint] */
hook_wall  = 2.5;
hook_clear = 0.2;
notch_r    = leg_tube_dia/2 - hook_wall;
hook_inner = notch_r + hook_clear;
hook_outer = leg_tube_dia / 2;

// Hook wrap angles (math convention, CCW from +X)
// Right hook: wraps outer(+X) side from 5'oclock(-60°) seamlessly to inner bridge(180°)
// Left hook: wraps inner bridge(0°) seamlessly to outer(-X) side 7'oclock(240°)
hook_R = [-60, 180];
hook_L = [0, 240];

/* [Calculated] */
rack_w    = rack_outer_width - tube_dia;
bot_x     = rack_w / 2;
top_x     = (deck_w/2) - (tube_dia/2);
leg_top_z = deck_height - leg_tube_dia/2;
beam_y_positions = [27, -27];
$fn = 60;

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

// Tube clip (bottom snap fit to rack with eccentric strength profile)
module tube_clip(len) {
    cor = tube_dia/2 + 3.0;  // 9.0mm outer radius
    cir = tube_dia/2 + 0.15; // 6.15mm inner radius
    rotate([90,0,0]) translate([0,0,-len/2])
        linear_extrude(height=len)
            eccentric_partial_ring(cir, cor, -38, 218, 0, 1.5);
}

// Leg module
module leg(is_right) {
    s  = is_right ? 1 : -1;
    bx = bot_x*s;  tx = top_x*s;
    fy = rack_length/2;  ry = -rack_length/2;
    // Set z_bot to 0 so the leg tube axis perfectly intersects the C-clamp center
    z_bot = 0;  
    R = 10;  st = 15;
    V = [tx-bx,0,leg_top_z-z_bot];  u = vnorm(V);
    uf=[0,-1,0]; ur=[0,1,0];
    Cf = [tx,fy,leg_top_z]-u*R+uf*R;
    Cr = [tx,ry,leg_top_z]-u*R+ur*R;
    Puf=[tx,fy,leg_top_z]-u*R; Pur=[tx,ry,leg_top_z]-u*R;
    Phf=[tx,fy,leg_top_z]+uf*R; Phr=[tx,ry,leg_top_z]+ur*R;
    ha = is_right ? hook_R : hook_L;

    difference() {
        union() {
            translate([bx,fy,0]) tube_clip(20);
            translate([bx,ry,0]) tube_clip(20);
            color("Silver") {
                hull() { translate([bx,fy,z_bot]) sphere(d=leg_tube_dia);
                         translate(Puf) sphere(d=leg_tube_dia); }
                for(i=[0:st-1]) hull() {
                    translate(Cf+u*R*cos(i*90/st)-uf*R*sin(i*90/st)) sphere(d=leg_tube_dia);
                    translate(Cf+u*R*cos((i+1)*90/st)-uf*R*sin((i+1)*90/st)) sphere(d=leg_tube_dia);
                }
                hull() { translate(Phf) sphere(d=leg_tube_dia);
                         translate(Phr) sphere(d=leg_tube_dia); }
                for(i=[0:st-1]) hull() {
                    translate(Cr+u*R*cos(i*90/st)-ur*R*sin(i*90/st)) sphere(d=leg_tube_dia);
                    translate(Cr+u*R*cos((i+1)*90/st)-ur*R*sin((i+1)*90/st)) sphere(d=leg_tube_dia);
                }
                hull() { translate(Pur) sphere(d=leg_tube_dia);
                         translate([bx,ry,z_bot]) sphere(d=leg_tube_dia); }
            }
        }
        // Partial notch only where hook wraps, width strictly beam_w
        for(y=beam_y_positions)
            translate([tx,y,leg_top_z]) rotate([90,0,0]) translate([0,0,-beam_w/2 - 0.2])
                linear_extrude(height=beam_w + 0.4)
                    eccentric_partial_ring(notch_r, leg_tube_dia/2+0.1, ha[0]-3, ha[1]+3, -1.0, 0);

        // Clear out any structural tubes protruding into the C-clip interior
        for(y=[fy, ry]) {
            translate([bx, y, 0])
                rotate([90,0,0])
                    cylinder(r=tube_dia/2 + 0.15, h=30, center=true);
        }
    }
}

// Deck beam
module deck_beam() {
    z = leg_top_z;
    difference() {
        union() {
            // Right hook (width strictly beam_w)
            translate([top_x,0,z]) rotate([90,0,0]) translate([0,0,-beam_w/2])
                linear_extrude(height=beam_w) eccentric_partial_ring(hook_inner, hook_outer, hook_R[0], hook_R[1], -1.0, 0);
            // Left hook (width strictly beam_w)
            translate([-top_x,0,z]) rotate([90,0,0]) translate([0,0,-beam_w/2])
                linear_extrude(height=beam_w) eccentric_partial_ring(hook_inner, hook_outer, hook_L[0], hook_L[1], -1.0, 0);
            // Bridge
            hull() {
                translate([ top_x,0,z+hook_outer-beam_thick/2]) cube([0.1,beam_w,beam_thick], center=true);
                translate([-top_x,0,z+hook_outer-beam_thick/2]) cube([0.1,beam_w,beam_thick], center=true);
            }
        }

        // Hook bore ensuring perfectly matched interior.
        // We elegantly shift the inner tube bore down perfectly mimicking the eccentric neck.
        for (xs=[-1,1]) {
            translate([xs*top_x, 0, z])
                rotate([90,0,0])
                    translate([0, -1.0, 0]) cylinder(r=hook_inner, h=beam_w+2, center=true);
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
    leg(false); leg(true);
    
    // Position beams directly in their flush pockets
    color("Coral") translate([0, beam_y_positions[0], 0]) deck_beam();
    color("Gold")  translate([0, beam_y_positions[1], 0]) deck_beam();
}

if (part==0) assembly();
else if (part==1) translate([rack_w/2,0,0]) leg(false);
else if (part==2) translate([-rack_w/2,0,0]) leg(true);
else if (part==3) rotate([180,0,0]) translate([0,0,-deck_height]) deck_beam();
