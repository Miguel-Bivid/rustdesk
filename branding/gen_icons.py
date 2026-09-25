#!/usr/bin/env python3
"""Regenera todos los iconos de la app a partir de branding/icon.svg y branding/glyph.svg.

  python branding/gen_icons.py

Requiere: pip install resvg-py pillow
"""
import io
import shutil
from pathlib import Path

import resvg_py
from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
ICON = (HERE / "icon.svg").read_text(encoding="utf-8")
GLYPH = (HERE / "glyph.svg").read_text(encoding="utf-8")
ANDROID_RES = ROOT / "flutter/android/app/src/main/res"
DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}


def render(svg, size):
    png = resvg_py.svg_to_bytes(svg_string=svg, width=size, height=size)
    return Image.open(io.BytesIO(bytes(png))).convert("RGBA")


def save_png(svg, size, path, mode=None):
    im = render(svg, size)
    if mode:
        im = im.convert(mode)
    im.save(ROOT / path)


def save_ico(path, sizes):
    big = render(ICON, 256)
    big.save(ROOT / path, sizes=[(s, s) for s in sizes])


def android_foreground(size):
    # Safe zone of an adaptive icon is the inner 66/108 of the canvas.
    canvas = Image.new("RGBA", (size, size))
    inner = round(size * 66 / 108)
    glyph = render(GLYPH, inner)
    offset = (size - inner) // 2
    canvas.alpha_composite(glyph, (offset, offset))
    return canvas


def main():
    save_png(ICON, 1024, "res/icon.png")
    save_png(ICON, 512, "res/mac-icon.png")
    save_png(ICON, 256, "res/128x128@2x.png")
    save_png(ICON, 128, "res/128x128.png")
    save_png(ICON, 64, "res/64x64.png")
    save_png(ICON, 32, "res/32x32.png")
    save_ico("res/icon.ico", [16, 24, 32, 48, 64, 128, 256])
    save_ico("res/tray-icon.ico", [16, 20, 24, 32, 48])
    save_ico("flutter/windows/runner/resources/app_icon.ico", [16, 24, 32, 48, 64, 128, 256])
    shutil.copy(HERE / "icon.svg", ROOT / "res/scalable.svg")
    shutil.copy(HERE / "icon.svg", ROOT / "flutter/assets/icon.svg")

    for density, scale in DENSITIES.items():
        d = ANDROID_RES / f"mipmap-{density}"
        launcher = round(48 * scale)
        render(ICON, launcher).save(d / "ic_launcher.png")
        render(ICON, launcher).save(d / "ic_launcher_round.png")
        android_foreground(round(108 * scale)).save(d / "ic_launcher_foreground.png")
        render(GLYPH, round(24 * scale)).convert("LA").save(d / "ic_stat_logo.png")
    print("Iconos regenerados")


if __name__ == "__main__":
    main()
