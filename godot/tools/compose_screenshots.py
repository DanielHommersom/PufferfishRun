"""Composes App Store screenshots: background art + caption + a real in-game capture.

    python3 godot/tools/compose_screenshots.py <raw_dir> <background.png> <out_dir> <iphone|ipad>

raw_dir holds the captures from tests/store_captures.gd. The background is cropped to fill the
canvas. Captions use the game's typeface (Courier New Bold) in the game's orange and gold.
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

SIZES = {"iphone": (1179, 2556), "ipad": (2048, 2732)}
FONT = "/System/Library/Fonts/Supplemental/Courier New Bold.ttf"
ORANGE = (244, 168, 50)
ORANGE_DARK = (120, 60, 0)
WHITE = (255, 255, 255)

# Order on the App Store: the first three matter most.
SHOTS = [
    ("02_gameplay", "HOLD TO PUFF", "SQUEEZE THROUGH THE REEF"),
    ("03_kelp_magnet", "GRAB POWER-UPS", "MAGNET, SHIELD & SLOW-MO"),
    ("05_abyss", "DIVE DEEPER", "ALL THE WAY TO THE ABYSS"),
    ("06_shop_hats", "DRESS UP", "12 SKINS, 7 HATS & 5 TRAILS"),
    ("04_shipwreck_shield", "6 OCEAN ZONES", "FROM REEF TO SHIPWRECK"),
    ("07_daily", "COME BACK DAILY", "REWARDS, MISSIONS & CHALLENGES"),
    ("01_menu", "HOW DEEP CAN YOU GO?", "FREE TO PLAY"),
]


def cover(img, size):
    """Scale and centre-crop img so it fills size."""
    w, h = size
    s = max(w / img.width, h / img.height)
    img = img.resize((round(img.width * s), round(img.height * s)), Image.LANCZOS)
    x, y = (img.width - w) // 2, (img.height - h) // 2
    return img.crop((x, y, x + w, y + h))


def fit_font(draw, text, max_w, start):
    size = start
    while size > 20:
        f = ImageFont.truetype(FONT, size)
        if draw.textlength(text, font=f) <= max_w:
            return f
        size -= 4
    return ImageFont.truetype(FONT, size)


def centered(draw, text, y, font, fill, outline, stroke, canvas_w):
    w = draw.textlength(text, font=font)
    draw.text(((canvas_w - w) / 2, y), text, font=font, fill=fill, stroke_width=stroke, stroke_fill=outline)


def compose(raw, bg, title, sub, device):
    W, H = SIZES[device]
    canvas = cover(bg.convert("RGB"), (W, H))
    # Slight darkening at the top so the caption always reads well
    shade = Image.new("L", (W, H), 0)
    sd = ImageDraw.Draw(shade)
    for y in range(int(H * 0.32)):
        sd.line([(0, y), (W, y)], fill=int(120 * (1 - y / (H * 0.32))))
    canvas = Image.composite(Image.new("RGB", (W, H), (2, 10, 25)), canvas, shade)

    draw = ImageDraw.Draw(canvas)
    margin = int(W * 0.07)
    title_font = fit_font(draw, title, W - 2 * margin, int(W * (0.115 if device == "iphone" else 0.08)))
    sub_font = fit_font(draw, sub, W - 2 * margin, int(W * (0.052 if device == "iphone" else 0.036)))
    top = int(H * 0.055)
    centered(draw, title, top, title_font, ORANGE, ORANGE_DARK, max(4, title_font.size // 12), W)
    centered(draw, sub, top + int(title_font.size * 1.25), sub_font, WHITE, (0, 0, 0), max(2, sub_font.size // 14), W)

    # The real game screen, framed with rounded corners and a soft shadow
    caption_bottom = top + int(title_font.size * 1.25) + int(sub_font.size * 2.1)
    avail_h = H - caption_bottom - int(H * 0.035)
    scale = min(avail_h / raw.height, (W - 2 * margin * 0.6) / raw.width)
    sw, sh = round(raw.width * scale), round(raw.height * scale)
    shot = raw.convert("RGB").resize((sw, sh), Image.LANCZOS)
    radius = int(sw * 0.07)
    border = max(6, int(sw * 0.012))
    x, y = (W - sw) // 2, caption_bottom + (avail_h - sh) // 2

    shadow = Image.new("L", (W, H), 0)
    ImageDraw.Draw(shadow).rounded_rectangle([x - border, y - border + 18, x + sw + border, y + sh + border + 18], radius + border, fill=150)
    shadow = shadow.filter(ImageFilter.GaussianBlur(28))
    canvas = Image.composite(Image.new("RGB", (W, H), (0, 0, 0)), canvas, shadow)

    frame = Image.new("L", (W, H), 0)
    ImageDraw.Draw(frame).rounded_rectangle([x - border, y - border, x + sw + border, y + sh + border], radius + border, fill=255)
    canvas = Image.composite(Image.new("RGB", (W, H), WHITE), canvas, frame)

    mask = Image.new("L", (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, sw - 1, sh - 1], radius, fill=255)
    canvas.paste(shot, (x, y), mask)
    return canvas


def main():
    raw_dir, bg_path, out_dir, device = sys.argv[1:5]
    os.makedirs(out_dir, exist_ok=True)
    bg = Image.open(bg_path)
    for i, (name, title, sub) in enumerate(SHOTS, 1):
        raw = Image.open(os.path.join(raw_dir, name + ".png"))
        out = compose(raw, bg, title, sub, device)
        path = os.path.join(out_dir, "%02d_%s.png" % (i, name[3:]))
        out.save(path)
        print("saved", path, out.size)


if __name__ == "__main__":
    main()
