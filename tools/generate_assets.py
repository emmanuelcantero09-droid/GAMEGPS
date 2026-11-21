#!/usr/bin/env python3
"""Genera el icono de la app sin dependencias externas (PNG puro con zlib)."""

import math
import os
import struct
import zlib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SS = 4  # supersampling para bordes suaves

CYAN = (0x00, 0xE5, 0xFF)
VIOLET = (0x7B, 0x2B, 0xFF)
DARK = (0x05, 0x07, 0x0F)
NAVY = (0x0B, 0x14, 0x26)


def inside_round_rect(x, y, cx, cy, hw, hh, r):
    dx = abs(x - cx) - (hw - r)
    dy = abs(y - cy) - (hh - r)
    if dx <= 0 or dy <= 0:
        return dx <= 0 and dy <= 0
    return dx * dx + dy * dy <= r * r


def inside_cross(x, y, cx, cy, half_len, half_thick):
    return (
        abs(x - cx) <= half_len and abs(y - cy) <= half_thick
    ) or (
        abs(y - cy) <= half_len and abs(x - cx) <= half_thick
    )


def inside_triangle(px, py, a, b, c):
    def sign(p1, p2, p3):
        return (p1[0] - p3[0]) * (p2[1] - p3[1]) - (p2[0] - p3[0]) * (p1[1] - p3[1])

    d1 = sign((px, py), a, b)
    d2 = sign((px, py), b, c)
    d3 = sign((px, py), c, a)
    neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
    pos = (d1 > 0) or (d2 > 0) or (d3 > 0)
    return not (neg and pos)


def inside_pin(x, y, scale=1.0):
    cx, cy = 0.5, 0.40
    r = 0.165 * scale
    if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
        return True
    tip = (cx, cy + 0.34 * scale)
    left = (cx - 0.165 * scale, cy + 0.05 * scale)
    right = (cx + 0.165 * scale, cy + 0.05 * scale)
    return inside_triangle(x, y, tip, left, right)


def inside_circle(x, y, cx, cy, r):
    return (x - cx) ** 2 + (y - cy) ** 2 <= r * r


def blend(buf, w, h, x, y, color, alpha=1.0):
    if x < 0 or y < 0 or x >= w or y >= h or alpha <= 0:
        return
    i = (y * w + x) * 4
    a = min(1.0, alpha)
    for c in range(3):
        buf[i + c] = int(buf[i + c] * (1 - a) + color[c] * a)
    buf[i + 3] = 255


def round_rect(buf, w, h, cx, cy, hw, hh, r, color_fn):
    for y in range(h):
        ny = (y + 0.5) / h
        for x in range(w):
            nx = (x + 0.5) / w
            if inside_round_rect(nx, ny, cx, cy, hw, hh, r):
                blend(buf, w, h, x, y, color_fn(nx, ny))


def shape(buf, w, h, test, color, alpha=1.0):
    for y in range(h):
        ny = (y + 0.5) / h
        for x in range(w):
            nx = (x + 0.5) / w
            if test(nx, ny):
                blend(buf, w, h, x, y, color, alpha)


def render(size):
    w = h = size * SS
    buf = bytearray(w * h * 4)
    for i in range(0, len(buf), 4):
        buf[i:i + 4] = bytes(DARK + (0,))

    def bg(nx, ny):
        t = min(1.0, max(0.0, (nx + ny) / 2))
        return tuple(int(NAVY[c] * (1 - t) + (0x06, 0x0B, 0x18)[c] * t) for c in range(3))

    round_rect(buf, w, h, 0.5, 0.5, 0.5, 0.5, 0.19, bg)

    # Rejilla sutil tipo HUD
    for i in range(1, 8):
        p = i / 8
        shape(buf, w, h, lambda x, y, p=p: abs(x - p) < 0.0012 or abs(y - p) < 0.0012,
              (0x12, 0x2A, 0x44), 0.5)

    # Cruz de mando (glow + cuerpo)
    shape(buf, w, h, lambda x, y: inside_cross(x, y, 0.5, 0.60, 0.42, 0.15), CYAN, 0.16)
    shape(buf, w, h, lambda x, y: inside_cross(x, y, 0.5, 0.60, 0.34, 0.085), VIOLET, 0.95)

    # Pin GPS (glow + cuerpo)
    shape(buf, w, h, lambda x, y: inside_pin(x, y, 1.30), CYAN, 0.18)
    shape(buf, w, h, lambda x, y: inside_pin(x, y, 1.0), CYAN, 1.0)

    # Ojo del pin
    shape(buf, w, h, lambda x, y: inside_circle(x, y, 0.5, 0.40, 0.080), DARK, 1.0)
    shape(buf, w, h, lambda x, y: inside_circle(x, y, 0.5, 0.40, 0.032), CYAN, 1.0)

    # Botones del mando
    shape(buf, w, h, lambda x, y: inside_circle(x, y, 0.17, 0.66, 0.035), CYAN, 0.9)
    shape(buf, w, h, lambda x, y: inside_circle(x, y, 0.83, 0.66, 0.035), VIOLET, 0.9)

    # Downsample
    out = bytearray(size * size * 4)
    for y in range(size):
        for x in range(size):
            acc = [0, 0, 0, 0]
            for sy in range(SS):
                for sx in range(SS):
                    i = ((y * SS + sy) * w + (x * SS + sx)) * 4
                    for c in range(4):
                        acc[c] += buf[i + c]
            j = (y * size + x) * 4
            for c in range(4):
                out[j + c] = acc[c] // (SS * SS)
    return size, size, out


def write_png(path, w, h, buf):
    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    raw = b"".join(b"\x00" + bytes(buf[y * w * 4:(y + 1) * w * 4]) for y in range(h))
    png = (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b"")
    )
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(png)
    print(f"{path} ({w}x{h})")


def main():
    densities = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, size in densities.items():
        w, h, buf = render(size)
        write_png(os.path.join(ROOT, "android", "app", "src", "main", "res", folder, "ic_launcher.png"), w, h, buf)

    w, h, buf = render(512)
    write_png(os.path.join(ROOT, "assets", "logo", "app_icon.png"), w, h, buf)


if __name__ == "__main__":
    main()
