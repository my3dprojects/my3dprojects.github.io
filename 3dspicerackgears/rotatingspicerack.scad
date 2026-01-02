// --- FINAL SPICE RACK: FORCED LOZENGE HANDLE & O-RING GEARS ---
// UPDATE: IDLER PIN AND GEAR HEIGHT MADE FLUSH WITH FILLER SHAPE

$fn = 60; 

// --- 1. CONFIGURATION ---

// 0 = ASSEMBLY VIEW
// 1 = BOX (With 3rd Pin for Idler)
// 2 = GEARS (Set to 2 to print your new gears)
// 3 = HANDLE (Strict Lozenge with O-Ring Clearance Cut)
PART_TO_PRINT = 2; 

// --- TRACTION SETTINGS ---
// 0 = Smooth (Original)
// 1 = O-Ring Groove (Standard #224 O-Ring)
// 2 = Printed "Nubs" Texture 
TRACTION_MODE = 1; 

INCH = 25.4;
wall_thick = 3;
floor_thick = 4;
base_height = 2 * INCH; 

// --- 2. FIXED GEOMETRY ---
orig_gap = 0.5; 
orig_len = (9.75 * INCH) - (wall_thick * 2);
orig_diam = (orig_len - (orig_gap * 3)) / 2;
orig_r = orig_diam / 2;

FIXED_PIN_Y_BACK  =  (orig_r + orig_gap/2);
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

teeth_main  = round((r_main_new * 360) / pitch_val);
teeth_idler = round((r_idler * 360) / pitch_val);

r_main_final  = (teeth_main * pitch_val) / 360;
r_idler_final = (teeth_idler * pitch_val) / 360;

dist_final = r_main_final + r_idler_final + 0.5; 
final_idler_x = sqrt(pow(dist_final, 2) - pow(y_offset, 2));


// --- 4. Z HEIGHTS (ADJUSTED) ---
gear_h = 8;            
spacer_h = 0.5;        
total_stack_h = spacer_h + gear_h; 

// *** FIX APPLIED HERE ***
// Removed the extra "+ 0.5" so the pin is exactly the height of the filler/gears
pin_top_z = floor_thick + total_stack_h; 


// --- 5. RENDER LOGIC ---

if (PART_TO_PRINT == 0) {
    // ASSEMBLY VIEW
    render_box();
    translate([0, FIXED_PIN_Y_FRONT, floor_thick]) gear_unit(teeth_main, r_main_final, "Silver", show_oring=true);
    translate([0, FIXED_PIN_Y_BACK, floor_thick])  gear_unit(teeth_main, r_main_final, "Silver", show_oring=true);
    translate([final_idler_x, 0, floor_thick]) gear_unit(teeth_idler, r_idler_final, "Gold");
    translate([0, 0, pin_top_z]) render_handle(printing=false);
} 
else if (PART_TO_PRINT == 1) {
    // PRINT: BOX (With 3rd Pin)
    render_box();
}
else if (PART_TO_PRINT == 2) {
    // PRINT: GEARS
    translate([-r_main_final - 2, 0, 0]) gear_unit(teeth_main, r_main_final, "Silver");
    translate([r_main_final + 2, 0, 0])  gear_unit(teeth_main, r_main_final, "Silver");
    translate([0, r_main_final + r_idler_final + 5, 0]) gear_unit(teeth_idler, r_idler_final, "Gold");
} 
else if (PART_TO_PRINT == 3) {
    // PRINT: HANDLE (Forced Lozenge with Relief Cut)
    render_handle(printing=true);
}


// --- MODULES ---

module render_handle(printing) {
    handle_h = base_height - pin_top_z;
    rot_vec = printing ? [180, 0, 0] : [0, 0, 0];
    pos_vec = printing ? [0, 0, handle_h] : [0, 0, 0];
    
    // Lozenge Cut Params
    shave_offset = 2.0; 
    cut_len = (FIXED_PIN_Y_BACK - FIXED_PIN_Y_FRONT) + (shave_offset * 2);
    cut_center_y = (FIXED_PIN_Y_BACK + FIXED_PIN_Y_FRONT) / 2;

    // Relief Cut Params (For O-Ring)
    cut_depth = 3.0;
    // Length of the handle between pin centers
    center_dist = FIXED_PIN_Y_BACK - FIXED_PIN_Y_FRONT;
    // We leave 5.0mm of material around each pin center
    safety_margin = 5.0; 
    relief_cut_len = center_dist - (safety_margin * 2);

    translate(pos_vec)
    rotate(rot_vec)
    color("Crimson")
    union() {
        difference() {
            intersection() {
                // ORIGINAL HULL (Capsule Shape)
                hull() {
                    translate([0, FIXED_PIN_Y_FRONT, 0]) cylinder(r=6, h=handle_h); 
                    translate([0, FIXED_PIN_Y_BACK, 0]) cylinder(r=6, h=handle_h);
                }
                
                // SHAVING CUBE (Forces Flat Ends)
                translate([0, cut_center_y, handle_h/2])
                    cube([20, cut_len, handle_h + 10], center=true);
            }

            // --- THE RELIEF CUT ---
            // Removes bottom 3.0mm, but stops 5.0mm short of the pins
            translate([0, cut_center_y, cut_depth/2]) 
                cube([20, relief_cut_len, cut_depth], center=true);
        }
        
        // Connectors for Main Pins (Original Length/Pos)
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
    
    color("Teal") {
        difference() {
            rounded_rect(w, l, h, 10);
            translate([0, 0, floor_thick]) 
                rounded_rect(w - wall_thick*2, l - wall_thick*2, h + 10, 5);
            
            translate([0, -l/2, floor_thick + (gear_h/2) + 5])
                cube([cutout_r*2 + 6, 20, gear_h + 20], center=true);
                
            translate([0, -l/2, h])
                  cube([cutout_r*1.6, 20, 20], center=true);
        }
        
        pin_y_front = FIXED_PIN_Y_FRONT - final_box_center_y;
        pin_y_back  = FIXED_PIN_Y_BACK  - final_box_center_y;
        mid_y = (pin_y_front + pin_y_back) / 2;
        dist_to_center = (w/2 - wall_thick);
    
        translate([-(w/2 - wall_thick), mid_y, floor_thick])
            side_filler_shape(pin_y_front, pin_y_back, mid_y, dist_to_center, false, cutout_r);
    
        translate([(w/2 - wall_thick), mid_y, floor_thick])
            side_filler_shape(pin_y_front, pin_y_back, mid_y, dist_to_center, true, cutout_r);
    
        translate([0, pin_y_front, 0]) pin();
        translate([0, pin_y_back, 0]) pin();
        
        // 3rd Pin
        translate([final_idler_x, -final_box_center_y, 0]) pin();
    }
}

module side_filler_shape(y_f, y_b, y_mid, dist_to_center, is_right, r_cut) {
    filler_h = total_stack_h;
    block_w = dist_to_center; 
    
    gear_x_rel = is_right ? -dist_to_center : dist_to_center;
    cube_center_x = is_right ? -block_w/2 : block_w/2;
    
    difference() {
        translate([cube_center_x, 0, filler_h/2])
            cube([block_w, abs(y_b - y_f), filler_h], center=true);
            
        translate([gear_x_rel, y_f - y_mid, -1])
            cylinder(r=r_cut + 3.0, h=filler_h + 10);
        translate([gear_x_rel, y_b - y_mid, -1])
            cylinder(r=r_cut + 3.0, h=filler_h + 10);
            
        if (is_right) {
            translate([gear_x_rel + final_idler_x, 0, -1])
                cylinder(r=r_idler_final + 3.0, h=filler_h + 10); 
        }
    }
}

module pin() {
    difference() {
        cylinder(h=pin_top_z, r=6); 
        translate([0,0, floor_thick])
            cylinder(h=pin_top_z + 10, d=5); 
    }
}

module gear_unit(teeth, radius, col, show_oring=false) {
    clearance = 0.6; 
    
    // Traction Parameters
    traction_r_start = 15; 
    traction_r_end   = radius - 3; 
    
    color(col) {
        difference() {
            union() {
                // 1. The Base Spacer
                difference() {
                    cylinder(r=10, h=spacer_h); 
                    translate([0,0,-1])
                        cylinder(r=(12+clearance)/2, h=spacer_h+2); 
                }
                
                // 2. The Gear
                translate([0,0, spacer_h])
                    simple_herringbone_gear(teeth, pitch_val, gear_h, 12 + clearance, 0);
                
                // 3. ADDITIVE TRACTION (Mode 2: Nubs)
                if (TRACTION_MODE == 2) {
                    translate([0, 0, spacer_h + gear_h])
                        traction_nubs(traction_r_start, traction_r_end);
                }
            }
            
            // 4. SUBTRACTIVE TRACTION (Mode 1: O-Ring Groove)
            if (TRACTION_MODE == 1) {
                // Dimensions for AS568-224 O-Ring (ID=44mm, Width=3.5mm)
                groove_w = 3.8;       
                groove_d = 2.0;       
                groove_r_center = 24; // Radius 24 = Diameter 48mm
                
                translate([0, 0, spacer_h + gear_h - groove_d + 0.01]) 
                    difference() {
                        cylinder(r=groove_r_center + groove_w/2, h=groove_d+1);
                        translate([0,0,-1])
                            cylinder(r=groove_r_center - groove_w/2, h=groove_d+5);
                    }
            }
        }
    }
    
    // 5. VISUAL O-RING (Only shows if show_oring is true)
    if (show_oring && TRACTION_MODE == 1) {
        // O-Ring Calculation based on user specs (1.75" ID, 2.0" OD)
        // Thickness = (2.0 - 1.75)/2 = 0.125 inch = 3.175mm
        oring_thick = 3.175;
        
        // We use the groove_r_center (24mm) for the visual radius
        // because the O-ring is stretched onto the gear.
        groove_r_center = 24; 
        groove_d = 2.0;

        // Position: Bottom of groove is at (spacer_h + gear_h - groove_d)
        // Center of O-ring is half its thickness up from that bottom.
        z_pos = spacer_h + gear_h - groove_d + (oring_thick/2);

        color("Black")
        translate([0, 0, z_pos])
        rotate_extrude($fn=60)
        translate([groove_r_center, 0, 0])
        circle(r=oring_thick/2, $fn=20);
    }
}

module traction_nubs(r_inner, r_outer) {
    nub_size = 0.8; 
    spacing = 3.0;  
    nub_height = 0.6;
    
    linear_extrude(height = nub_height)
        intersection() {
            difference() {
                circle(r=r_outer);
                circle(r=r_inner);
            }
            for (x = [-r_outer : spacing : r_outer]) {
                for (y = [-r_outer : spacing : r_outer]) {
                    translate([x, y]) circle(r=nub_size, $fn=8);
                }
            }
        }
}

module rounded_rect(w, l, h, r) {
    translate([-w/2, -l/2, 0])
    hull() {
        translate([r, r, 0]) cylinder(r=r, h=h);
        translate([w-r, r, 0]) cylinder(r=r, h=h);
        translate([w-r, l-r, 0]) cylinder(r=r, h=h);
        translate([r, l-r, 0]) cylinder(r=r, h=h);
    }
}

module simple_herringbone_gear(teeth, pitch_val, h, bore, twist_val) {
    r_pitch = (teeth * pitch_val) / 360;
    tooth_w = (r_pitch * 6.28) / teeth / 2;
    linear_extrude(height=h, twist=twist_val, slices=60, convexity=10)
    difference() {
        union() {
            circle(r=r_pitch - 1.5);
            for(i=[0:teeth-1]) {
                rotate([0,0, i*(360/teeth)])
                translate([0, r_pitch - 1.5, 0])
                polygon([[-tooth_w/1.8, -1], [tooth_w/1.8, -1], [tooth_w/3, 3.0], [-tooth_w/3, 3.0]]);
            }
        }
        circle(r=bore/2);
    }
}