// --- PARAMETERS ---

// Which part to display?
// 0 = Assembly View (For looking only, do not print)
// 1 = Base (Print this first)
// 2 = Main Holder Body (Print this second)
part_to_print = 2;

// Dimensions (in Inches, converted to mm)
inches_to_mm = 25.4;
width_inch = 9;
height_inch = 5;

// General Geometry
diameter = width_inch * inches_to_mm;
total_height = height_inch * inches_to_mm;
wall_thickness = 2.4; 

// Base Mechanism Settings
base_puck_height = 15; 
spindle_diam = 18; // Slightly thicker for stability
spindle_height = total_height * 0.70; // Spindle goes 70% up the body
tolerance = 1.0; // Clearance for rotation

// Smoothing
$fn = 150;

// --- LOGIC ---

module assembly() {
    color("gray") 
    LazySusanBase();
    
    color("burlywood") 
    // Lifted 2mm to simulate the gap needed for rotation
    translate([0,0, base_puck_height + 2]) 
    UtensilHolder();
}

module LazySusanBase() {
    union() {
        // 1. The Base Plate (Solid)
        cylinder(h=base_puck_height, d=diameter - 5);
        
        // 2. The Spindle (The long rod)
        cylinder(h=spindle_height, d=spindle_diam);
        
        // 3. Rounded Cap (Smoother insertion)
        translate([0,0,spindle_height])
        sphere(d=spindle_diam);
        
        // 4. Fillet at the bottom of spindle for strength
        difference() {
            cylinder(h=10, d=spindle_diam + 20);
            translate([0,0,-1])
            difference() {
                cylinder(h=12, d=spindle_diam + 25);
                cylinder(h=12, d=spindle_diam);
            }
        }
    }
}

module UtensilHolder() {
    // --- CALCULATIONS FOR SOLID BOTTOM ---
    base_cutout_height = base_puck_height + 2; 
    solid_floor_thickness = 3; 
    internal_floor_start = base_cutout_height + solid_floor_thickness; 

    difference() {
        
        // --- POSITIVE GEOMETRY ---
        union() {
            // 1. Main Outer Shell (With Cutouts)
            difference() {
                cylinder(h=total_height, d=diameter);
                
                // Hollow out the main bucket
                translate([0,0, internal_floor_start])
                cylinder(h=total_height + 1, d=diameter - (wall_thickness*2));
                
                // Chamfer top (Full height parts only)
                translate([0,0,total_height])
                rotate_extrude()
                translate([diameter/2, 0, 0])
                circle(r=2);
                
                // --- NEW: CUT DOWN EVERY OTHER PIE ---
                // We remove the top 50% of the wall for alternating sectors.
                // We use a polygon wedge extruded upwards.
                for (a = [60, 180, 300]) {
                    rotate([0,0,a])
                    translate([0,0, total_height * 0.5]) // Start at 50% height
                    linear_extrude(height = (total_height * 0.5) + 2)
                    polygon(points=[
                        [0,0], 
                        [diameter, 0], // Extend far beyond radius
                        [diameter * cos(60), diameter * sin(60)] // 60 degree wedge
                    ]);
                }
            }
            
            // 2. Center Hub (Remains Full Height)
            cylinder(h=total_height, d=spindle_diam + 12); 
            
            // 3. Inner Divider Tube (Remains Full Height)
            difference() {
                cylinder(h=total_height, d=(diameter/3) + wall_thickness);
                translate([0,0, internal_floor_start])
                cylinder(h=total_height, d=(diameter/3));
            }
            
            // 4. Radial Dividers (Remain Full Height)
            intersection() {
                translate([0,0, internal_floor_start])
                cylinder(h=total_height, d=diameter - wall_thickness);
                
                translate([0,0,total_height/2])
                for(r = [0 : 60 : 360]) {
                    rotate([0,0,r])
                    cube([diameter, wall_thickness, total_height], center=true);
                }
            }
        }
        
        // --- NEGATIVE GEOMETRY ---
        
        // 1. Spindle Hole
        translate([0,0, -1])
        cylinder(h=spindle_height + 5, d=spindle_diam + tolerance);
        
        // 2. Base Puck Clearance
        translate([0,0, -1])
        cylinder(h=base_cutout_height, d=diameter + 2); 
    }
}

// --- RENDERING SWITCH ---

if (part_to_print == 0) {
    assembly();
} else if (part_to_print == 1) {
    LazySusanBase();
} else if (part_to_print == 2) {
    UtensilHolder();
}