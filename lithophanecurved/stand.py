import numpy as np
import struct
import math

def create_knot_friendly_tower(output_path, litho_width_mm=203.2, curve_angle_deg=120,
                               tower_height=150.0, tower_radius=25.0):
    print(f"--- Generating Knot-Friendly Tower ---")

    # --- Configuration ---
    curve_angle_rad = np.radians(curve_angle_deg)
    r_litho = litho_width_mm / curve_angle_rad
    
    slot_width = 3.8
    wall_height = 12.0
    base_thickness = 3.0
    
    # Hole Config
    hole_bottom_lip = 3.0  # Height of the solid floor ring (traps the wire)
    hole_h = 9.0           # Height of the hole opening (Total hole is 3mm to 12mm)
    top_slot_h = 10.0
    top_rim_h = 4.0
    
    # Hole Width: 35 degrees = ~15mm wide (fits USB head if squeezed, definitely catches knot)
    hole_width_deg = 35.0
    
    # Radii
    r_floor_start = tower_radius - 2.0
    r_slot_in = r_litho - (slot_width / 2)
    r_slot_out = r_litho + (slot_width / 2)
    r_outer_wall = r_slot_out + 2.0
    r_tower_out = tower_radius
    r_tower_in = tower_radius - 2.5

    triangles = []

    # --- Helpers ---
    def add_quad(p_bl, p_br, p_tr, p_tl):
        triangles.append((p_bl, p_br, p_tr))
        triangles.append((p_bl, p_tr, p_tl))

    def polar_to_cart(r, theta, z):
        return (r * np.sin(theta), r * np.cos(theta), z)

    # --- GEOMETRY BUILDER ---
    def add_solid_arc_tube(r_inner, r_outer, z_start, z_end, start_angle, end_angle):
        steps = 60
        thetas = np.linspace(start_angle, end_angle, steps)
        for i in range(steps - 1):
            t1 = thetas[i]
            t2 = thetas[i+1]
            add_quad(polar_to_cart(r_outer, t1, z_start), polar_to_cart(r_outer, t2, z_start),
                     polar_to_cart(r_outer, t2, z_end), polar_to_cart(r_outer, t1, z_end))
            add_quad(polar_to_cart(r_inner, t2, z_start), polar_to_cart(r_inner, t1, z_start),
                     polar_to_cart(r_inner, t1, z_end), polar_to_cart(r_inner, t2, z_end))
            add_quad(polar_to_cart(r_inner, t1, z_end), polar_to_cart(r_outer, t1, z_end),
                     polar_to_cart(r_outer, t2, z_end), polar_to_cart(r_inner, t2, z_end))
            add_quad(polar_to_cart(r_inner, t2, z_start), polar_to_cart(r_outer, t2, z_start),
                     polar_to_cart(r_outer, t1, z_start), polar_to_cart(r_inner, t1, z_start))
        
        # End Caps
        t_s, t_e = thetas[0], thetas[-1]
        add_quad(polar_to_cart(r_inner, t_s, z_start), polar_to_cart(r_inner, t_s, z_end),
                 polar_to_cart(r_outer, t_s, z_end), polar_to_cart(r_outer, t_s, z_start))
        add_quad(polar_to_cart(r_inner, t_e, z_start), polar_to_cart(r_outer, t_e, z_start),
                 polar_to_cart(r_outer, t_e, z_end), polar_to_cart(r_inner, t_e, z_end))

    # --- ANGLES ---
    half_hole = np.radians(hole_width_deg / 2)
    start_solid = np.pi + half_hole
    end_solid = start_solid + (2*np.pi - 2*half_hole)

    # ==========================================
    # TOWER CONSTRUCTION (5 STACKS)
    # ==========================================
    
    # 1. BOTTOM LIP (Solid Ring) - TRAPS THE WIRE
    # Z: 0 to 3mm
    print("Generating Bottom Lip (Wire Trap)...")
    add_solid_arc_tube(r_tower_in, r_tower_out, 0, hole_bottom_lip, 0, 2*np.pi)

    # 2. THE KNOT HOLE (Gap at Back)
    # Z: 3mm to 12mm
    print("Generating Knot Hole Window...")
    z_hole_top = hole_bottom_lip + hole_h
    add_solid_arc_tube(r_tower_in, r_tower_out, hole_bottom_lip, z_hole_top, start_solid, end_solid)

    # 3. MAIN TRUNK (Solid Cylinder)
    # Z: 12mm to Top Slot
    z_slot_bottom = tower_height - top_rim_h - top_slot_h
    print(f"Generating Main Trunk...")
    add_solid_arc_tube(r_tower_in, r_tower_out, z_hole_top, z_slot_bottom, 0, 2*np.pi)

    # 4. TOP ENTRY SLOT (Gap at Back)
    z_slot_top = tower_height - top_rim_h
    print("Generating Top Entry Slot...")
    add_solid_arc_tube(r_tower_in, r_tower_out, z_slot_bottom, z_slot_top, start_solid, end_solid)

    # 5. TOP RIM (Solid Ring)
    print("Generating Top Rim...")
    add_solid_arc_tube(r_tower_in, r_tower_out, z_slot_top, tower_height, 0, 2*np.pi)


    # ==========================================
    # BASE CONSTRUCTION
    # ==========================================
    print("Generating Base...")
    h_floor = base_thickness
    h_wall = base_thickness + wall_height
    r_wall_in_start = r_slot_in - 2.0
    
    profile = [
        (r_floor_start, 0), (r_outer_wall, 0), (r_outer_wall, h_wall),
        (r_slot_out, h_wall), (r_slot_out, h_floor), (r_slot_in, h_floor),
        (r_slot_in, h_wall), (r_wall_in_start, h_wall), (r_wall_in_start, h_floor),
        (r_floor_start, h_floor)
    ]
    b_steps = 200
    b_thetas = np.linspace(-curve_angle_rad/2, curve_angle_rad/2, b_steps)
    
    for i in range(b_steps - 1):
        t1 = b_thetas[i]
        t2 = b_thetas[i+1]
        for p_idx in range(len(profile)):
            p_curr = profile[p_idx]
            p_next = profile[(p_idx + 1) % len(profile)]
            add_quad(polar_to_cart(p_curr[0], t1, p_curr[1]), polar_to_cart(p_curr[0], t2, p_curr[1]),
                     polar_to_cart(p_next[0], t2, p_next[1]), polar_to_cart(p_next[0], t1, p_next[1]))

    t_start, t_end = b_thetas[0], b_thetas[-1]
    pt0 = polar_to_cart(profile[0][0], t_start, profile[0][1])
    pt0_end = polar_to_cart(profile[0][0], t_end, profile[0][1])
    for p_idx in range(1, len(profile) - 1):
        triangles.append((pt0, polar_to_cart(profile[p_idx+1][0], t_start, profile[p_idx+1][1]),
                          polar_to_cart(profile[p_idx][0], t_start, profile[p_idx][1])))
        triangles.append((pt0_end, polar_to_cart(profile[p_idx][0], t_end, profile[p_idx][1]),
                          polar_to_cart(profile[p_idx+1][0], t_end, profile[p_idx+1][1])))

    # Write File
    with open(output_path, 'wb') as f:
        f.write(b'\x00' * 80)
        f.write(struct.pack('<I', len(triangles)))
        for tri in triangles:
            f.write(struct.pack('<3f', 0.0, 0.0, 0.0))
            for v in tri:
                f.write(struct.pack('<3f', *v))
            f.write(b'\x00\x00')
    print("Success! Knot-Friendly Tower generated.")

# Run
create_knot_friendly_tower("litho_tower_knot_friendly.stl", litho_width_mm=203.2, curve_angle_deg=120)
