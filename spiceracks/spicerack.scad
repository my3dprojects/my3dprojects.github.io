/**********************************************************************
  Spice Rack Conveyor - BAMBU P1S "SEPARATE PLATE" EDITION
  - FIX: Use this mode to get smooth bottom surfaces.
  - INSTRUCTIONS: 
      1. Set part_to_print = "base", Render (F6), Export STL (F7).
      2. Set part_to_print = "chain", Render (F6), Export STL (F7).
      3. Print separately and drop the chain into the base.
**********************************************************************/

/* [Configuration] */
bottle_diameter = 53;
num_bottles = 8;

/* [View Settings] */
// CHANGE THIS to export your files one by one:
// "base"   -> The red track housing
// "chain"  -> The loop of links (Prints flat on bed)
// "handle" -> The central spinner
part_to_print = "handle";

/* [Dimensions] */
rail_height = 16;            
wall_height = 20;
floor_thickness = 3;
handle_height = 90;
handle_thickness = 15;
sliding_clearance = 1.5;

/* [Animation Controls] */
show_bottles = false;
freeze_for_print = true;     
print_phase = 0;             

/* [Tuning - Pintle Hitch] */
jaw_thickness = 2.8;         
z_gap = 0.35;                
arm_width = 8.0;             

/* [Test Coupon] */
coupon_gap = 6;              

/* --- HINGE SETTINGS --- */
hinge_shank_d   = 5.0;       
hinge_head_d    = 8.6;
hinge_lug_d     = 9.0;      
hinge_clear     = 0.6;       

/* --- CALCULATIONS --- */
ring_wall_thick = 1.2;
ring_outer_dia  = bottle_diameter + (ring_wall_thick*2);

// Link Gap
link_gap = hinge_lug_d + 0.2; 
link_len = ring_outer_dia + link_gap;

ef_relief_h     = 0.6;

/* --- Track layout --- */
bottles_on_curve = 3;
bottles_on_straight = floor((num_bottles - (bottles_on_curve*2)) / 2);

/* IMPORTANT GEOMETRY */
turn_delta  = 180 / bottles_on_curve;
turn_radius = link_len / (2 * sin(turn_delta/2));

straight_len = bottles_on_straight * link_len;

/* Base sizing */
chord_dist_to_center = turn_radius * cos(turn_delta/2);
island_radius = chord_dist_to_center - (ring_outer_dia/2) - sliding_clearance;
track_width   = island_radius * 2;
wall_radius   = turn_radius + (ring_outer_dia/2) + 0.5;
outer_width   = wall_radius * 2;

track_len = straight_len;
handle_spacing = straight_len * 0.6;

/* --- HELPERS --- */
function wrap(i, m) = i - floor(i/m) * m;
function vadd(a,b) = [a[0]+b[0], a[1]+b[1]];
function vmul(a,s) = [a[0]*s, a[1]*s];
function vavg(a,b) = vmul(vadd(a,b), 0.5);

/* --- LINK MODULE (PINTLE STYLE) --- */
module ring_link() {
    
    z_jaw_bot_start = 0;
    z_jaw_bot_end   = jaw_thickness;
    z_lunette_start = z_jaw_bot_end + z_gap;
    z_lunette_end   = rail_height - jaw_thickness - z_gap;
    z_lunette_h     = z_lunette_end - z_lunette_start;
    z_jaw_top_start = rail_height - jaw_thickness;
    z_jaw_top_end   = rail_height;

    chamfer_h = 0.8;

    difference() {
        // POSITIVE GEOMETRY
        union() {
            // 1. MAIN BODY (Ring)
            union() {
                cylinder(h=chamfer_h, d1=ring_outer_dia - 1.2, d2=ring_outer_dia, $fn=64);
                translate([0,0,chamfer_h])
                    cylinder(h=rail_height-chamfer_h, d=ring_outer_dia, $fn=64);
            }

            // 2. MALE LUNETTE (Right Side)
            intersection() {
                translate([0,0,z_lunette_start])
                    cylinder(h=z_lunette_h, d=500); 
                union() {
                    translate([link_len/2, 0, 0])
                        cylinder(h=rail_height, d=hinge_lug_d, $fn=48);
                    
                    hull() {
                        translate([ring_outer_dia/2 - 1, 0, 0])
                            cylinder(h=rail_height, d=arm_width, $fn=32);
                        translate([link_len/2, 0, 0])
                            cylinder(h=rail_height, d=hinge_lug_d, $fn=48);
                    }
                }
            }
            
            // 3. FEMALE JAWS (Left Side)
            intersection() {
                union() {
                    translate([0,0,z_jaw_bot_start]) cylinder(h=jaw_thickness, d=500);
                    translate([0,0,z_jaw_top_start]) cylinder(h=jaw_thickness, d=500);
                }
                union() {
                    translate([-link_len/2, 0, 0])
                        cylinder(h=rail_height, d=hinge_lug_d, $fn=48);
                    
                    hull() {
                        translate([-ring_outer_dia/2 + 1, 0, 0])
                            cylinder(h=rail_height, d=arm_width, $fn=32);
                        translate([-link_len/2, 0, 0])
                            cylinder(h=rail_height, d=hinge_lug_d, $fn=48);
                    }
                }
            }
            
            // 4. PIN
            translate([-link_len/2, 0, 0])
                cylinder(h=rail_height, d=hinge_shank_d, $fn=32);
        }

        // --- SUBTRACTIONS ---

        // 1. BOTTLE HOLE
        translate([0,0,-1]) 
            cylinder(h=rail_height+2, d=bottle_diameter, $fn=64);

        // 2. Pin Hole
        translate([link_len/2, 0, -1])
            cylinder(h=rail_height+2, d=hinge_shank_d + 2*hinge_clear, $fn=32);

        // 3. Elephant Foot Relief
        translate([-link_len/2, 0, -0.01])
             cylinder(h=ef_relief_h, d1=hinge_shank_d + 1.0, d2=hinge_shank_d, $fn=32);
        
        // 4. Internal Chamfers
        translate([link_len/2, 0, z_lunette_start])
             cylinder(h=0.6, d1=hinge_shank_d + 2*hinge_clear + 1.2, d2=hinge_shank_d + 2*hinge_clear, $fn=32);
        translate([link_len/2, 0, z_lunette_end - 0.6])
             cylinder(h=0.6, d1=hinge_shank_d + 2*hinge_clear, d2=hinge_shank_d + 2*hinge_clear + 1.2, $fn=32);
    }
}

/* --- JOINT LOOP GENERATION --- */
right_center = [ straight_len/2, 0 ];
left_center  = [ -straight_len/2, 0 ];

j_top = [ for(i=[0:bottles_on_straight]) [ -straight_len/2 + i*link_len,  turn_radius ] ];
j_right = [
    for(i=[1:bottles_on_curve])
        let(a = 90 - i*turn_delta)
        [ right_center[0] + turn_radius*cos(a), right_center[1] + turn_radius*sin(a) ]
];
j_bottom = [ for(i=[1:bottles_on_straight]) [ straight_len/2 - i*link_len, -turn_radius ] ];
j_left = [
    for(i=[1:bottles_on_curve-1])
        let(a = 270 - i*turn_delta)
        [ left_center[0] + turn_radius*cos(a), left_center[1] + turn_radius*sin(a) ]
];

J = concat(j_top, j_right, j_bottom, j_left);

module chain_closed_loop(zoff=0) {
    anim_offset = freeze_for_print ? print_phase : $t;

    for (i=[0:num_bottles-1]) {
        idx_curr   = wrap(i, num_bottles);
        idx_next   = wrap(i+1, num_bottles);
        idx_next_2 = wrap(i+2, num_bottles);

        p0_start = J[idx_curr];
        p1_start = J[idx_next];
        p0_end   = J[idx_next];
        p1_end   = J[idx_next_2];

        p0 = p0_start + (p0_end - p0_start) * anim_offset;
        p1 = p1_start + (p1_end - p1_start) * anim_offset;

        c  = vavg(p0, p1);
        th = atan2(p1[1]-p0[1], p1[0]-p0[0]);

        translate([c[0], c[1], zoff])
            rotate([0,0,th])
                ring_link();
    }
}

/* --- PARTS --- */
module full_base() {
    union() {
        difference() {
            hull() {
                translate([track_len/2, 0, floor_thickness]) cylinder(h=rail_height, d=track_width, $fn=64);
                translate([-track_len/2, 0, floor_thickness]) cylinder(h=rail_height, d=track_width, $fn=64);
            }
            translate([handle_spacing/2, 0, 0]) cylinder(h=rail_height+10, d=12.5, $fn=32);
            translate([-handle_spacing/2, 0, 0]) cylinder(h=rail_height+10, d=12.5, $fn=32);
        }
        
        shell_offset = 1.5;
        
        difference() {
            hull() {
                translate([track_len/2, 0, 0]) cylinder(h=wall_height, d=outer_width + shell_offset, $fn=64);
                translate([-track_len/2, 0, 0]) cylinder(h=wall_height, d=outer_width + shell_offset, $fn=64);
            }
            translate([0,0,floor_thickness])
            hull() {
                translate([track_len/2, 0, 0]) cylinder(h=wall_height+1, d=outer_width, $fn=64);
                translate([-track_len/2, 0, 0]) cylinder(h=wall_height+1, d=outer_width, $fn=64);
            }
        }
    }
}

module handle() {
    union() {
        translate([handle_spacing/2, 0, 0]) cylinder(h=handle_height, d=handle_thickness, $fn=32);
        translate([-handle_spacing/2, 0, 0]) cylinder(h=handle_height, d=handle_thickness, $fn=32);
        translate([0,0,handle_height])
        hull() {
             translate([handle_spacing/2, 0, 0]) sphere(d=handle_thickness);
             translate([-handle_spacing/2, 0, 0]) sphere(d=handle_thickness);
        }
        translate([handle_spacing/2, 0, -rail_height + 2]) cylinder(h=rail_height, d=12, $fn=32);
        translate([-handle_spacing/2, 0, -rail_height + 2]) cylinder(h=rail_height, d=12, $fn=32);
    }
}

/* --- OUTPUT LOGIC --- */
if (part_to_print == "base") {
    color("IndianRed") full_base();
}
else if (part_to_print == "chain") {
    color("White") chain_closed_loop(0);
}
else if (part_to_print == "handle") {
    translate([0, 0, handle_thickness/2])
        rotate([-90, 0, 0])
            handle();
}
else if (part_to_print == "assembly") {
    color("IndianRed") full_base();
    color("White") chain_closed_loop(floor_thickness + 0.5);
    color("Silver") translate([0,0, floor_thickness + rail_height]) handle();
}
else if (part_to_print == "print_in_place") {
    color("IndianRed") full_base();
    color("White") chain_closed_loop(floor_thickness + 0.25);
}