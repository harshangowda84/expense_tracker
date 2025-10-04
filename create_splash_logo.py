#!/usr/bin/env python3

import os
from PIL import Image, ImageDraw

def create_splash_logo():
    """Create a splash screen version of the logo with proper background"""
    
    # Load the source logo
    source_path = "assets/app_logo_source.png"
    if not os.path.exists(source_path):
        print(f"Source logo not found at {source_path}")
        return
    
    # Load the source image
    source = Image.open(source_path).convert("RGBA")
    
    # Create splash screen logo for Android (larger, centered)
    splash_size = 512
    splash_bg = Image.new("RGBA", (splash_size, splash_size), (0, 0, 0, 0))  # Transparent background
    
    # Calculate size to maintain aspect ratio but be prominent
    logo_size = int(splash_size * 0.4)  # 40% of splash screen
    source_resized = source.resize((logo_size, logo_size), Image.Resampling.LANCZOS)
    
    # Center the logo
    x = (splash_size - logo_size) // 2
    y = (splash_size - logo_size) // 2
    
    splash_bg.paste(source_resized, (x, y), source_resized)
    
    # Save for Android
    android_splash_dir = "android/app/src/main/res/mipmap-xxxhdpi"
    os.makedirs(android_splash_dir, exist_ok=True)
    splash_bg.save(f"{android_splash_dir}/launch_image.png", "PNG")
    print(f"Created Android splash logo: {android_splash_dir}/launch_image.png")
    
    # Also create for other densities
    densities = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72, 
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192
    }
    
    for density, base_size in densities.items():
        density_dir = f"android/app/src/main/res/{density}"
        os.makedirs(density_dir, exist_ok=True)
        
        # Scale splash logo proportionally
        splash_logo_size = int(base_size * 2.5)  # Make splash logo larger than app icon
        density_splash = Image.new("RGBA", (splash_logo_size, splash_logo_size), (0, 0, 0, 0))
        
        # Resize and center logo
        logo_size_density = int(splash_logo_size * 0.4)
        source_density = source.resize((logo_size_density, logo_size_density), Image.Resampling.LANCZOS)
        
        x = (splash_logo_size - logo_size_density) // 2
        y = (splash_logo_size - logo_size_density) // 2
        
        density_splash.paste(source_density, (x, y), source_density)
        density_splash.save(f"{density_dir}/launch_image.png", "PNG")
    
    print("Created splash logos for all Android densities")
    
    # Create iOS launch image
    ios_dir = "ios/Runner"
    if os.path.exists(ios_dir):
        # Create larger version for iOS
        ios_splash = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
        logo_size_ios = int(512 * 0.3)  # Slightly smaller for iOS
        source_ios = source.resize((logo_size_ios, logo_size_ios), Image.Resampling.LANCZOS)
        
        x = (512 - logo_size_ios) // 2
        y = (512 - logo_size_ios) // 2
        
        ios_splash.paste(source_ios, (x, y), source_ios)
        ios_splash.save(f"{ios_dir}/LaunchImage.png", "PNG")
        print(f"Created iOS splash logo: {ios_dir}/LaunchImage.png")

if __name__ == "__main__":
    create_splash_logo()