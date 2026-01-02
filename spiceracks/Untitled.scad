/**********************************************************************
 Spice Rack Conveyor Animation (PRINT-IN-PLACE HINGE CHAIN) — PS1 READY
 - PS1 bed is 256 x 256
 - DO NOT print "chain_loop" on PS1 (too large).
 - Use "ps1_chain_coil" for print-in-place chain that fits the bed.
**********************************************************************/

/* [Configuration] */
bottle_diameter = 53;
num_bottles = 14;

/* [View Settings] */
// Options: "assembly", "animation", "chain_loop", "ps1_chain_coil", "all_rings_plated",
//          "base_left", "base_right", "handle", "joint_test"
part_to_print = "ps1_chain_coil";

/* [Dimensions] */
rail_height = 15;
wall_height = 20;
floor_thickness = 3;
handle_height = 90;
handle_thickness = 15;
sliding_clearance = 1.5;

/* [Animation Controls] */
anim_loops_per_cycle = 1;
show_bottles = true;
bottle_height = 80;
bottle_alpha = 0.18;

/* --- PS1 BUILD PLATE (reference only) --- */
ps1_bed_x = 256;
ps1_bed_y = 256;
bed_margin = 4;          // visual margin
show_bed_outline = true; // set false if you don’t want the outline

/* --- CALCULATIONS --- */
ring_wall_thick = 3;
ring_outer_dia = bottle_diameter + (ring_wall_thick*2);

// Link spacing FIX (prevents ring-to-ring collision on turns)
link_gap = 2;                 // if track rubs in real life, use 3
link_len = ring_outer_dia + link_gap;

/* --- PRINT-IN-PLACE HINGE PARAMS (captive pin, no assembly) --- */
hinge_shank_d   = 5.0;
hinge_head_d    = 8.6;
hinge_head_h    = 2.2;
hinge_clear     = 0.40;

hinge_lug_d     = 14;

// Anti-elephant-foot relief
ef_relief_h = 0.6;
ef_extra    = 0.35;

// Track layout (final installed shape)
bottles_on_curve = 3;
bottles_on_straight = (num_bottles - (bottles_on_curve*2)) / 2;

turn_radius = (bottles_on_curve * link_len) / PI;
straight_len = bottles_on_straight * link_len;

island_radius = turn_radius - (ring_outer_dia/2) - sliding_clearance;
track_width = island_radius * 2;

wall_radius = turn_radius + (ring_outer_dia/2) + sliding_clearance;
outer_width = wall_radius * 2;

track_len = straight_len;
handle_spacing = straight_len * 0.6;

/* --- HELPERS --- */
function wrap(x, m) = x - floor(x/m) * m;
function vadd(a,b) = [a[0]+b[0], a[1]+b[1]];
function rot2(th, v) =
    let(t = th*PI/180)
    [ v[0]*cos(t) - v[1]*sin(t),
      v[0]*sin(t) + v[1]*cos(t) ];

/* Racetrack path length (centerline) */
track_L = (2 * straight_len) + (2 * PI * turn_radius);

/* pos_dir(s) returns [x, y, thetaDeg] for distance s along the racetrack */
function pos_dir(s) =
    (s < straight_len)
        ? [ -straight_len/2 + s,  turn_radius, 0 ]
    : (s < straight_len + PI*turn_radius)
        ? let(
            u = (s - straight_len) / (PI*turn_radius),
            a = 90 - (u * 180)
          )
          [  straight_len/2 + turn_radius*cos(a),
             turn_radius*sin(a),
             a - 90 ]
    : (s < (2*straight_len + PI*turn_radius))
        ? let(u = (s - (straight_len + PI*turn_radius)))
          [  straight_len/2 - u, -turn_radius, 180 ]
    : let(
          u = (s - (2*straight_len + PI*turn_radius)) / (PI*turn_radius),
          a = -90 - (u * 180)
      )
      [ -straight_len/2 + turn_radius*cos(a),
         turn_radius*sin(a),
         a - 90 ];

/* --- MODULES --- */

module bed_outline_ps1() {
    if (!show_bed_outline) return;
    // thin outline rectangle centered at origin
    color([0,0,0,0.15])
    translate([0,0,-0.4])
    linear_extrude(0.4)
    difference() {
        square([ps1_bed_x - 2*bed_margin, ps1_bed_y - 2*bed_margin], center=true);
        square([ps1_bed_x - 2*bed_margin - 2, ps1_bed_y - 2*bed_margin - 2], center=true);
    }
}

// PRINT-IN-PLACE LINK
module ring_link() {
    shank_hole_d = hinge_shank_d + 2*hinge_clear;

    difference() {
        union() {
            // Ring body
            cylinder(h=rail_height, d=ring_outer_dia, $fn=64);

            // Bridge
            translate([link_len/4, 0, rail_height/2])
                cube([link_len/2, 8, rail_height], center=true);

            // MALE PIN at +X
            translate([link_len/2, 0, 0])
                cylinder(h=rail_height, d=hinge_shank_d, $fn=48);

            // Tapered head
            translate([link_len/2, 0, rail_height])
                cylinder(h=hinge_head_h, d1=hinge_shank_d, d2=hinge_head_d, $fn=64);

            // FEMALE LUG at -X
            translate([-link_len/2, 0, 0])
                cylinder(h=rail_height, d=hinge_lug_d, $fn=64);
        }

        // Bottle hole
        translate([0,0,-1])
            cylinder(h=rail_height+2, d=bottle_diameter, $fn=64);

        // Female lug through-hole
        translate([-link_len/2, 0, -1])
            cylinder(h=rail_height+hinge_head_h+3, d=shank_hole_d, $fn=64);

        // Elephant-foot relief
        translate([-link_len/2, 0, -0.01])
            cylinder(h=ef_relief_h, d=shank_hole_d + 2*ef_extra, $fn=64);
    }
}

/* -------- JOINT TURN CHECK -------- */
joint_angle_deg = 60;
show_collision = true;

module joint_test(angle=60) {
    color("White") ring_link();

    joint = [link_len/2, 0, 0];

    color("White")
    translate(joint)
        rotate([0,0,angle])
            translate([-joint[0], -joint[1], 0])
                translate([link_len, 0, 0])
                    ring_link();

    if (show_collision) {
        color("Red")
        intersection() {
            ring_link();
            translate(joint)
                rotate([0,0,angle])
                    translate([-joint[0], -joint[1], 0])
                        translate([link_len, 0, 0])
                            ring_link();
        }
    }
}

/* --- BASE + HANDLE (unchanged) --- */

module base_island_shape() {
    difference() {
        hull() {
            translate([track_len/2, 0, 0]) cylinder(h=rail_height, d=track_width, $fn=64);
            translate([-track_len/2, 0, 0]) cylinder(h=rail_height, d=track_width, $fn=64);
        }
        translate([handle_spacing/2, 0, 0]) cylinder(h=rail_height+1, d=12.5, $fn=32);
        translate([-handle_spacing/2, 0, 0]) cylinder(h=rail_height+1, d=12.5, $fn=32);
    }
}

module base_shell_shape() {
    difference() {
        hull() {
            translate([track_len/2, 0, 0]) cylinder(h=wall_height, d=outer_width + 6, $fn=64);
            translate([-track_len/2, 0, 0]) cylinder(h=wall_height, d=outer_width + 6, $fn=64);
        }
        translate([0,0,floor_thickness])
        hull() {
            translate([track_len/2, 0, 0]) cylinder(h=wall_height+1, d=outer_width, $fn=64);
            translate([-track_len/2, 0, 0]) cylinder(h=wall_height+1, d=outer_width, $fn=64);
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

module dovetail(tol=0) {
    translate([0, -100, 0])
    linear_extrude(wall_height + 5)
    polygon([[-8+tol, -10], [-5+tol, 250], [5-tol, 250], [8-tol, -10]]);
}

module full_base() {
    union() {
        translate([0,0,floor_thickness]) base_island_shape();
        base_shell_shape();
    }
}

module base_left() {
    difference() {
        full_base();
        translate([0, -250, -1]) cube([250, 500, 100]);
        dovetail(tol = -0.15);
    }
}

module base_right() {
    union() {
        difference() {
            full_base();
            translate([-250, -250, -1]) cube([250, 500, 100]);
        }
        intersection() { full_base(); dovetail(tol=0); }
    }
}

/* --- CHAIN PLACEMENT: final installed racetrack (visual only) --- */

module ring_at_distance(s, zoff=0) {
    pd = pos_dir(s);
    translate([pd[0], pd[1], zoff])
        rotate([0,0,pd[2]])
            ring_link();

    if (show_bottles) {
        color([0.8, 0.8, 1.0, bottle_alpha])
        translate([pd[0], pd[1], zoff + 0.2])
            cylinder(h=bottle_height, d=bottle_diameter*0.98, $fn=48);
    }
}

module chain_static_loop(zoff=0) {
    for (i = [0 : num_bottles-1]) {
        s = wrap(i*link_len, track_L);
        ring_at_distance(s, zoff);
    }
}

module animated_chain(zoff=0) {
    base_shift = wrap($t * track_L * anim_loops_per_cycle, track_L);
    for (i = [0 : num_bottles-1]) {
        s = wrap(i*link_len + base_shift, track_L);
        ring_at_distance(s, zoff);
    }
}

/* --- PS1-FRIENDLY PRINT-IN-PLACE CHAIN LAYOUT --- */
/*
  We “coil” the connected chain using a constant joint angle so the whole
  (already-interlocked) chain fits on a 256x256 bed.

  - This prints as ONE connected print-in-place chain.
  - After printing, flex joints and then “uncoil” into the racetrack.
*/
ps1_coil_angle = 38;     // degrees per joint (35–42 works well for PS1 packing)
ps1_coil_center = true;  // just a visual centering helper

// Forward-kinematics state for link i: [[x,y], headingDeg]
function chain_state(i, a) =
    (i == 0)
        ? [[0,0], 0]
        : let(
            prev = chain_state(i-1, a),
            O    = prev[0],
            th   = prev[1],
            J    = vadd(O, rot2(th, [link_len/2, 0])),
            th2  = th + a[i-1],
            O2   = vadd(J, rot2(th2, [link_len/2, 0]))
          )
          [O2, th2];

module chain_coil(angle_deg=38) {
    // joint angles list (length num_bottles-1)
    A = [ for(k=[0:num_bottles-2]) angle_deg ];

    // Optionally center-ish (slicer can also center; this just helps visually)
    // We'll just translate so first link starts near center.
    T = ps1_coil_center ? [0,0,0] : [0,0,0];

    translate(T)
    for (i=[0:num_bottles-1]) {
        st = chain_state(i, A);
        O  = st[0];
        th = st[1];
        translate([O[0], O[1], 0])
            rotate([0,0,th])
                ring_link();
    }
}

/* --- OUTPUT MODES --- */

if (part_to_print == "joint_test") {
    bed_outline_ps1();
    joint_test(joint_angle_deg);
}
else if (part_to_print == "ps1_chain_coil") {
    bed_outline_ps1();
    // PRINT THIS on PS1 (print-in-place chain that fits the bed)
    show_bottles = false;
    chain_coil(ps1_coil_angle);
}
else if (part_to_print == "chain_loop") {
    // WARNING: Too large for PS1. Use ps1_chain_coil instead.
    chain_static_loop(0);
}
else if (part_to_print == "animation") {
    color("FireBrick") base_left();
    color("IndianRed") base_right();
    color("Silver") translate([0,0, floor_thickness + rail_height]) handle();
    animated_chain(floor_thickness);
}
else if (part_to_print == "assembly") {
    color("FireBrick") base_left();
    color("IndianRed") base_right();
    chain_static_loop(floor_thickness);
    color("Silver") translate([0,0, floor_thickness + rail_height]) handle();
}
else if (part_to_print == "all_rings_plated") {
    for(i=[0:num_bottles-1]) {
        translate([(i % 4) * (bottle_diameter + 20), floor(i / 4) * (bottle_diameter + 20), 0])
            ring_link();
    }
}
else if (part_to_print == "base_left") {
    base_left();
}
else if (part_to_print == "base_right") {
    base_right();
}
else if (part_to_print == "handle") {
    rotate([180,0,0]) handle();
}
