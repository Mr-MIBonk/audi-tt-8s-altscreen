#!/usr/bin/env python3
"""TT cockpit CarPlay @@VERSION@@ - PC builder.

Turns the two files the head unit exported to the SD card (mod/tt/export/lsd.jxe and
dio_manager) into the two install files that cannot be published, because they contain
Audi/Harman code: mod/tt/build/tt-zoom.jar and mod/tt/build/dio_manager.

    python3 build.py            (run it from the SD card; Windows: py build.py)

Needs Python 3.8+ and Java 11+ (java on the PATH), and internet once: it downloads
jxe2jar (luka-dev, pinned commit) and ASM 9.7 (Maven Central) and checks every file's
SHA-256. The result must match the tested build byte for byte, or nothing is written.
Nothing is uploaded anywhere.
"""
import hashlib
import os
import shutil
import struct
import subprocess
import sys
import tempfile
import urllib.request
import zipfile

VERSION = "@@VERSION@@"
STOCK_JXE = "@@STOCK_JXE@@"
STOCK_DIO = "@@STOCK_DIO@@"
NEW_JAR = "@@NEW_JAR@@"
NEW_DIO = "@@NEW_DIO@@"

JXE2JAR = "https://raw.githubusercontent.com/luka-dev/jxe2jar/9eeb45bbf14bf8afe3452c7be96a4d1f0206a286/src/"
JXE2JAR_FILES = {
    "bitstring.py": "04daec6b4f5aa674745708046c7684d7f9b1e89fcf76bfb9086110925e24cee0",
    "bytecode.py": "ed6587a65168b15328b7d1ea8c34f554e9f543531a159e41a653897364aa51b4",
    "common.py": "be0371b82224ec56940db537174283d9a30489f8f6ad4f53f4c15c2922b5c6db",
    "constpool.py": "66da7ba7769296c69b5fef82c9276fcdea47bebfd2ea73d7c5ebc3405c7334a4",
    "jxe.py": "82dd48ee04e102702955cc09f9bbd4412edbef949d4935da76ddae6e62a89039",
    "jxe2jar.py": "9f56143ae6ae53f3f3b1ebcd7eb8a45a089cc65ccf9fb5535d760bd10585b7c9",
    "rt.classes": "3af102e6175d9f2384ca7fd49fceb0a02575bbca0c37a68fd1b2674cf7ef68e0",
}
MAVEN = "https://repo1.maven.org/maven2/org/ow2/asm/"
ASM = {
    "asm-9.7.jar": ("asm/9.7/asm-9.7.jar", "adf46d5e34940bdf148ecdd26a9ee8eea94496a72034ff7141066b3eea5c4e9d"),
    "asm-tree-9.7.jar": ("asm-tree/9.7/asm-tree-9.7.jar", "62f4b3bc436045c1acb5c3ba2d8ec556ec3369093d7f5d06c747eb04b56d52b1"),
    "asm-analysis-9.7.jar": ("asm-analysis/9.7/asm-analysis-9.7.jar", "7bc6bcbc21379948a0c8c467fb0f864206e5b818f6bc0b546872f5c9f941556f"),
    "asm-util-9.7.jar": ("asm-util/9.7/asm-util-9.7.jar", "37a6414d36641973f1af104937c95d6d921b2ddb4d612c66c5a9f2b13fc14211"),
}

HERE = os.path.dirname(os.path.abspath(__file__))
TT = os.path.dirname(HERE)
EXPORT = os.path.join(TT, "export")
BUILD = os.path.join(TT, "build")


def sha(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def stop(msg):
    print("\nSTOPPED: " + msg)
    print("Nothing was written to the SD card.")
    sys.exit(1)


def fetch(url, dest, want):
    if os.path.exists(dest) and sha(dest) == want:
        return
    print("  downloading " + url.rsplit("/", 1)[1])
    tmp = dest + ".part"
    try:
        with urllib.request.urlopen(url, timeout=60) as r, open(tmp, "wb") as f:
            shutil.copyfileobj(r, f)
    except Exception as e:
        stop("download failed (%s): %s" % (url, e))
    if sha(tmp) != want:
        os.remove(tmp)
        stop("downloaded file has the wrong checksum: " + url)
    os.replace(tmp, dest)


def java_ok():
    try:
        p = subprocess.run(["java", "-version"], capture_output=True, text=True)
    except OSError:
        return None
    out = (p.stderr or "") + (p.stdout or "")
    return out.splitlines()[0] if out else "java"


def mkjar(src, out):
    """Deterministic jar (same as the project's hmi/tools/mkjar.py)."""
    names = sorted(os.path.relpath(os.path.join(r, f), src).replace(os.sep, "/")
                   for r, _, fs in os.walk(src) for f in fs)
    with zipfile.ZipFile(out, "w") as z:
        entries = [("META-INF/MANIFEST.MF", None)] + [(n, n) for n in names]
        for n, path in entries:
            if path is None:
                data = b"Manifest-Version: 1.0\r\n\r\n"
            else:
                with open(os.path.join(src, *path.split("/")), "rb") as f:
                    data = f.read()
            # stored + fixed create_system: the same bytes on every PC (deflate differs by zlib build)
            zi = zipfile.ZipInfo(n, (2026, 1, 1, 0, 0, 0))
            zi.compress_type = zipfile.ZIP_STORED
            zi.create_system = 0
            z.writestr(zi, data)


def patch_dio(src, dst):
    """Hook-first dio_manager (same as the project's scripts/patch_dio_mu1462.py)."""
    DYN, NEEDED_COUNT, STRTAB, RPATH_VAL = 682504, 18, 22664, 13842
    DT_NEEDED, DT_RPATH = 1, 15
    HOOK = b"libaltscreen111.so\0"
    data = bytearray(open(src, "rb").read())
    entries = [struct.unpack_from("<II", data, DYN + i * 8) for i in range(NEEDED_COUNT + 1)]
    if any(t != DT_NEEDED for t, _ in entries[:NEEDED_COUNT]) or entries[NEEDED_COUNT] != (DT_RPATH, RPATH_VAL):
        stop("dio_manager layout is not as expected")
    at = STRTAB + RPATH_VAL
    data[at:at + len(HOOK)] = HOOK
    new = [(DT_NEEDED, RPATH_VAL)] + [(DT_NEEDED, v) for _, v in entries[:NEEDED_COUNT]]
    for i, (tag, val) in enumerate(new):
        struct.pack_into("<II", data, DYN + i * 8, tag, val)
    with open(dst, "wb") as f:
        f.write(data)


def main():
    print("TT cockpit CarPlay %s - PC builder" % VERSION)
    if sys.version_info < (3, 8):
        stop("Python 3.8 or newer is needed (this is %s)" % sys.version.split()[0])
    jxe = os.path.join(EXPORT, "lsd.jxe")
    dio = os.path.join(EXPORT, "dio_manager")
    if not (os.path.exists(jxe) and os.path.exists(dio)):
        stop("mod/tt/export/ has no lsd.jxe and dio_manager. Run the 'export' step in the car first.")
    print("1/5 checking the exported files")
    if sha(jxe) != STOCK_JXE:
        stop("lsd.jxe is not MU1462 P5180 - this release does not support your head unit.")
    if sha(dio) != STOCK_DIO:
        stop("dio_manager is not the stock MU1462 file.")
    jv = java_ok()
    if not jv:
        stop("Java was not found. Install Java 11 or newer (e.g. Temurin from adoptium.net) and try again.")
    print("    " + jv)

    work = tempfile.mkdtemp(prefix="tt-build-")
    try:
        cache = os.path.join(work, "cache")
        os.makedirs(os.path.join(cache, "jxe2jar"))
        print("2/5 downloading tools (jxe2jar, ASM)")
        for name, want in JXE2JAR_FILES.items():
            fetch(JXE2JAR + name, os.path.join(cache, "jxe2jar", name), want)
        for name, (path, want) in ASM.items():
            fetch(MAVEN + path, os.path.join(cache, name), want)

        print("3/5 converting lsd.jxe (about a minute)")
        stock = os.path.join(work, "stock.jar")
        p = subprocess.run([sys.executable, "-E", "-s", os.path.join(cache, "jxe2jar", "jxe2jar.py"), jxe, stock],
                           cwd=os.path.join(cache, "jxe2jar"), capture_output=True, text=True)
        if p.returncode != 0 or not os.path.exists(stock):
            print((p.stdout or "")[-2000:], (p.stderr or "")[-2000:])
            stop("jxe2jar failed")

        print("4/5 building the HMI jar")
        out = os.path.join(work, "out")
        os.makedirs(out)
        # work on a copy without the "._Name" AppleDouble files macOS adds on FAT cards
        # (PatchZoom read ._RouteRec.class as a class and stopped)
        classes = os.path.join(work, "classes")
        shutil.copytree(os.path.join(HERE, "classes"), classes,
                        ignore=shutil.ignore_patterns("._*", ".DS_Store"))
        cp = os.pathsep.join([os.path.join(classes, "tools")] + [os.path.join(cache, n) for n in ASM])
        gate = os.path.join(classes, "gate", "local", "tt", "ZoomGate.class")
        for args in (["PatchZoom", stock, gate, out], ["VerifyZoom", stock, out]):
            p = subprocess.run(["java", "-cp", cp] + args, capture_output=True, text=True)
            if p.returncode != 0:
                print((p.stdout or "")[-3000:], (p.stderr or "")[-3000:])
                stop(args[0] + " failed")
        jar = os.path.join(work, "tt-zoom.jar")
        mkjar(out, jar)
        got = sha(jar)
        if got != NEW_JAR:
            stop("the HMI jar does not match the tested build (%s). Please report this." % got[:16])

        print("5/5 patching dio_manager")
        dnew = os.path.join(work, "dio_manager")
        patch_dio(dio, dnew)
        if sha(dnew) != NEW_DIO:
            stop("the patched dio_manager does not match the tested build. Please report this.")

        os.makedirs(BUILD, exist_ok=True)
        for f in ("tt-zoom.jar", "dio_manager"):
            shutil.copyfile(os.path.join(work, f), os.path.join(BUILD, f))
        if sha(os.path.join(BUILD, "tt-zoom.jar")) != NEW_JAR or sha(os.path.join(BUILD, "dio_manager")) != NEW_DIO:
            stop("writing to the SD card failed (card full or damaged?)")
    finally:
        shutil.rmtree(work, ignore_errors=True)

    print("\nDone: mod/tt/build/tt-zoom.jar and mod/tt/build/dio_manager match the tested build.")
    print("You may delete mod/tt/export/ now (60 MB).")
    print("Next: optional librgd_hook.so into mod/tt/user/, eject the card, then run 'install':")
    print("MIB2 Toolbox: Customization -> TTCarPlay -> 3. install;  M.I.B.: write install into")
    print("mod/tt/action.txt and Run Custom Script.")


if __name__ == "__main__":
    main()
