#!/usr/bin/env python3
"""Convert app logo PNG to Windows ICO format"""

from PIL import Image
import os

# Input and output paths
input_png = "assets/app_logo_source.png"
output_ico = "windows/runner/resources/app_icon.ico"

# Open the PNG image
img = Image.open(input_png)

# Resize to 256x256 (standard Windows icon size)
icon_size = (256, 256)
resized = img.resize(icon_size, Image.Resampling.LANCZOS)

# Convert to RGB for ICO format
if resized.mode == 'RGBA':
    # Create a white background
    background = Image.new('RGB', resized.size, (255, 255, 255))
    background.paste(resized, mask=resized.split()[3])  # Use alpha channel as mask
    resized = background
else:
    resized = resized.convert('RGB')

# Save as ICO file
resized.save(output_ico, format='ICO')

print(f"✓ Successfully converted {input_png} to {output_ico}")
print(f"  Icon size: 256x256")
