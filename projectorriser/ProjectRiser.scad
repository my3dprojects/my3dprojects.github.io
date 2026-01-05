// --- Projector Tilt Riser (FINAL FIX) ---

/* [Export Selection] */
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

/* [Hidden] */
$fn = 60; 
w = width_inch * 25.4;
d = depth_inch * 25.4;

// --- Main Logic ---
if (print_selection == 0) {
    color("Teal") bottom_plate(); 
    
    // --- ASSEMBLY LOGIC ---
    // With both hinges now having identical "flat bottoms" (D-shape),
    // this rotation will result in perfect visual alignment.
    translate([0, d, plate_thickness]) 
        rotate([-10, 0, 0]) 
        translate([0, -d, -plate_thickness]) 
        union() {
            color("CornflowerBlue") top_plate(); 
            translate([w/2, -tab_extension, plate_thickness + 50]) 
                rotate([180, 0, 0]) 
                color("Orange") printable_screw(); 
        }
        
    translate([-2, d, plate_thickness]) rotate([0,90,0]) color("Orange") hinge_pin_printable();
    translate([w+2, d, plate_thickness]) rotate([0,-90,0]) color("Orange") hinge_pin_printable();

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
                
                translate([w/3 + hinge_clearance/2, 0, plate_thickness]) 
                    rotate([0,90,0]) 
                    difference() {
                        cylinder(h=knuckle_len, r=hinge_radius);
                        translate([0,0,-1]) cylinder(h=w, d=hinge_pin_dia + 0.6);
                    }
                    
                translate([w/3 + hinge_clearance/2, -hinge_radius, 0]) 
                    cube([knuckle_len, hinge_radius, plate_thickness]);
            }
        }

        // --- FLUSH CUT (TOP) ---
        // Stops the cut 20mm before the back to preserve hinge height
        translate([-50, 10, plate_thickness]) cube([1000, d - 20, 50]);

        // --- FLOOR CUT (BOTTOM) ---
        // Cuts off the hinge "belly" that protrudes below Z=0
        // This ensures the bottom of the hinge is flush with the bottom of the plate.
        translate([-50, -50, -50]) cube([2000, 2000, 50]);
    }
}

module bottom_plate() {
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
            translate([0, d, 0]) {
                 knuckle_len = w/3 - hinge_clearance;
                 translate([0, 0, plate_thickness]) rotate([0,90,0]) difference() {
                        cylinder(h=knuckle_len, r=hinge_radius);
                        translate([0,0,-1]) cylinder(h=w, d=hinge_pin_dia + 0.6);
                    }
                 translate([w - knuckle_len, 0, plate_thickness]) rotate([0,90,0]) difference() {
                        cylinder(h=knuckle_len, r=hinge_radius);
                        translate([0,0,-1]) cylinder(h=w, d=hinge_pin_dia + 0.6);
                    }
                 translate([0, -hinge_radius, 0]) cube([knuckle_len, hinge_radius, plate_thickness]);
                 translate([w-knuckle_len, -hinge_radius, 0]) cube([knuckle_len, hinge_radius, plate_thickness]);
            }
        }
        // Bottom Plate Floor Cut
        translate([-50, -50, -50]) cube([1000, 1000, 50]);
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