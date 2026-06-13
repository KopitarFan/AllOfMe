#!/usr/bin/env python3
"""Generate release-ready All Of Me icon assets.

The checked-in source icon is resized with macOS `sips`, so a fresh
Flutter/Xcode machine can regenerate assets without installing Pillow or
ImageMagick.
"""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE_ICON = ROOT / "assets" / "brand" / "allofme-icon.png"
APP_ICON_DIR = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
LAUNCH_DIR = ROOT / "ios" / "Runner" / "Assets.xcassets" / "LaunchImage.imageset"
WEB_DIR = ROOT / "web"
ANDROID_RES_DIR = ROOT / "android" / "app" / "src" / "main" / "res"

ICON_SIZES = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}

LAUNCH_SIZES = {
    "LaunchImage.png": 84,
    "LaunchImage@2x.png": 168,
    "LaunchImage@3x.png": 252,
}

WEB_SIZES = {
    "favicon.png": 32,
    "icons/Icon-192.png": 192,
    "icons/Icon-512.png": 512,
    "icons/Icon-maskable-192.png": 192,
    "icons/Icon-maskable-512.png": 512,
}

ANDROID_SIZES = {
    "mipmap-mdpi/ic_launcher.png": 48,
    "mipmap-hdpi/ic_launcher.png": 72,
    "mipmap-xhdpi/ic_launcher.png": 96,
    "mipmap-xxhdpi/ic_launcher.png": 144,
    "mipmap-xxxhdpi/ic_launcher.png": 192,
}


def resize_source_icon(path: Path, size: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(SOURCE_ICON, path)
    subprocess.run(
        ["sips", "-z", str(size), str(size), str(path)],
        check=True,
        stdout=subprocess.DEVNULL,
    )


def main() -> None:
    if not SOURCE_ICON.exists():
        raise SystemExit(f"Missing source icon: {SOURCE_ICON}")

    for filename, size in ICON_SIZES.items():
        resize_source_icon(APP_ICON_DIR / filename, size)

    for filename, size in LAUNCH_SIZES.items():
        resize_source_icon(LAUNCH_DIR / filename, size)

    for filename, size in WEB_SIZES.items():
        resize_source_icon(WEB_DIR / filename, size)

    for filename, size in ANDROID_SIZES.items():
        resize_source_icon(ANDROID_RES_DIR / filename, size)


if __name__ == "__main__":
    main()
