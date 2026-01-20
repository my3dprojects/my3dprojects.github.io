// --- Projector Tilt Riser (FINAL ALIGNMENT + ASSEMBLY FLIP) ---

/* [Export Selection] */
// 0 = Assembly View (Flipped Top, Screw on Top)
// 1 = Top Plate (Printable)
// 2 = Bottom Plate (Printable)
// 3 = Hardware (Pins & Screw)
print_selection = 1; 

/* [Dimensions] */
width_inch = 9; 
depth_inch = 6; 
plate_thickness = 6; 

/* [Hardware Settings] */
screw_dia = 14; 
screw_len = 60; 
pitch = 4;
thread_clearance = 0.8; 

/* [Extension Settings] */
tab_extension = 30; 
tab_radius = 28; 

/* [Hinge Settings] */
hinge_pin_dia = 10; 
hinge_radius = 8;
hinge_clearance = 0.6; 
// Pushes the hinge back from the plate edge to prevent binding
hinge_offset = 4; 

/* [Hidden] */
$fn = 60; 
w = width_inch * 25.4;
d = depth_inch * 25.4;

// --- Main Logic ---
if (print_selection == 0) {
    color("Teal") bottom_plate(); 
    
    // --- ASSEMBLY LOGIC ---
    // Pivot Point Location:
    // Y = d + hinge_offset (Center of hinge pin)
    // Z = plate_thickness * 2 (12mm - Aligned with raised bottom hinge)
    
    translate([0, d + hinge_offset, plate_thickness * 2]) 
        rotate([-10, 0, 0]) // Tilt angle (adjust as needed)
        translate([0, -(d + hinge_offset), -(plate_thickness * 2)]) 
        union() {
            // --- TOP PLATE (FLIPPED) ---
            // 1. We rotate [0, 180, 0] to flip it upside down (Ridge Down) while keeping Y orientation.
            // 2. We translate X by 'w' to compensate for the flip.
            // 3. We translate Z by 'plate_thickness * 3' (18mm) to align the flipped hinge (z=-6) to the target (z=12).
            translate([w, 0, plate_thickness * 3]) 
                rotate([0, 180, 0]) 
                color("CornflowerBlue") top_plate(); 
            
            // --- SCREW (ON TOP) ---
            // 1. Rotate 180 X to point shaft down.
            // 2. Translate to align with the tab hole.
            //    Z = 22mm (12mm Plate Height + 10mm Screw Head Thickness compensation)
            translate([w/2, -tab_extension, plate_thickness * 2 + 10]) 
                rotate([180, 0, 0]) 
                color("Orange") printable_screw(); 
        }
        
    // --- PINS ---
    // Aligned to the new Hinge Axis
    translate([-2, d + hinge_offset, plate_thickness * 2]) 
        rotate([0,90,0]) 
        color("Orange") hinge_pin_printable();
        
    translate([w+2, d + hinge_offset, plate_thickness * 2]) 
        rotate([0,-90,0]) 
        color("Orange") hinge_pin_printable();

} else if (print_selection == 1) {
    top_plate();
} else if (print_selection == 2) {
    bottom_plate();
} else if (print_selection == 3) {
    translate([0, 0, 0]) printable_screw();
    translate([50, 0, 0]) hinge_pin_printable();
    translate([80, 0, 0]) hinge_pin_printable();
}

// --- Modules ---

module grid_cutouts() {
    cutout_w = (w - 30) / 4; 
    cutout_d = (d - 60) / 3; 
    gap = 8; 
    for (ix = [0:3]) {
        for (iy = [0:2]) {
            translate([15 + ix*cutout_w + gap/2, 15 + iy*cutout_d + gap/2, -1])
                minkowski() {
                    cube([cutout_w - gap - 4, cutout_d - gap - 4, plate_thickness + 2]);
                    cylinder(r=2, h=0.1); 
                }
        }
    }
}

module top_plate() {
    difference() {
        union() {
            difference() {
                cube([w, d, plate_thickness]);
                grid_cutouts();
                
                // --- TRIMMED BACK EDGES ---
                translate([-1, d - 5, -1])
                    cube([(w/3) + 1, 10, plate_thickness + 2]);
                translate([w - (w/3), d - 5, -1])
                    cube([(w/3) + 1, 10, plate_thickness + 2]);
            }
            
            // --- FIXED RIDGE ---
            translate([15, 0, plate_thickness]) 
                cube([w - 30, 6, hinge_radius]);

            // Threaded Tab
            translate([w/2, 0, 0]) difference() {
                hull() {
                    translate([0, -tab_extension, 0]) cylinder(h=plate_thickness, r=tab_radius);
                    translate([-tab_radius, 0, 0]) cube([tab_radius*2, 0.1, plate_thickness]);
                }
                translate([0, -tab_extension, -1]) 
                    threads(diameter=screw_dia + thread_clearance, pitch=pitch, length=plate_thickness + 2);
            }

            // Hinge Knuckles
            translate([0, d, 0]) {
                knuckle_len = w/3 - hinge_clearance;
                
                // Cylinder moved back by hinge_offset
                translate([w/3 + hinge_clearance/2, hinge_offset, plate_thickness]) 
                    rotate([0,90,0]) 
                    cylinder(h=knuckle_len, r=hinge_radius);

                // Support Block 
                translate([w/3 + hinge_clearance/2, -hinge_radius, 0]) 
                    cube([knuckle_len, hinge_radius, plate_thickness]);
            }
        }

        // --- GLOBAL HOLE CUT ---
        translate([-50, d + hinge_offset, plate_thickness]) 
            rotate([0,90,0]) 
            cylinder(h=w+100, d=hinge_pin_dia + 0.6);

        // Flush Cut (Top Back)
        translate([-50, d + hinge_offset + 10, plate_thickness]) cube([1000, 50, 50]);

        // Floor Cut (D-Shape Profile)
        translate([-50, -50, -50]) cube([2000, 2000, 50]);
    }
}

module bottom_plate() {
    // Hinge Axis is at 12mm absolute Z
    hinge_z = plate_thickness * 2; 

    difference() {
        union() {
            difference() {
                cube([w, d, plate_thickness]);
                grid_cutouts();
            }
            translate([w/2, 0, 0]) difference() {
                hull() {
                    translate([0, -tab_extension, 0]) cylinder(h=plate_thickness, r=tab_radius);
                    translate([-tab_radius, 0, 0]) cube([tab_radius*2, 0.1, plate_thickness]);
                }
                translate([0, -tab_extension, plate_thickness - 2.0]) 
                    cylinder(h=2.1, d=screw_dia + 4); 
            }
            
            // Hinge Structure
            translate([0, d, 0]) {
                 knuckle_len = w/3 - hinge_clearance;
                 
                 // Cylinder 1 (Raised & Offset)
                 translate([0, hinge_offset, hinge_z]) 
                    rotate([0,90,0]) 
                    cylinder(h=knuckle_len, r=hinge_radius);

                 // Cylinder 2 (Raised & Offset)
                 translate([w - knuckle_len, hinge_offset, hinge_z]) 
                    rotate([0,90,0]) 
                    cylinder(h=knuckle_len, r=hinge_radius);

                 // Support 1 (Extended)
                 translate([0, -hinge_radius, 0]) 
                    cube([knuckle_len, hinge_radius + hinge_offset, hinge_z]);
                 
                 // Support 2 (Extended)
                 translate([w-knuckle_len, -hinge_radius, 0]) 
                    cube([knuckle_len, hinge_radius + hinge_offset, hinge_z]);
            }
        }
        
        // --- GLOBAL HOLE CUT ---
        translate([-50, d + hinge_offset, hinge_z]) 
            rotate([0,90,0]) 
            cylinder(h=w+100, d=hinge_pin_dia + 0.6);

        // Floor Cut (Standard)
        translate([-50, -50, -50]) cube([1000, 1000, 50]);

        // --- MATCHING PROFILE CUT ---
        translate([-50, d + hinge_offset - hinge_radius, 0])
            cube([w+100, hinge_radius*2, hinge_z - plate_thickness]);
    }
}

module printable_screw() {
    union() {
        difference() {
             union() { cylinder(h=10, d=38); for(i=[0:30:360]) rotate([0,0,i]) translate([19,0,0]) cylinder(h=10, r=2.5); }
        }
        translate([0,0,10]) 
            threads(diameter=screw_dia, pitch=pitch, length=screw_len);
    }
}

module hinge_pin_printable() {
    pin_L = (w/3) + 15;
    union() {
        cylinder(h=4, d=hinge_pin_dia + 6);
        translate([0,0,4]) cylinder(h=pin_L, d=hinge_pin_dia);
        translate([0,0,4+pin_L]) cylinder(h=2, d1=hinge_pin_dia, d2=hinge_pin_dia-2);
    }
}

module threads(diameter=14, pitch=4, length=10, rez=$fn){
    twist = length/pitch*360;
    depth = pitch * 0.6; 
    linear_extrude(height = length, center = false, convexity = 10, twist = -twist, $fn = rez)
        translate([depth/2, 0, 0]) circle(r = diameter/2 - depth/2);
}