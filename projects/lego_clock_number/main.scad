// LEGO Number Plate (Flush Pixel Style)
// Created for a LEGO Clock project
// Dimensions: 2x3 studs (1x3 for number 1)
// Adjusted for Multi-Material Printing

// --- Customization ---
render_single = -1; // [-1:9]
render_part = 0;   // 0: Both, 1: Base, 2: Numbers

$fn = 64;

// --- Parameters ---
pitch = 8.0;
tolerance = 0.2;
plate_h = 3.2;
wall_th = 1.22;
tube_od = 6.42;
tube_id = 5.22;
pin_d = 3.2;         // Diameter of small pipes for 1xN plates

// Standard size (for layout calculations)
std_width = 2 * pitch - tolerance;
std_length = 3 * pitch - tolerance;

// 3x5 dot patterns
pixel_patterns = [
    [1,1,1, 1,0,1, 1,0,1, 1,0,1, 1,1,1], // 0
    [0,1,0, 0,1,0, 0,1,0, 0,1,0, 0,1,0], // 1
    [1,1,1, 0,0,1, 1,1,1, 1,0,0, 1,1,1], // 2
    [1,1,1, 0,0,1, 1,1,1, 0,0,1, 1,1,1], // 3
    [1,0,1, 1,0,1, 1,1,1, 0,0,1, 0,0,1], // 4
    [1,1,1, 1,0,0, 1,1,1, 0,0,1, 1,1,1], // 5
    [1,1,1, 1,0,0, 1,1,1, 1,0,1, 1,1,1], // 6
    [1,1,1, 0,0,1, 0,0,1, 0,0,1, 0,0,1], // 7
    [1,1,1, 1,0,1, 1,1,1, 1,0,1, 1,1,1], // 8
    [1,1,1, 1,0,1, 1,1,1, 0,0,1, 1,1,1]  // 9
];

module pixel_dots(n, h) {
    p = pixel_patterns[n];
    dot_size = 4.0; 
    for (row = [0:4]) {
        for (col = [0:2]) {
            if (p[row*3 + col] == 1) {
                translate([(col - 1) * dot_size, (2 - row) * dot_size, 0])
                    cube([dot_size, dot_size, h], center=true);
            }
        }
    }
}

module lego_number_tile(num, base_color="RoyalBlue", text_color="White") {
    studs_x = (num == 1) ? 1 : 2;
    w = studs_x * pitch - tolerance;
    l = 3 * pitch - tolerance;
    
    cx = w/2;
    cy = l/2;
    inlay_depth = 1.0; 

    // 1. Base Plate
    if (render_part == 0 || render_part == 1) {
        render() {
            color(base_color)
            difference() {
                // Main body
                group() {
                    difference() {
                        cube([w, l, plate_h]);
                        translate([wall_th, wall_th, -0.1])
                            cube([w - 2*wall_th, l - 2*wall_th, plate_h - 1.0 + 0.1]);
                    }
                    
                    if (studs_x == 2) {
                        // 2x3用の大きなチューブ
                        for (y = [pitch, 2 * pitch]) {
                            translate([pitch - tolerance/2, y - tolerance/2, 0])
                                difference() {
                                    cylinder(d=tube_od, h=plate_h - 1.0);
                                    cylinder(d=tube_id, h=plate_h - 1.0);
                                }
                        }
                    } else if (studs_x == 1) {
                        // 1x3用の小さなパイプ (本物のレゴにある小さな円柱)
                        for (y = [pitch, 2 * pitch]) {
                            translate([pitch/2 - tolerance/2, y - tolerance/2, 0])
                                cylinder(d=pin_d, h=plate_h - 1.0);
                        }
                    }
                }
                // Cut out pixels
                translate([cx, cy, plate_h - inlay_depth/2 + 0.01])
                    pixel_dots(num, inlay_depth + 0.02);
            }
        }
    }
    
    // 2. Number Pixels
    if (render_part == 0 || render_part == 2) {
        render() {
            color(text_color)
            translate([cx, cy, plate_h - inlay_depth/2])
                pixel_dots(num, inlay_depth);
        }
    }
}

// --- Rendering Logic ---
if (render_single == -1) {
    for (i = [0:9]) {
        col = i % 5;
        row = floor(i / 5);
        studs_x = (i == 1) ? 1 : 2;
        x_shift = (i == 1) ? pitch / 2 : 0;

        translate([col * (std_width + 5) + x_shift, -row * (std_length + 5), 0])
            lego_number_tile(
                num = i, 
                base_color = (i % 2 == 0 ? "#1E88E5" : "#D81B60"), 
                text_color = "White"
            );
    }
} else {
    lego_number_tile(render_single, "#1E88E5", "White");
}
