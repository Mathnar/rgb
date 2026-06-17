#!/usr/bin/env python3
"""Generate the neon RGB app icon + splash logo.

Requires Pillow:  pip install Pillow
Run from the repo root:  python3 tools/gen_branding.py
Then apply with:
    dart run flutter_launcher_icons
    dart run flutter_native_splash:create
"""
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "assets", "branding")

# Pick any bold geometric TTF you like; update this path if needed.
FONT = os.environ.get(
    "RGB_FONT",
    "/mnt/skills/examples/canvas-design/canvas-fonts/Outfit-Bold.ttf",
)

BG = (7, 7, 11, 255)
LETTERS = [("R", (255, 45, 85)), ("G", (43, 255, 136)), ("B", (45, 156, 255))]


def render_logo(canvas_size, target_width_frac, with_bg, glow=True):
    S = canvas_size
    img = Image.new("RGBA", (S, S), BG if with_bg else (0, 0, 0, 0))

    target_w = S * target_width_frac
    spacing = 0.06
    size = 10
    while True:
        f = ImageFont.truetype(FONT, size)
        widths = [f.getbbox(c)[2] - f.getbbox(c)[0] for c, _ in LETTERS]
        total = sum(widths) + size * spacing * (len(LETTERS) - 1)
        if total >= target_w or size > S:
            break
        size += 4
    f = ImageFont.truetype(FONT, size)

    metrics = [(c, col, f.getbbox(c)) for c, col in LETTERS]
    gap = size * spacing
    total = sum(bb[2] - bb[0] for _, _, bb in metrics) + gap * (len(metrics) - 1)
    top = min(bb[1] for _, _, bb in metrics)
    bot = max(bb[3] for _, _, bb in metrics)
    x = (S - total) / 2
    y = (S - (bot - top)) / 2 - top

    glow_layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sharp_layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    gd, sd = ImageDraw.Draw(glow_layer), ImageDraw.Draw(sharp_layer)

    cursor = x
    for c, col, bb in metrics:
        w = bb[2] - bb[0]
        gd.text((cursor - bb[0], y), c, font=f, fill=col + (255,))
        core = tuple(min(255, int(v + (255 - v) * 0.55)) for v in col)
        sd.text((cursor - bb[0], y), c, font=f, fill=core + (255,))
        cursor += w + gap

    if glow:
        for radius in (S * 0.05, S * 0.025, S * 0.012):
            img = Image.alpha_composite(
                img, glow_layer.filter(ImageFilter.GaussianBlur(radius))
            )
    img = Image.alpha_composite(img, glow_layer)
    img = Image.alpha_composite(img, sharp_layer)
    return img


def main():
    os.makedirs(OUT, exist_ok=True)
    render_logo(1024, 0.78, with_bg=True).save(os.path.join(OUT, "icon_source.png"))
    render_logo(1024, 0.58, with_bg=False).save(os.path.join(OUT, "icon_foreground.png"))
    render_logo(1152, 0.46, with_bg=False).save(os.path.join(OUT, "splash_logo.png"))
    print("Branding written to", os.path.normpath(OUT))


if __name__ == "__main__":
    main()
