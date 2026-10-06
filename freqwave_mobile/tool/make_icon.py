"""Builds the Cocord launcher icons from tool/icon_source.png (pip install pillow).

Run from the project root:  python tool/make_icon.py
The artwork already has its own rounded-square background, so it is used as a
regular (non-adaptive) icon with the white corners made transparent.
"""
from PIL import Image, ImageDraw, ImageFilter

RES = "android/app/src/main/res"
SRC = "tool/icon_source.png"
LEGACY = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}


def cut_corners(img):
    """Make the white area outside the rounded square transparent."""
    rgba = img.convert("RGBA")
    w, h = rgba.size
    marker = (255, 0, 255, 0)
    for corner in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]:
        ImageDraw.floodfill(rgba, corner, marker, thresh=40)
    # soften the cut edge a little
    alpha = rgba.getchannel("A").filter(ImageFilter.GaussianBlur(1.2))
    rgba.putalpha(alpha)
    return rgba


def main():
    art = cut_corners(Image.open(SRC))
    for dens, px in LEGACY.items():
        art.resize((px, px), Image.LANCZOS).save(f"{RES}/mipmap-{dens}/ic_launcher.png")
    print("icons written")


if __name__ == "__main__":
    main()
