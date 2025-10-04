#!/usr/bin/env python3

import os
from PIL import Image, ImageDraw

def create_full_logo_splash():
    """Create a splash screen version of the logo that fills space without white borders"""
    
    # Load the source logo
    source_path = "assets/app_logo_source.png"
    if not os.path.exists(source_path):
        print(f"Source logo not found at {source_path}")
        return
    
    # Load the source image
    source = Image.open(source_path).convert("RGBA")
    
    # Get the bounding box of non-transparent pixels
    bbox = source.getbbox()
    if bbox:
        # Crop to remove any transparent padding
        source_cropped = source.crop(bbox)
    else:
        source_cropped = source
    
    # Create splash screen logo for Android densities
    densities = {
        "mipmap-mdpi": 120,
        "mipmap-hdpi": 180, 
        "mipmap-xhdpi": 240,
        "mipmap-xxhdpi": 360,
        "mipmap-xxxhdpi": 480
    }
    
    for density, size in densities.items():
        density_dir = f"android/app/src/main/res/{density}"
        os.makedirs(density_dir, exist_ok=True)
        
        # Create a logo that fills most of the space
        logo_resized = source_cropped.resize((size, size), Image.Resampling.LANCZOS)
        
        # Save directly without any additional padding
        logo_resized.save(f"{density_dir}/launch_image.png", "PNG")
        print(f"Created full splash logo: {density_dir}/launch_image.png")
    
    # Create iOS launch image without padding
    ios_dir = "ios/Runner"
    if os.path.exists(ios_dir):
        ios_size = 512
        ios_logo = source_cropped.resize((ios_size, ios_size), Image.Resampling.LANCZOS)
        ios_logo.save(f"{ios_dir}/LaunchImage.png", "PNG")
        print(f"Created iOS full splash logo: {ios_dir}/LaunchImage.png")

if __name__ == "__main__":
    create_full_logo_splash()