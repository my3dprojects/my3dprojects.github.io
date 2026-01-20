// FIX APPLIED: Increased Rod Diameter to 12mm and Socket Depth to 15mm
// for maximum rigidity and zero wobble.

$fn = 60; 

// --- 1. CONFIGURATION ---

// 0 = ASSEMBLY VIEW 
// 1 = BOX (With Heavy Duty Sockets)
// 2 = GEARS 
// 3 = HANDLE 
// 4 = HEAVY DUTY PILLARS (Print 4 of these)
PART_TO_PRINT = 4; 

// --- TRACTION SETTINGS ---
// 0 = Smooth (Original)
// 1 = O-Ring Groove (Standard #224 O-Ring)
// 2 = Printed "Nubs" Texture 
TRACTION_MODE = 0; 

INCH = 25.4;
wall_thick = 3;
floor_thick = 4;
base_height = 2 * INCH; 

// --- 2. FIXED GEOMETRY ---
orig_gap = 0.5; 
orig_len = (9.75 * INCH) - (wall_thick * 2);
orig_diam = (orig_len - (orig_gap * 3)) / 2;
orig_r = orig_diam / 2;

FIXED_PIN_Y_BACK  =  (orig_r + orig_gap/2);
FIXED_PIN_Y_FRONT = -(orig_r + orig_gap/2);

orig_protrusion = 6;
box_max_y = FIXED_PIN_Y_BACK + orig_r + 3.0 + wall_thick;
box_min_y = (FIXED_PIN_Y_FRONT - orig_r) + orig_protrusion;
final_box_length = box_max_y - box_min_y;
final_box_center_y = (box_max_y + box_min_y) / 2;
final_box_width = (orig_r * 2) + (3.0 * 2) + (wall_thick * 2);

// --- 3. GEAR MATH ---
shrink_amount = 1.5; 
r_main_new = orig_r - shrink_amount;
r_idler = 12; 

dist_centers = r_main_new + r_idler + 0.5; 
y_offset = FIXED_PIN_Y_BACK; 

pitch_val = 280; 

teeth_main  = round((r_main_new * 360) / pitch_val);
teeth_idler = round((r_idler * 360) / pitch_val);

r_main_final  = (teeth_main * pitch_val) / 360;
r_idler_final = (teeth_idler * pitch_val) / 360;

dist_final = r_main_final + r_idler_final + 0.5; 
final_idler_x = sqrt(pow(dist_final, 2) - pow(y_offset, 2));


// --- 4. Z HEIGHTS ---
gear_h = 8;            
spacer_h = 0.0;        
total_stack_h = spacer_h + gear_h; 
drop_amt = 1.2; 
pin_top_z = floor_thick + total_stack_h; 

// --- 5. STACKING SYSTEM PARAMS (HEAVY DUTY) ---
// *** UPDATED FOR STRENGTH ***
stack_pin_r = 6.0;    // 12mm Diameter (Was 8mm) - Much stronger
stack_col_r = 8.5;    // Thicker outer housing to accept the 12mm rod
stack_socket_depth = 15.0; // Deeper sockets (Was 10mm) to stop wobble
fusion_overlap = 2.5; // Slightly more overlap for the heavier column

// *** VERTICAL CLEARANCE FOR BOTTLES ***
stack_clearance = 120; // 120mm space between racks

// Position: External to the wall
stack_x = (final_box_width/2) + stack_col_r - fusion_overlap; 
stack_y = (final_box_length/2) - (final_box_width/2); 


// --- 6. RENDER LOGIC ---

if (PART_TO_PRINT == 0) {
    // ASSEMBLY VIEW: STACKED
    
    // Bottom Unit
    render_full_unit(); 
    
    // Top Unit (Lifted by base_height + clearance)
    translate([0, 0, base_height + stack_clearance]) 
        render_full_unit();
        
    // Show Tall Pillars connecting them
    color("DimGray")
    for (mx = [0, 1]) for (my = [0, 1]) {
        sx = mx == 0 ? -stack_x : stack_x;
        sy = my == 0 ? -stack_y : stack_y;
        
        translate([sx, sy + final_box_center_y, base_height - stack_socket_depth]) 
            render_stacking_pillar();
    }
} 
else if (PART_TO_PRINT == 1) {
    render_box();
}
else if (PART_TO_PRINT == 2) {
    translate([-r_main_final - 2, 0, 0]) gear_unit(teeth_main, r_main_final, gear_h, "Silver");
    translate([r_main_final + 2, 0, 0])  gear_unit(teeth_main, r_main_final, gear_h, "Silver");
    translate([0, r_main_final + r_idler_final + 5, 0]) 
        gear_unit(teeth_idler, r_idler_final, gear_h - drop_amt, "Gold", override_mode=1);
} 
else if (PART_TO_PRINT == 3) {
    render_handle(printing=true);
}
else if (PART_TO_PRINT == 4) {
    // PRINT: TALL STACKING PILLARS (Array of 4)
    // Laying flat for printing strength
    for(i=[0:3]) {
        translate([0, i * 18, stack_pin_r]) 
        rotate([90, 0, 0])
        render_stacking_pillar();
    }
}


// --- MODULES ---

module render_full_unit() {
    render_box();
    translate([0, FIXED_PIN_Y_FRONT, floor_thick]) gear_unit(teeth_main, r_main_final, gear_h, "Silver", show_oring=true);
    translate([0, FIXED_PIN_Y_BACK, floor_thick])  gear_unit(teeth_main, r_main_final, gear_h, "Silver", show_oring=true);
    translate([final_idler_x, 0, floor_thick]) gear_unit(teeth_idler, r_idler_final, gear_h - drop_amt, "Gold", override_mode=1);
    translate([0, 0, pin_top_z]) render_handle(printing=false);
}

module render_stacking_pillar() {
    // Total height = Clearance + (2 * Socket Depth)
    h_total = stack_clearance + (stack_socket_depth * 2);
    r = stack_pin_r - 0.2; // Clearance tolerance for printing
    
    // Main Shaft
    cylinder(r=r, h=h_total);
}

module render_handle(printing) {
    handle_h = base_height - pin_top_z;
    rot_vec = printing ? [180, 0, 0] : [0, 0, 0];
    pos_vec = printing ? [0, 0, handle_h] : [0, 0, 0];
    
    shave_offset = 2.0; 
    cut_len = (FIXED_PIN_Y_BACK - FIXED_PIN_Y_FRONT) + (shave_offset * 2);
    cut_center_y = (FIXED_PIN_Y_BACK + FIXED_PIN_Y_FRONT) / 2;

    cut_depth = 3.0;
    center_dist = FIXED_PIN_Y_BACK - FIXED_PIN_Y_FRONT;
    safety_margin = 5.0; 
    relief_cut_len = center_dist - (safety_margin * 2);

    translate(pos_vec)
    rotate(rot_vec)
    color("Crimson")
    union() {
        difference() {
            intersection() {
                hull() {
                    translate([0, FIXED_PIN_Y_FRONT, 0]) cylinder(r=6, h=handle_h); 
                    translate([0, FIXED_PIN_Y_BACK, 0]) cylinder(r=6, h=handle_h);
                }
                translate([0, cut_center_y, handle_h/2])
                    cube([20, cut_len, handle_h + 10], center=true);
            }
            translate([0, cut_center_y, cut_depth/2]) 
                cube([20, relief_cut_len, cut_depth], center=true);
        }
        translate([0, FIXED_PIN_Y_FRONT, -5]) cylinder(r=2.4, h=5.1); 
        translate([0, FIXED_PIN_Y_BACK, -5]) cylinder(r=2.4, h=5.1);
    }
}

module render_box() {
    translate([0, final_box_center_y, 0]) 
    base_enclosure(final_box_width, final_box_length, base_height);
}

module base_enclosure(w, l, h) {
    cutout_r = orig_r; 
    tight_gap = 1.0; 
    extra_width = 12.0; 
    outer_r = w / 2;
    inner_r = (w - wall_thick*2) / 2;
    
    pin_y_front = FIXED_PIN_Y_FRONT - final_box_center_y;
    pin_y_back  = FIXED_PIN_Y_BACK  - final_box_center_y;

    color("Teal") {
        difference() {
            union() {
                // Outer Hull
                difference() {
                    rounded_rect(w, l, h, outer_r);
                    translate([0, 0, floor_thick]) 
                        rounded_rect(w - wall_thick*2, l - wall_thick*2, h + 10, inner_r);
                    
                    // Front Cutout
                    cut_len = 100;
                    cut_height = gear_h + 20; 
                    translate([0, pin_y_front - (cut_len/2), floor_thick + (cut_height/2)])
                        cube([cutout_r*2 + tight_gap + extra_width, cut_len, cut_height], center=true);
                }
                
                // Finger Rest (Embedded & Lowered)
                translate([0, -l/2, h - 5]) 
                    render_finger_rest();
                
                // --- EXTERNAL SOCKET HOUSINGS ---
                for (mx = [0, 1]) for (my = [0, 1]) {
                    sx = mx == 0 ? -stack_x : stack_x;
                    sy = my == 0 ? -stack_y : stack_y;
                    translate([sx, sy, 0])
                        cylinder(r=stack_col_r, h=h);
                }
            }
            
            // --- SOCKET HOLES (Top and Bottom) ---
            for (mx = [0, 1]) for (my = [0, 1]) {
                sx = mx == 0 ? -stack_x : stack_x;
                sy = my == 0 ? -stack_y : stack_y;
                
                // Top Socket
                translate([sx, sy, h]) {
                    translate([0,0, -stack_socket_depth]) cylinder(r=stack_pin_r, h=stack_socket_depth + 1);
                    translate([0,0, -1]) cylinder(r1=stack_pin_r, r2=stack_pin_r+1, h=1.01); // Chamfer
                }
                
                // Bottom Socket
                translate([sx, sy, -1]) {
                    cylinder(r=stack_pin_r, h=stack_socket_depth + 1);
                    translate([0,0, 0]) cylinder(r1=stack_pin_r+1, r2=stack_pin_r, h=1); // Chamfer
                }
            }
        }
        
        mid_y = (pin_y_front + pin_y_back) / 2;
        dist_to_center = (w/2 - wall_thick);
    
        translate([-(w/2 - wall_thick), mid_y, floor_thick])
            side_filler_shape(pin_y_front, pin_y_back, mid_y, dist_to_center, false, cutout_r);
    
        translate([(w/2 - wall_thick), mid_y, floor_thick])
            side_filler_shape(pin_y_front, pin_y_back, mid_y, dist_to_center, true, cutout_r);
    
        translate([0, pin_y_front, 0]) pin(pin_top_z);
        translate([0, pin_y_back, 0]) pin(pin_top_z);
        translate([final_idler_x, -final_box_center_y, 0]) pin(pin_top_z - drop_amt);
    }
}

module render_finger_rest() {
    rest_w = 30; rest_d = 12; rest_h = 8; embed_depth = 3.0; 
    rotate([0, 0, 180]) hull() {
        translate([-rest_w/2, -embed_depth, -rest_h]) cube([rest_w, embed_depth, rest_h]);
        translate([-rest_w/2, rest_d, -2]) cube([rest_w, 2, 2]);
    }
}

module side_filler_shape(y_f, y_b, y_mid, dist_to_center, is_right, r_cut) {
    filler_h = total_stack_h - drop_amt; 
    block_w = dist_to_center; 
    gear_x_rel = is_right ? -dist_to_center : dist_to_center;
    cube_center_x = is_right ? -block_w/2 : block_w/2;
    tight_gap = 1.0; idler_clearance = 2.5; 
    
    difference() {
        translate([cube_center_x, 0, filler_h/2])
            cube([block_w, abs(y_b - y_f), filler_h], center=true);
        translate([gear_x_rel, y_f - y_mid, -1]) cylinder(r=r_cut + tight_gap, h=filler_h + 10);
        translate([gear_x_rel, y_b - y_mid, -1]) cylinder(r=r_cut + tight_gap, h=filler_h + 10);
        if (is_right) translate([gear_x_rel + final_idler_x, 0, -1]) cylinder(r=r_idler_final + idler_clearance, h=filler_h + 10); 
    }
}

module pin(h_val) {
    difference() {
        cylinder(h=h_val, r=6); 
        translate([0,0, floor_thick]) cylinder(h=h_val + 10, d=5); 
    }
}

module gear_unit(teeth, radius, h_val, col, show_oring=false, override_mode=-1) {
    clearance = 1.0; 
    current_mode = (override_mode > -1) ? override_mode : TRACTION_MODE;
    traction_r_start = 8; traction_r_end = radius - 3; 
    
    color(col) {
        difference() {
            union() {
                difference() {
                    cylinder(r=10, h=spacer_h); 
                    translate([0,0,-1]) cylinder(r=(12+clearance)/2, h=spacer_h+2); 
                }
                translate([0,0, spacer_h]) simple_herringbone_gear(teeth, pitch_val, h_val, 12 + clearance, 0);
                if (current_mode == 2) translate([0, 0, spacer_h + h_val]) traction_nubs(traction_r_start, traction_r_end);
            }
            if (current_mode == 1) {
                groove_w = 3.8; groove_d = 2.0; groove_r_center = 24; 
                translate([0, 0, spacer_h + h_val - groove_d + 0.01]) difference() {
                    cylinder(r=groove_r_center + groove_w/2, h=groove_d+1);
                    translate([0,0,-1]) cylinder(r=groove_r_center - groove_w/2, h=groove_d+5);
                }
            }
        }
    }
    if (show_oring && current_mode == 1) {
        oring_thick = 3.175; groove_r_center = 24; groove_d = 2.0;
        z_pos = spacer_h + h_val - groove_d + (oring_thick/2);
        color("Black") translate([0, 0, z_pos]) rotate_extrude($fn=60) translate([groove_r_center, 0, 0]) circle(r=oring_thick/2, $fn=20);
    }
}

module traction_nubs(r_inner, r_outer) {
    nub_size = 0.8; spacing = 3.0; nub_height = 0.8; 
    linear_extrude(height = nub_height) intersection() {
        difference() { circle(r=r_outer); circle(r=r_inner); }
        for (x = [-r_outer : spacing : r_outer]) for (y = [-r_outer : spacing : r_outer]) translate([x, y]) circle(r=nub_size, $fn=8);
    }
}

module rounded_rect(w, l, h, r) {
    translate([-w/2, -l/2, 0]) hull() {
        translate([r, r, 0]) cylinder(r=r, h=h);
        translate([w-r, r, 0]) cylinder(r=r, h=h);
        translate([w-r, l-r, 0]) cylinder(r=r, h=h);
        translate([r, l-r, 0]) cylinder(r=r, h=h);
    }
}

module simple_herringbone_gear(teeth, pitch_val, h, bore, twist_val) {
    r_pitch = (teeth * pitch_val) / 360;
    tooth_w = (r_pitch * 6.28) / teeth / 2;
    linear_extrude(height=h, twist=twist_val, slices=60, convexity=10) difference() {
        union() {
            circle(r=r_pitch - 1.5);
            for(i=[0:teeth-1]) rotate([0,0, i*(360/teeth)]) translate([0, r_pitch - 1.5, 0]) polygon([[-tooth_w/1.8, -1], [tooth_w/1.8, -1], [tooth_w/3, 3.0], [-tooth_w/3, 3.0]]);
        }
        circle(r=bore/2);
    }
}