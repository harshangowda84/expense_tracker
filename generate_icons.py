#!/usr/bin/env python3
"""
Script to generate app icons from source image for Flutter project
"""

from PIL import Image, ImageOps
import os

def create_icon(source_path, output_path, size, crop_to_square=True):
    """Create an icon of specified size from source image"""
    try:
        # Open the source image
        with Image.open(source_path) as img:
            # Convert to RGBA if not already
            if img.mode != 'RGBA':
                img = img.convert('RGBA')
            
            if crop_to_square:
                # Crop to square (center crop)
                width, height = img.size
                min_dimension = min(width, height)
                left = (width - min_dimension) // 2
                top = (height - min_dimension) // 2
                right = left + min_dimension
                bottom = top + min_dimension
                img = img.crop((left, top, right, bottom))
            
            # Resize to target size with high quality, filling entire space
            img = img.resize((size, size), Image.Resampling.LANCZOS)
            
            # For iOS icons, we need to keep some padding for Apple's guidelines
            # For Android and Web, we can fill the entire space
            if 'ios' in output_path.lower() or 'Icon-App' in output_path:
                # iOS icons: keep small padding (about 5% on each side)
                padding = int(size * 0.05)
                if padding > 0:
                    # Create a new image with padding
                    padded_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
                    content_size = size - (2 * padding)
                    resized_content = img.resize((content_size, content_size), Image.Resampling.LANCZOS)
                    padded_img.paste(resized_content, (padding, padding), resized_content)
                    img = padded_img
            
            # Ensure output directory exists
            os.makedirs(os.path.dirname(output_path), exist_ok=True)
            
            # Save the image
            img.save(output_path, 'PNG', optimize=True)
            print(f"Created: {output_path} ({size}x{size})")
            
    except Exception as e:
        print(f"Error creating {output_path}: {e}")

def main():
    source_image = "assets/app_logo_source.png"
    
    if not os.path.exists(source_image):
        print(f"Source image not found: {source_image}")
        return
    
    # Android icons (mipmap folders)
    android_icons = [
        ("android/app/src/main/res/mipmap-mdpi/ic_launcher.png", 48),
        ("android/app/src/main/res/mipmap-hdpi/ic_launcher.png", 72),
        ("android/app/src/main/res/mipmap-xhdpi/ic_launcher.png", 96),
        ("android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png", 144),
        ("android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png", 192),
    ]
    
    # iOS icons
    ios_icons = [
        ("ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png", 20),
        ("ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png", 40),
        ("ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png", 60),
        ("ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png", 29),
        ("ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png", 58),
        ("ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png", 87),
        ("ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png", 40),
        ("ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png", 80),
        ("ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png", 120),
        ("ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png", 120),
        ("ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png", 180),
        ("ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png", 76),
        ("ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png", 152),
        ("ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png", 167),
        ("ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png", 1024),
    ]
    
    # Web icons
    web_icons = [
        ("web/icons/Icon-192.png", 192),
        ("web/icons/Icon-512.png", 512),
        ("web/icons/Icon-maskable-192.png", 192),
        ("web/icons/Icon-maskable-512.png", 512),
        ("web/favicon.png", 32),
    ]
    
    # Create all icons
    all_icons = android_icons + ios_icons + web_icons
    
    print(f"Generating {len(all_icons)} icons from {source_image}...")
    
    for output_path, size in all_icons:
        create_icon(source_image, output_path, size)
    
    print("\nIcon generation complete!")
    print("\nNext steps:")
    print("1. For iOS: Run 'flutter build ios' to refresh icon cache")
    print("2. For Android: Clean and rebuild the project")
    print("3. For Web: Icons will be updated automatically")

if __name__ == "__main__":
    main()