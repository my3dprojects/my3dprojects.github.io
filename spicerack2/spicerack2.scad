// --- Oblong Geared Spice Rack (Final V5 - 13T Knob) ---
// Plate Size: 256x256mm
// Fixes: 13-tooth Knob, Flush Axles, Safe Print Layout
// UPDATE (2025-12-29):
//  - FIX: Both trays rotate together (same direction) when knob turns.
//  - FIX: Mesh uses overlap engagement (needed for this cut-tooth gear style).

/* [View Mode] */
// Uncheck to see the printable parts layout
show_animation = false;

part_to_print = "knob";

/* [General Dimensions] */
gear_module = 3.5;

tray_teeth_count = 30;
knob_teeth_count = 13;

knob_pd_adjust = 1.0;  // mm to enlarge knob gear pitch diameter (try 0.8–1.6)


// Auto-calculate exact Pitch Diameters
tray_pd = tray_teeth_count * gear_module; // 105mm
knob_pd = (knob_teeth_count * gear_module) + knob_pd_adjust;


tray_wall_height = 15;
base_height = 4;
tolerance = 0.15;

/* [Mesh Tuning] */
// IMPORTANT for this gear style: gears are "notch-cut" from a pitch cylinder,
// so they usually need a tiny OVERLAP to actually interlock.
// Positive = tighter / more engagement. Start 0.15 to 0.25.
mesh_overlap = 0.25;

/* [Hidden] */
$fn = 80;

// Spacing between the two large trays
gear_spacing = tray_pd + 1.0;

// Placement Math
dist_x = gear_spacing / 2;
dist_target = (tray_pd/2) + (knob_pd/2);

// For engagement, reduce the center distance slightly:
mesh_radius = dist_target - mesh_overlap;

// Safe sqrt guard (prevents NaN if values are impossible)
calc_y_offset = -sqrt(max(mesh_radius*mesh_radius - dist_x*dist_x, 0));

// --- Main Logic ---
// --- Main Logic ---
if (part_to_print == "knob") {
    // Print knob by itself at the origin
    drive_knob();
}
else if (show_animation) {
    assembly_animated();
}
else {
    print_layout_bambu_vertical();
}


// --- Layouts ---

module print_layout_bambu_vertical() {
    // 1. Base Housing (Left Side)
    translate([-68, 0, 0])
    rotate([0,0,90])
    base_housing();

    // 2. Tray 1 (Top Right)
    translate([68, 70, 0])
    spice_turntable();

    // 3. Tray 2 (Bottom Right)
    translate([68, -70, 0])
    spice_turntable();

    // 4. Drive Knob (Center Right)
    // Positioned safely at X=38
    translate([38, 0, 0])
    drive_knob();
}

module assembly_animated() {
    knob_turns_per_cycle = 4;
    total_base_rotation = 360 * $t * knob_turns_per_cycle;

    // gear ratio: tray angle = knob angle * (knob_teeth / tray_teeth)
    ratio_knob_to_tray = knob_teeth_count / tray_teeth_count;

    // Knob rotation (sign just affects visual direction)
    knob_angle = -total_base_rotation;

    // With a center knob meshing both trays:
    // - Each tray rotates opposite the knob
    // - Both trays rotate the SAME direction as each other
    tray_angle = (total_base_rotation * ratio_knob_to_tray);

    // Optional: small phase offset on ONE tray
    left_tray_angle  = tray_angle + (180/tray_teeth_count); // 1/2 tooth (6° for 30T)
    right_tray_angle = tray_angle;

    color("White") base_housing();

    color("#44aaff")
    translate([-gear_spacing/2, 0, base_height])
    rotate([0,0, left_tray_angle])
    spice_turntable();

    color("#66cc44")
    translate([gear_spacing/2, 0, base_height])
    rotate([0,0, right_tray_angle])
    spice_turntable();

    color("#ff4444")
    translate([0, calc_y_offset, base_height])
    rotate([0,0, knob_angle])
    drive_knob();
}

// --- Components ---

module base_housing() {
    union() {
        hull() {
            translate([-gear_spacing/2, 0, 0]) cylinder(h=base_height, d=tray_pd + 12);
            translate([gear_spacing/2, 0, 0]) cylinder(h=base_height, d=tray_pd + 12);
            translate([0, calc_y_offset, 0])  cylinder(h=base_height, d=knob_pd + 12);
        }

        // Reduced axle height to sit flush-ish with gear recess
        translate([-gear_spacing/2, 0, 0]) cylinder(h=base_height + 5.5, d=9 - tolerance);
        translate([gear_spacing/2, 0, 0]) cylinder(h=base_height + 5.5, d=9 - tolerance);
        translate([0, calc_y_offset, 0])  cylinder(h=base_height + 5.5, d=7 - tolerance);
    }
}

module spice_turntable() {
    union() {
        simple_gear(tray_teeth_count, tray_pd, 6, 9);
        translate([0,0,6]) {
            difference() {
                cylinder(h=tray_wall_height, d=tray_pd);
                translate([0,0,2]) cylinder(h=tray_wall_height, d=tray_pd - 4);
            }
            cylinder(h=2, d=tray_pd);
        }
    }
}

module drive_knob() {
    union() {
        simple_gear(knob_teeth_count, knob_pd, 6, 7);
        translate([0,0,6]) cylinder(h=25, d=22);
        translate([0,0,6])
        for(i=[0:45:360]) rotate([0,0,i]) translate([11,0,0]) cylinder(h=25, d=4, $fn=16);
    }
}

module simple_gear(num_teeth, pitch_d, height, axle_d) {
    pitch = 360 / num_teeth;
    tooth_depth = gear_module * 1.2;

    difference() {
        cylinder(h=height, d=pitch_d);

        // Axle Hole
        translate([0,0,-1]) cylinder(h=height+2, d=axle_d + tolerance);

        // Chamfer
        translate([0,0,-0.1]) cylinder(h=1.5, d1=axle_d + tolerance + 1.5, d2=axle_d + tolerance);

        for (i = [0 : num_teeth-1]) {
            rotate([0, 0, i * pitch])
            translate([pitch_d/2, 0, -1])
            linear_extrude(height+2)
            // Slimmer tooth profile (0.85 width factor) to prevent jamming
            polygon(points=[
                [-gear_module * 0.85, 0],
                [ gear_module * 0.85, 0],
                [ gear_module * 0.35, -tooth_depth],
                [-gear_module * 0.35, -tooth_depth]
            ]);
        }
    }
}
