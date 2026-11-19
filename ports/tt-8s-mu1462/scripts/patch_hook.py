#!/usr/bin/env python3
"""Patch the AltScreen hook so a busy renderer tee port never blocks CarPlay.

usage: python3 -I patch_hook.py carplay/bin/libaltscreen111.so out/libaltscreen111.so

Car log (run32): after the iPhone dropped, every reconnect loaded the hook again, but
127.0.0.1:19820 (the renderer tee) was still taken by the old session, so the hook logged
"cannot start local H264 tee; AltScreen disabled fail-closed" and returned before it had
looked up the stock AirPlayReceiverSession* functions. Its exported replacements still
interposed them, found no stock delegate ("FATAL no stock SessionSetup delegate") and the
session setup failed: the CarPlay icon flickered and the phone never connected.

altscreen111_init -> start_tee_server -> bind_listener_ipv4(19820, &actual, loopback=1,
allow_ephemeral=0). One instruction sets allow_ephemeral to 1: when 19820 is free nothing
changes; when it is busy the tee takes a free port, the init finishes and CarPlay connects.
(The cockpit renderer still looks for 19820, so the CarPlay map in the cockpit waits until
the old holder is gone.)
"""
import hashlib
import struct
import sys

SRC_SHA = "9a8c01ec8323d5de7695e212ff6168b0bb7df99d8554c9971f5449c5a21d6256"
OFF_MOV = 0xb494     # mov r3, r6   (allow_ephemeral = 0)  ->  mov r3, #1
OFF_BL = 0xb4a0      # bl bind_listener_ipv4 (first call in altscreen111_init: the tee)
OLD = 0xe1a03006
NEW = 0xe3a03001

src, dst = sys.argv[1], sys.argv[2]
b = bytearray(open(src, "rb").read())
assert hashlib.sha256(b).hexdigest() == SRC_SHA, "not the shipped libaltscreen111.so"
assert struct.unpack_from("<I", b, OFF_MOV)[0] == OLD
assert struct.unpack_from("<I", b, OFF_MOV - 4)[0] == 0xe3a02001          # mov r2, #1 (loopback)
assert struct.unpack_from("<I", b, OFF_BL)[0] == 0xebffdee1               # bl bind_listener_ipv4
assert struct.unpack_from("<I", b, OFF_BL + 4)[0] == 0xe3500000           # cmp r0, #0
struct.pack_into("<I", b, OFF_MOV, NEW)
open(dst, "wb").write(b)
print(dst, hashlib.sha256(b).hexdigest())
