import numpy as np
from PIL import Image, ImageOps
import struct
import math

def create_curved_lithophane(image_path, output_path, width_mm=203.2, resolution=0.2,
                             min_thick=0.6, max_thick=3.0, curve_angle_deg=120):
    """
    Converts an image to a curved lithophane STL.
    
    Args:
        image_path: Path to input image.
        output_path: Path to save STL.
        width_mm: Arc width. 203.2mm is exactly 8 inches.
        resolution: mm per pixel. 0.2 is standard for FDM.
        min_thick: Minimum thickness (lightest parts).
        max_thick: Maximum thickness (darkest parts).
        curve_angle_deg: 120 degrees provides good stability for tall prints.
    """
    
    print(f"--- Processing {image_path} ---")
    print(f"Target Height/Width: ~{width_mm}mm ({width_mm/25.4:.2f} inches)")
    
    # 1. Load and Preprocess Image
    try:
        img = Image.open(image_path).convert('L')  # Convert to grayscale
    except FileNotFoundError:
        print(f"Error: Could not find '{image_path}'. Make sure the file is in the same folder.")
        return

    # Calculate dimensions based on resolution
    # We maintain aspect ratio. If image is square, Height = Width = 8 inches.
    target_width_px = int(width_mm / resolution)
    aspect_ratio = img.height / img.width
    target_height_px = int(target_width_px * aspect_ratio)
    height_mm = width_mm * aspect_ratio
    
    print(f"Resizing image to {target_width_px}x{target_height_px} pixels...")
    img = img.resize((target_width_px, target_height_px), Image.Resampling.LANCZOS)
    
    # Add a border (frame) - 3mm
    border_px = int(3 / resolution)
    
    # Create a new canvas with border
    # 0 is black (thick), so the border will be thick and sturdy
    framed_img = Image.new('L', (target_width_px + 2*border_px, target_height_px + 2*border_px), 0)
    framed_img.paste(img, (border_px, border_px))
    
    # Get pixel array
    pixels = np.array(framed_img)
    pixels = pixels.astype(float) / 255.0  # Normalize 0.0 to 1.0
    
    # Thickness Map:
    # Value 0 (Black) -> max_thick
    # Value 1 (White) -> min_thick
    thickness_map = max_thick - pixels * (max_thick - min_thick)
    
    rows, cols = thickness_map.shape
    
    # 2. Geometry Calculation
    print("Calculating curved geometry...")
    
    # Calculate Radius based on Arc Width and Angle
    curve_angle_rad = np.radians(curve_angle_deg)
    radius = width_mm / curve_angle_rad
    
    # Theta range centered around 0
    thetas = np.linspace(-curve_angle_rad/2, curve_angle_rad/2, cols)
    # Y range (height)
    ys = np.linspace(0, height_mm + (2 * 3), rows)
    
    # Create meshgrid
    theta_grid, y_grid = np.meshgrid(thetas, ys)
    
    # -- Generate Coordinates --
    # Inner Surface (Back) - Smooth
    x_in = radius * np.sin(theta_grid)
    z_in = radius * np.cos(theta_grid)
    y_in = y_grid
    
    # Outer Surface (Front) - Textured
    # R_out = R + thickness
    r_out = radius + thickness_map
    x_out = r_out * np.sin(theta_grid)
    z_out = r_out * np.cos(theta_grid)
    y_out = y_grid
    
    # 3. STL Generation
    print("Generating STL triangles (this may take a moment)...")
    
    header = b'\x00' * 80
    
    n_quads_grid = (rows - 1) * (cols - 1)
    n_quads_tb = (cols - 1)
    n_quads_lr = (rows - 1)
    
    num_triangles = (n_quads_grid * 2 * 2) + (n_quads_tb * 2 * 2) + (n_quads_lr * 2 * 2)
    
    with open(output_path, 'wb') as f:
        f.write(header)
        f.write(struct.pack('<I', num_triangles))
        
        def write_tri(v1, v2, v3):
            f.write(struct.pack('<3f', 0.0, 0.0, 0.0)) # Normal (dummy)
            f.write(struct.pack('<3f', *v1))
            f.write(struct.pack('<3f', *v2))
            f.write(struct.pack('<3f', *v3))
            f.write(b'\x00\x00') # Attribute

        # Prepare vertices for easy indexing
        verts_in = np.dstack((x_in, y_in, z_in))
        verts_out = np.dstack((x_out, y_out, z_out))
        
        # 1. Front Surface (Outer)
        for r in range(rows - 1):
            for c in range(cols - 1):
                v_tl = verts_out[r, c]
                v_tr = verts_out[r, c+1]
                v_bl = verts_out[r+1, c]
                v_br = verts_out[r+1, c+1]
                write_tri(v_tl, v_bl, v_tr)
                write_tri(v_tr, v_bl, v_br)

        # 2. Back Surface (Inner)
        for r in range(rows - 1):
            for c in range(cols - 1):
                v_tl = verts_in[r, c]
                v_tr = verts_in[r, c+1]
                v_bl = verts_in[r+1, c]
                v_br = verts_in[r+1, c+1]
                write_tri(v_tl, v_tr, v_bl)
                write_tri(v_tr, v_br, v_bl)
                
        # 3. Top Edge
        for c in range(cols - 1):
            v_tl = verts_in[0, c]
            v_tr = verts_in[0, c+1]
            v_bl = verts_out[0, c]
            v_br = verts_out[0, c+1]
            write_tri(v_tl, v_tr, v_bl)
            write_tri(v_tr, v_br, v_bl)

        # 4. Bottom Edge
        r_end = rows - 1
        for c in range(cols - 1):
            v_tl = verts_out[r_end, c]
            v_tr = verts_out[r_end, c+1]
            v_bl = verts_in[r_end, c]
            v_br = verts_in[r_end, c+1]
            write_tri(v_tl, v_tr, v_bl)
            write_tri(v_tr, v_br, v_bl)

        # 5. Left Edge
        for r in range(rows - 1):
            v_tl = verts_out[r, 0]
            v_tr = verts_in[r, 0]
            v_bl = verts_out[r+1, 0]
            v_br = verts_in[r+1, 0]
            write_tri(v_tl, v_tr, v_bl)
            write_tri(v_tr, v_br, v_bl)

        # 6. Right Edge
        c_end = cols - 1
        for r in range(rows - 1):
            v_tl = verts_in[r, c_end]
            v_tr = verts_out[r, c_end]
            v_bl = verts_in[r+1, c_end]
            v_br = verts_out[r+1, c_end]
            write_tri(v_tl, v_tr, v_bl)
            write_tri(v_tr, v_br, v_bl)

    print(f"Success! Saved to {output_path}")

# --- Configuration for 8-inch Lithophane ---
image_path = "benmadi.jpg"
output_path = "benmadi_8inch_curved.stl"

# 203.2 mm = 8 inches
# 120 degrees = Increased curve for stability on the Bambu bed
create_curved_lithophane(image_path, output_path, width_mm=203.2, curve_angle_deg=120)
