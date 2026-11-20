"""Deterministic jar: fixed timestamps, sorted entries, so the same input always gives the same sha256.
v50: entries are stored uncompressed with a fixed create_system. Deflate output differs between
zlib builds (Python 3.14 on Windows ships zlib-ng), so compressed jars had a different hash on
other PCs even with identical contents.
usage: python3 -I mkjar.py <class dir> <out jar>   (prints the sha256)"""
import hashlib
import os
import sys
import zipfile

src, out = sys.argv[1], sys.argv[2]
names = sorted(os.path.relpath(os.path.join(r, f), src).replace(os.sep, '/')
               for r, _, fs in os.walk(src) for f in fs)
with zipfile.ZipFile(out, 'w') as z:
    for n, data in [('META-INF/MANIFEST.MF', b'Manifest-Version: 1.0\r\n\r\n')] + \
            [(n, open(os.path.join(src, *n.split('/')), 'rb').read()) for n in names]:
        zi = zipfile.ZipInfo(n, (2026, 1, 1, 0, 0, 0))
        zi.compress_type = zipfile.ZIP_STORED
        zi.create_system = 0
        z.writestr(zi, data)
print(hashlib.sha256(open(out, 'rb').read()).hexdigest())
