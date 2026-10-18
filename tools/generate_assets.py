"""Genera las portadas de album, fotos de artista y avatares que faltan."""
import os, random, math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
S = 1000

FONT_BOLD = "C:/Windows/Fonts/segoeuib.ttf"
FONT_SEMI = "C:/Windows/Fonts/seguisb.ttf"
FONT_REG = "C:/Windows/Fonts/segoeui.ttf"
if not os.path.exists(FONT_BOLD):
    FONT_BOLD = "C:/Windows/Fonts/arialbd.ttf"
    FONT_SEMI = FONT_BOLD
    FONT_REG = "C:/Windows/Fonts/arial.ttf"


def font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except Exception:
        return ImageFont.load_default()


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def gradient(size, c1, c2, angle=135):
    small = 96
    g = Image.new("RGB", (small, small))
    px = g.load()
    rad = math.radians(angle)
    dx, dy = math.cos(rad), math.sin(rad)
    for y in range(small):
        for x in range(small):
            t = ((x / small) * dx + (y / small) * dy)
            t = max(0.0, min(1.0, (t + 0.5) / 1.0))
            px[x, y] = lerp(c1, c2, t)
    return g.resize((size, size), Image.BICUBIC)


def blobs(img, colors, seed=1):
    rnd = random.Random(seed)
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    w, h = img.size
    for c in colors:
        for _ in range(3):
            r = rnd.randint(int(w * 0.22), int(w * 0.55))
            cx = rnd.randint(-int(w * 0.1), int(w * 1.1))
            cy = rnd.randint(-int(h * 0.1), int(h * 1.1))
            d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=c + (rnd.randint(45, 95),))
    layer = layer.filter(ImageFilter.GaussianBlur(70))
    return Image.alpha_composite(img.convert("RGBA"), layer)


def grain(img, strength=14):
    noise = Image.effect_noise(img.size, 22).convert("L")
    noise = noise.filter(ImageFilter.GaussianBlur(0.4))
    overlay = Image.merge("RGBA", (noise, noise, noise, Image.new("L", img.size, strength)))
    return Image.alpha_composite(img.convert("RGBA"), overlay)


def vignette(img, power=0.55):
    w, h = img.size
    mask = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(mask)
    d.ellipse([-w * 0.25, -h * 0.25, w * 1.25, h * 1.25], fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(120))
    dark = Image.new("RGBA", (w, h), (6, 3, 12, int(255 * power)))
    dark.putalpha(mask.point(lambda v: int((255 - v) * power)))
    return Image.alpha_composite(img.convert("RGBA"), dark)


def wrap(draw, text, fnt, maxw):
    words = text.split()
    lines, cur = [], ""
    for wd in words:
        test = (cur + " " + wd).strip()
        if draw.textlength(test, font=fnt) <= maxw or not cur:
            cur = test
        else:
            lines.append(cur)
            cur = wd
    if cur:
        lines.append(cur)
    return lines


def album_cover(path, title, c1, c2, seed, label="POLIMUSIC"):
    img = gradient(S, c1, c2, 120)
    img = blobs(img, [(255, 255, 255), (192, 132, 252), (255, 255, 255)], seed)
    img = vignette(img, 0.45)
    img = grain(img, 12)

    d = ImageDraw.Draw(img)
    f_label = font(FONT_SEMI, 26)
    f_title = font(FONT_BOLD, 82)

    d.text((70, 66), " ".join(label), font=f_label, fill=(255, 255, 255, 210))

    # linea decorativa
    d.line([(70, 120), (170, 120)], fill=(255, 255, 255, 170), width=3)

    lines = wrap(d, title, f_title, S - 140)
    y = S - 90 - len(lines) * 92
    for ln in lines:
        d.text((70, y), ln, font=f_title, fill=(255, 255, 255, 255))
        y += 92

    # vinilo decorativo
    cx, cy, r = int(S * 0.72), int(S * 0.32), int(S * 0.19)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(255, 255, 255, 70), width=3)
    d.ellipse([cx - r * 0.62, cy - r * 0.62, cx + r * 0.62, cy + r * 0.62], outline=(255, 255, 255, 55), width=2)
    d.ellipse([cx - r * 0.16, cy - r * 0.16, cx + r * 0.16, cy + r * 0.16], fill=(255, 255, 255, 190))

    img.convert("RGB").save(path, quality=92, optimize=True)
    print("album  ->", os.path.basename(path))


def artist_photo(path, name, c1, c2, seed):
    img = gradient(S, c1, c2, 105)
    img = blobs(img, [(255, 255, 255), (233, 213, 255), (255, 255, 255)], seed)
    img = vignette(img, 0.5)
    img = grain(img, 10)

    d = ImageDraw.Draw(img)
    initials = "".join([p[0] for p in name.split() if p][:2]).upper()

    for rr in (0.40, 0.31):
        r = int(S * rr)
        d.ellipse([S / 2 - r, S / 2 - r, S / 2 + r, S / 2 + r], outline=(255, 255, 255, 45), width=3)

    f = font(FONT_BOLD, 300)
    bb = d.textbbox((0, 0), initials, font=f)
    d.text(((S - (bb[2] - bb[0])) / 2 - bb[0], (S - (bb[3] - bb[1])) / 2 - bb[1] - 30),
           initials, font=f, fill=(255, 255, 255, 235))

    f2 = font(FONT_SEMI, 34)
    bb2 = d.textbbox((0, 0), name, font=f2)
    d.text(((S - (bb2[2] - bb2[0])) / 2 - bb2[0], S - 86), name, font=f2, fill=(255, 255, 255, 225))

    img.convert("RGB").save(path, quality=90, optimize=True)
    print("artist ->", os.path.basename(path))


def default_cover(path):
    img = gradient(S, (44, 20, 74), (124, 58, 237), 135)
    img = blobs(img, [(255, 255, 255), (192, 132, 252)], 7)
    img = vignette(img, 0.4)
    img = grain(img, 10)
    d = ImageDraw.Draw(img)
    cx, cy = S // 2, S // 2
    d.ellipse([cx - 120, cy + 60, cx - 20, cy + 160], fill=(255, 255, 255, 235))
    d.rectangle([cx - 34, cy - 210, cx - 12, cy + 120], fill=(255, 255, 255, 235))
    d.polygon([(cx - 34, cy - 210), (cx + 130, cy - 250), (cx + 130, cy - 150), (cx - 34, cy - 120)],
              fill=(255, 255, 255, 235))
    img.convert("RGB").save(path, quality=92, optimize=True)
    print("default->", os.path.basename(path))


def avatar(path, initials, c1, c2, size=420):
    img = gradient(size, c1, c2, 135)
    img = blobs(img, [(255, 255, 255)], 3)
    d = ImageDraw.Draw(img)
    f = font(FONT_BOLD, int(size * 0.42))
    bb = d.textbbox((0, 0), initials, font=f)
    d.text(((size - (bb[2] - bb[0])) / 2 - bb[0], (size - (bb[3] - bb[1])) / 2 - bb[1] - size * 0.03),
           initials, font=f, fill=(255, 255, 255, 240))
    img.convert("RGB").save(path, quality=92, optimize=True)
    print("avatar ->", os.path.basename(path))


def main():
    alb = os.path.join(ROOT, "albumImages")
    art = os.path.join(ROOT, "ArtistImages")
    usr = os.path.join(ROOT, "userImages")
    for p in (alb, art, usr):
        os.makedirs(p, exist_ok=True)

    albums = [
        ("album1.png", "Rock Album", (46, 16, 101), (190, 24, 93), 11),
        ("album2.png", "Relax Music", (23, 37, 84), (109, 40, 217), 22),
        ("album3.png", "Retro Album Music", (67, 20, 105), (194, 65, 12), 33),
        ("album4.png", "Classic Album", (30, 12, 52), (161, 98, 7), 44),
        ("album5.png", "Country Album", (59, 20, 110), (6, 148, 114), 55),
    ]
    for fn, title, c1, c2, seed in albums:
        album_cover(os.path.join(alb, fn), title, c1, c2, seed)

    default_cover(os.path.join(alb, "default.png"))

    artists = [
        ("artist1.jpg", "Juan Gabriel", (109, 40, 217), (236, 72, 153), 61),
        ("artist2.jpg", "Ana Gabriel", (79, 30, 168), (14, 165, 233), 62),
        ("artist3.jpg", "Mariah Carey", (67, 20, 105), (217, 119, 6), 63),
        ("artist4.jpg", "Elvis Presley", (23, 23, 65), (147, 51, 234), 64),
        ("artist5.jpg", "Edward Sheeran", (49, 46, 129), (16, 185, 129), 65),
    ]
    for fn, name, c1, c2, seed in artists:
        artist_photo(os.path.join(art, fn), name, c1, c2, seed)

    avatar(os.path.join(art, "default.jpg"), "♪", (55, 30, 90), (124, 58, 237))
    avatar(os.path.join(usr, "username1.png"), "U1", (76, 29, 149), (192, 132, 252))
    avatar(os.path.join(usr, "default.jpg"), "?", (55, 30, 90), (124, 58, 237))


if __name__ == "__main__":
    main()
