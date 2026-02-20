import bpy
import os

frames_dir = os.path.expanduser("~/Desktop/sprite_frames/")
os.makedirs(frames_dir, exist_ok=True)
cols, rows = 4, 2
fw, fh, fn = 192, 64, 8

scene = bpy.context.scene

# Update render resolution to 192x64
scene.render.resolution_x = fw
scene.render.resolution_y = fh

# Widen the ortho scale a bit to fit the wide model
cam = bpy.data.objects["Camera"]
cam.data.ortho_scale = 2.8  # wider to fit 192px wide frame

# 8 frames evenly spaced across 120 frame animation
num_frames = fn
frame_indices = [int(i * 120 / num_frames) for i in range(num_frames)]
print("Rendering frames:", frame_indices)

for i, frame in enumerate(frame_indices):
    scene.frame_set(frame)
    filepath = os.path.join(frames_dir, f"frame_{i:02d}.png")
    scene.render.filepath = filepath
    bpy.ops.render.render(write_still=True)
    print(f"Rendered frame {i} (timeline frame {frame}) -> {filepath}")

print(f"All {fn} frames rendered!")

# Create blank RGBA sprite sheet image in Blender
sheet_name = "SpriteSheet"
if sheet_name in bpy.data.images:
    bpy.data.images.remove(bpy.data.images[sheet_name])

sheet = bpy.data.images.new(sheet_name, width=cols * fw, height=rows * fh, alpha=True)
sheet.pixels[:] = [0.0] * (cols * fw * rows * fh * 4)

for i in range(fn):
    path = os.path.join(frames_dir, f"frame_{i:02d}.png")
    img = bpy.data.images.load(path)
    img.pixels  # force load
    
    col = i % cols
    row = i // cols
    # Blender image origin is bottom-left, so flip row
    flipped_row = (rows - 1) - row
    
    px = list(img.pixels)
    sheet_px = list(sheet.pixels)
    
    for y in range(fh):
        for x in range(fw):
            src_idx = (y * fw + x) * 4
            dst_x = col * fw + x
            dst_y = flipped_row * fh + y
            dst_idx = (dst_y * cols * fw + dst_x) * 4
            sheet_px[dst_idx:dst_idx+4] = px[src_idx:src_idx+4]
    
    sheet.pixels[:] = sheet_px
    bpy.data.images.remove(img)
    print(f"Composited frame {i}")

# Save the sprite sheet
sheet.filepath_raw = os.path.expanduser("~/Desktop/spritesheet.png")
sheet.file_format = 'PNG'
sheet.save()
print("Sprite sheet saved to ~/Desktop/spritesheet.png")
