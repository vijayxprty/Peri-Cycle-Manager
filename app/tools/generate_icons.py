#!/usr/bin/env python3
"""Generate PeriBuds launcher icons (Android + iOS) from the approved rose icon.

Source: the APPROVED polished blooming pink rose on deep rose background.
  ~/workspace/goals/peribuds-period-tracker-app/app-icon-final.webp
  (1600x1600, RGB, no alpha)

Usage: python3 tools/generate_icons.py [path-to-flutter-project]
Defaults to the PeriBuds app dir next to this script's parent.
"""
import json
import os
import sys
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
APP_DIR = os.path.abspath(os.path.join(HERE, ".."))
if len(sys.argv) > 1:
    APP_DIR = os.path.abspath(sys.argv[1])

SRC = os.path.join(APP_DIR, "assets", "appicon-user.png")

DEEP_ROSE = (55, 2, 18)  # sampled corner of the approved icon


def load():
    im = Image.open(SRC).convert("RGB")
    print(f"source {SRC}: {im.size}")
    return im


def save(im, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    im.save(path, "PNG")
    print(f"  {path} {im.size}")


def round_icon(im, size):
    """Circular-masked version for Android ic_launcher_round."""
    im = im.resize((size, size), Image.LANCZOS).convert("RGBA")
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    d.ellipse((0, 0, size, size), fill=255)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(im, (0, 0), mask)
    return out


def android(im):
    res = os.path.join(APP_DIR, "android", "app", "src", "main", "res")
    # Legacy launcher icons (full-bleed image; background already deep rose)
    for name, size in [
        ("mipmap-mdpi", 48),
        ("mipmap-hdpi", 72),
        ("mipmap-xhdpi", 96),
        ("mipmap-xxhdpi", 144),
        ("mipmap-xxxhdpi", 192),
    ]:
        save(im.resize((size, size), Image.LANCZOS),
             os.path.join(res, name, "ic_launcher.png"))
        save(round_icon(im, size),
             os.path.join(res, name, "ic_launcher_round.png"))
    # Adaptive icon: foreground = full artwork scaled to 432 (108dp),
    # background = solid deep rose sampled from the artwork itself.
    fg = im.resize((432, 432), Image.LANCZOS)
    save(fg, os.path.join(res, "mipmap-anydpi-v26", "ic_launcher_foreground.png"))
    bg = Image.new("RGB", (432, 432), DEEP_ROSE)
    save(bg, os.path.join(res, "mipmap-anydpi-v26", "ic_launcher_background.png"))
    # Adaptive round foreground is the same file; Android Studio template
    # expects ic_launcher.xml referencing these two drawables — write it.
    xml_dir = os.path.join(res, "mipmap-anydpi-v26")
    with open(os.path.join(xml_dir, "ic_launcher.xml"), "w") as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n'
                '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
                '    <background android:drawable="@mipmap/ic_launcher_background"/>\n'
                '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
                '</adaptive-icon>\n')
    print("  wrote ic_launcher.xml (adaptive)")


def ios(im):
    appicon = os.path.join(
        APP_DIR, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
    # (size, scale, idiom, filename)
    specs = [
        (20, 2, "iphone", "Icon-App-20x20@2x.png"),
        (20, 3, "iphone", "Icon-App-20x20@3x.png"),
        (29, 2, "iphone", "Icon-App-29x29@2x.png"),
        (29, 3, "iphone", "Icon-App-29x29@3x.png"),
        (40, 2, "iphone", "Icon-App-40x40@2x.png"),
        (40, 3, "iphone", "Icon-App-40x40@3x.png"),
        (60, 2, "iphone", "Icon-App-60x60@2x.png"),
        (60, 3, "iphone", "Icon-App-60x60@3x.png"),
        (20, 1, "ipad", "Icon-App-20x20@1x.png"),
        (20, 2, "ipad", "Icon-App-20x20@2x.png"),
        (29, 1, "ipad", "Icon-App-29x29@1x.png"),
        (29, 2, "ipad", "Icon-App-29x29@2x.png"),
        (40, 1, "ipad", "Icon-App-40x40@1x.png"),
        (40, 2, "ipad", "Icon-App-40x40@2x.png"),
        (76, 1, "ipad", "Icon-App-76x76@1x.png"),
        (76, 2, "ipad", "Icon-App-76x76@2x.png"),
        (83.5, 2, "ipad", "Icon-App-83.5x83.5@2x.png"),
        (1024, 1, "ios-marketing", "Icon-App-1024x1024@1x.png"),
    ]
    images = []
    for size, scale, idiom, fname in specs:
        px = int(size * scale)
        save(im.resize((px, px), Image.LANCZOS), os.path.join(appicon, fname))
        images.append({
            "size": f"{size:g}x{size:g}",
            "idiom": idiom,
            "filename": fname,
            "scale": f"{scale:g}x",
        })
    contents = {"images": images, "info": {"version": 1, "author": "xcode"}}
    with open(os.path.join(appicon, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=2)
    print("  wrote Contents.json")


def main():
    im = load()
    android(im)
    ios(im)
    print("DONE — launcher icons generated from the approved rose icon.")


if __name__ == "__main__":
    main()
