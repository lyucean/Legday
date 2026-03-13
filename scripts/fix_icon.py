#!/usr/bin/env python3
"""Делает фон иконки фиолетовым и увеличивает фигуру в 2 раза по центру."""
from PIL import Image
import sys

def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "Legday/Assets.xcassets/AppIcon.appiconset/icon_1024.png"
    img = Image.open(path).convert("RGBA")
    w, h = img.size
    pix = img.load()

    # Фон — тёмно-фиолетовый, фигура — светлее. Находим фигуру по яркости.
    # Тёмный фон ~ (41,36,61), фигура ~ (169,128,225). Порог по сумме каналов.
    bg_avg = (41 + 36 + 61) / 3   # ~46
    fg_avg = (169 + 128 + 225) / 3  # ~174
    threshold = (bg_avg + fg_avg) / 2  # ~110

    # Маска: 1 = фигура (светлое), 0 = фон
    mask = Image.new("L", (w, h), 0)
    md = mask.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = pix[x, y]
            s = r + g + b
            if s > threshold * 3 and a > 128:
                md[x, y] = 255

    # Bounding box фигуры
    bbox = mask.getbbox()
    if not bbox:
        print("Figure bbox not found")
        return
    x0, y0, x1, y1 = bbox
    fw, fh = x1 - x0, y1 - y0

    # Вырезаем фигуру (с альфой по маске)
    figure = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
    for y in range(fh):
        for x in range(fw):
            px = pix[x0 + x, y0 + y]
            figure.putpixel((x, y), (*px[:3], md[x0 + x, y0 + y]))

    # Увеличиваем фигуру в 2 раза
    scale = 2
    nfw, nfh = fw * scale, fh * scale
    figure_big = figure.resize((nfw, nfh), Image.Resampling.LANCZOS)

    # Фон — тёмно-фиолетовый (как в оригинале)
    purple_bg = (41, 36, 61, 255)
    out = Image.new("RGBA", (w, h), purple_bg)

    # Центрируем увеличенную фигуру
    paste_x = (w - nfw) // 2
    paste_y = (h - nfh) // 2
    out.paste(figure_big, (paste_x, paste_y), figure_big)

    out.convert("RGB").save(path)
    print("Done:", path)

if __name__ == "__main__":
    main()
