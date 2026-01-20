// Suggestions to Save PLA on Main Holder (Bambu P1S Optimized)

// --- PARAMETERS ---

// Which part to display?
// 0 = Assembly View
// 1 = Base (Print this first)
// 2 = Main Holder Body (Print this second)
part_to_print = 2;

// SAVING MODE: Remove the vanity skirt?
// true = Holds utensils but you can see the spinning base (SAVES ~50g + SUPPORTS)
// false = Covers the base, but requires supports to print the bottom cavity
no_skirt_mode = false; 

inches_to_mm = 25.4;
width_inch = 9;
height_inch = 7;

// General Geometry
diameter = width_inch * inches_to_mm;
total_height = height_inch * inches_to_mm;
wall_thickness = 1.6; // 4 walls (0.4 nozzle)

// Base Mechanism Settings
base_puck_height = 15; 
spindle_diam = 18; 
spindle_height = total_height * 0.70; 
tolerance = 1.0; 
$fn = 100;

module assembly() {
    color("gray") LazySusanBase();
    color("burlywood") 
    translate([0,0, base_puck_height + 2]) 
    UtensilHolder();
}

module LazySusanBase() {
    union() {
        cylinder(h=base_puck_height, d=diameter - 5);
        cylinder(h=spindle_height, d=spindle_diam);
        translate([0,0,spindle_height]) sphere(d=spindle_diam);
    }
}

module UtensilHolder() {
    // Logic: If no_skirt_mode is ON, we chop off the bottom "skirt"
    // and lower the whole object so the internal floor touches Z=0.
    
    skirt_offset = no_skirt_mode ? 0 : (base_puck_height + 2);
    internal_floor_thickness = 2.0; 
    
    // The "Z" where the actual holding area starts
    floor_z = skirt_offset + internal_floor_thickness;

    difference() {
        
        // --- POSITIVE GEOMETRY ---
        union() {
            // 1. Main Outer Shell
            difference() {
                // If no skirt, we start the cylinder higher up (effectively shorter total print)
                translate([0,0, no_skirt_mode ? base_puck_height + 2 : 0])
                cylinder(h=total_height - (no_skirt_mode ? base_puck_height + 2 : 0), d=diameter);
                
                // Hollow out the bucket
                translate([0,0, floor_z])
                cylinder(h=total_height + 1, d=diameter - (wall_thickness*2));
                
                // Cut Down Pies (Existing Logic)
                for (a = [60, 180, 300]) {
                    rotate([0,0,a])
                    translate([0,0, total_height * 0.5]) 
                    linear_extrude(height = total_height)
                    polygon(points=[[0,0], [diameter, 0], [diameter * cos(60), diameter * sin(60)]]);
                }

                // --- BAMBU OPTIMIZATION: Diamond Windows ---
                // Replaces Pill shapes. 45-degree angles need ZERO support.
                for (a = [0, 120, 240]) { 
                     rotate([0,0,a + 30]) 
                     translate([diameter/2, 0, total_height * 0.75])
                     rotate([0, 45, 0]) // Rotate cube to make a diamond
                     cube([35, 60, 35], center=true);
                }
            }
            
            // 2. Center Hub (Thinned)
            translate([0,0, no_skirt_mode ? base_puck_height + 2 : 0])
            cylinder(h=total_height - (no_skirt_mode ? base_puck_height + 2 : 0), d=spindle_diam + 6); 
            
            // 3. Radial Dividers (Skeletonized)
            intersection() {
                translate([0,0, floor_z])
                cylinder(h=total_height, d=diameter - wall_thickness);
                
                translate([0,0,total_height/2])
                for(r = [0 : 60 : 360]) {
                    rotate([0,0,r])
                    difference() {
                        cube([diameter, wall_thickness, total_height], center=true);
                        // Cut Window in Divider
                        translate([diameter/3.5, 0, 15]) 
                        cube([diameter/3, wall_thickness + 5, total_height/1.5], center=true);
                    }
                }
            }
        }
        
        // --- NEGATIVE GEOMETRY ---
        
        // 1. Spindle Hole
        translate([0,0, -1])
        cylinder(h=spindle_height + 5, d=spindle_diam + tolerance);
        
        // 2. Base Puck Clearance (Only if skirt is enabled)
        if (!no_skirt_mode) {
            translate([0,0, -1])
            cylinder(h=base_puck_height + 2, d=diameter + 2); 
        }
    }
}

if (part_to_print == 0) assembly();
else if (part_to_print == 1) LazySusanBase();
else if (part_to_print == 2) UtensilHolder();