"""Generates the Cocord launcher icons (needs: pip install pillow).

Run from the project root:  python tool/make_icon.py
Design: white speech bubble holding three voice bars, on a blue->teal gradient.
"""
from PIL import Image, ImageDraw

RES = "android/app/src/main/res"
TOP = (37, 99, 235)      # blue
BOTTOM = (6, 182, 212)   # teal
SS = 4                   # supersampling factor


def gradient(size):
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * (size - 1))
            px[x, y] = tuple(int(TOP[i] + (BOTTOM[i] - TOP[i]) * t) for i in range(3))
    return img


def bubble(size, scale):
    """Transparent layer with the white bubble + bars, centered, `scale` of size."""
    s = size * SS
    layer = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    w = s * scale
    left, top = (s - w) / 2, (s - w) / 2 - s * 0.01
    right, bottom = left + w, top + w * 0.78
    d.rounded_rectangle([left, top, right, bottom], radius=w * 0.26, fill="white")
    # tail, bottom-left
    tail = [(left + w * 0.16, bottom - w * 0.02),
            (left + w * 0.16, bottom + w * 0.20),
            (left + w * 0.42, bottom - w * 0.02)]
    d.polygon(tail, fill="white")
    # three voice bars in the gradient color
    cx, cy = (left + right) / 2, (top + bottom) / 2
    bar_w, gap = w * 0.085, w * 0.075
    heights = [w * 0.22, w * 0.40, w * 0.28]
    x0 = cx - (3 * bar_w + 2 * gap) / 2
    for i, h in enumerate(heights):
        x = x0 + i * (bar_w + gap)
        d.rounded_rectangle([x, cy - h / 2, x + bar_w, cy + h / 2],
                            radius=bar_w / 2, fill=(37, 99, 235, 255))
    return layer.resize((size, size), Image.LANCZOS)


def rounded_mask(size, radius_frac):
    m = Image.new("L", (size * SS, size * SS), 0)
    ImageDraw.Draw(m).rounded_rectangle(
        [0, 0, size * SS - 1, size * SS - 1], radius=size * SS * radius_frac, fill=255)
    return m.resize((size, size), Image.LANCZOS)


def legacy(size):
    base = gradient(size).convert("RGBA")
    base.alpha_composite(bubble(size, 0.66))
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(base, (0, 0), rounded_mask(size, 0.22))
    return out


def main():
    legacy_sizes = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    adaptive_sizes = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
    for dens, px in legacy_sizes.items():
        legacy(px).save(f"{RES}/mipmap-{dens}/ic_launcher.png")
    for dens, px in adaptive_sizes.items():
        gradient(px).save(f"{RES}/mipmap-{dens}/ic_launcher_background.png")
        # Adaptive safe zone is the inner 66%; keep the bubble inside it.
        bubble(px, 0.58).save(f"{RES}/mipmap-{dens}/ic_launcher_foreground.png")
    print("icons written")


if __name__ == "__main__":
    main()
