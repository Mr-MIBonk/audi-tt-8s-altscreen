#!/usr/bin/env python3
"""Turn any picture into the turn panel's background file (panel-bg.a8) for tt-zoom v29+.

The panel draws it centred and faint behind the arrow and text, proportions kept. Light parts
of the picture become visible; dark parts stay transparent (use --invert for dark-on-light art).
The picture is cropped to its content first.

    python3 mkbg.py my-picture.png panel-bg.a8 [--invert] [--width 600]

Needs Pillow (pip install pillow). Copy the result to /mnt/app/root/tt/panel-bg.a8 on the car
(sh tt.sh setup does this when panel-bg.a8 is in /tmp). Pictures are yours: they are not part
of this repository.

File format: b"TTBG", u16 width, u16 height (big-endian), then width*height alpha bytes.
"""
import argparse
import struct
import sys

from PIL import Image


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('src')
    ap.add_argument('dst')
    ap.add_argument('--invert', action='store_true', help='dark shapes on a light background')
    ap.add_argument('--width', type=int, default=600)
    a = ap.parse_args()
    im = Image.open(a.src).convert('L')
    if a.invert:
        im = Image.eval(im, lambda v: 255 - v)
    box = im.point(lambda v: 255 if v > 128 else 0).getbbox()
    if box is None:
        sys.exit('picture has no light content (try --invert)')
    im = im.crop(box)
    w = min(a.width, im.width)
    h = max(2, round(im.height * w / im.width))
    im = im.resize((w, h), Image.LANCZOS)
    with open(a.dst, 'wb') as f:
        f.write(b'TTBG' + struct.pack('>HH', w, h) + im.tobytes())
    print('wrote %s (%dx%d)' % (a.dst, w, h))


if __name__ == '__main__':
    main()
