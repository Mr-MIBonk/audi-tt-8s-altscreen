#!/usr/bin/env python3
"""Assemble the SD-card release zip (maintainers only).

    python3 make-release.py VERSION OUT_DIR \\
        --stock-jar mu1462-stock.jar --asm-dir dl_maven --jdk-bin "C:/Program Files/Java/jdk-17/bin" \\
        --hook libaltscreen111-tt2.so --runtime cluster_runtime-sport --supervisor cluster_supervisor.sh \\
        --sha-tool altscreen-sha256 [--test-jxe lsd.jxe --test-dio dio_manager]

The zip holds only GPL code built by this project (CarPlay hook, renderer, supervisor,
checksum tool, toolkit, our compiled HMI classes and the patch tool). No Audi/Harman file:
the PC builder makes tt-zoom.jar and dio_manager from the user's own head unit.
Every input is checked against the hashes below; with --test-jxe/--test-dio the PC builder
runs end to end on a copy of the tree and must reproduce NEW_JAR / NEW_DIO.
"""
import argparse
import hashlib
import os
import shutil
import subprocess
import sys
import tempfile
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
PORT = os.path.dirname(HERE)

STOCK = {
    "STOCK_JXE": "44d0dfe86146f4f6f87819921088aa282025aebfcc940c7288804fc476ff21b7",
    "STOCK_AIRPLAY": "bd0fff7f7345d58493611d637bd6bce6362ca01d3b44c5be1e320c4f5c9c3c9c",
    "STOCK_IAP2": "7b9a1a6beef7bc893bb5a824486f4ad5fc34912a0b894a6d24d171ab324a8cb7",
    "STOCK_DIO": "1974dbd95df5c33f81da4d8cf2c77b791e5a6466aa65c7d1912ec9ebd8c140e3",
    "STOCK_MMIPOD": "d5af4a342705bd7ac3498a080e24faf5702c6fc2960895f58aa2800268126464",
    "NEW_DIO": "115259ff6f90af800c8a06c3b0655b2a59cffe00990ad6e7f525cc45c73c9043",
    "RGD_HOOK": "55470830e7972b55bb7b5d5a00fd8fe0802f5fe21018415d839ac57bef556a99",
    "SHA_TOOL": "c5609239ca978c0e29926c879d8ea3459b0ca29e6691cc72ad484feda570da9d",
}
# The tested set for this release (update together with a car test).
TESTED = {
    "NEW_LIB": "347a911454a48cc494851178d4298c29b71d8854fd3087ce6cb403e51c7885c5",   # hook TT build 2
    "NEW_RT": "24bf08142cc43a18330550ca448f4635e10d5ab3ed38475e80d450a469991a7f",    # renderer, Sport shift
    "NEW_SUP": None,   # set with --supervisor-sha after the car test (v6 de728b17 / v7 e8dbabca)
    "NEW_JAR": "ac5f1958763d70f4890f83ad0659807f6b18b7a67992acacaa36d4b6738b141e",   # tt-zoom v50 (pending car test)
}


def sha(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for b in iter(lambda: f.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def run(cmd, **kw):
    print("  $ " + " ".join(cmd)[:160])
    subprocess.run(cmd, check=True, **kw)


def fill(text, sub):
    for k, v in sub.items():
        text = text.replace("@@%s@@" % k, v)
    if "@@" in text:
        sys.exit("unfilled placeholder in template")
    return text


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("version")
    ap.add_argument("out")
    for a in ("stock-jar", "asm-dir", "jdk-bin", "hook", "runtime", "supervisor", "sha-tool", "supervisor-sha"):
        ap.add_argument("--" + a, required=True)
    ap.add_argument("--test-jxe")
    ap.add_argument("--test-dio")
    o = ap.parse_args()

    sub = dict(STOCK)
    sub.update(TESTED)
    sub["NEW_SUP"] = o.supervisor_sha
    sub["VERSION"] = "v" + o.version
    checks = [(o.hook, "NEW_LIB"), (o.runtime, "NEW_RT"), (o.supervisor, "NEW_SUP"), (o.sha_tool, "SHA_TOOL")]
    for path, key in checks:
        if sha(path) != sub[key]:
            sys.exit("%s does not match %s" % (path, key))
    kit = os.path.join(PORT, "kit", "tt.sh")
    if b"\r" in open(kit, "rb").read():
        sys.exit("kit/tt.sh has CR line endings")
    sub["NEW_KIT"] = sha(kit)

    stage = tempfile.mkdtemp(prefix="tt-release-")
    root = os.path.join(stage, "tt-cockpit-carplay-v" + o.version)
    tt = os.path.join(root, "mod", "tt")
    for d in ("payload", "pc/classes/gate", "pc/classes/tools", "export", "build", "user"):
        os.makedirs(os.path.join(tt, d))
    sd = os.path.join(HERE, "sd")

    def put(src, dst, text_sub=None, lf=True):
        if text_sub is not None:
            t = open(src, encoding="utf-8").read().replace("\r\n", "\n")
            with open(dst, "w", encoding="utf-8", newline="\n") as f:
                f.write(fill(t, text_sub))
        else:
            shutil.copyfile(src, dst)

    put(os.path.join(sd, "mod", "custom.sh"), os.path.join(root, "mod", "custom.sh"), {})
    put(os.path.join(sd, "mod", "tt", "tt-setup.sh"), os.path.join(tt, "tt-setup.sh"), sub)
    put(os.path.join(sd, "mod", "tt", "pc", "build.py"), os.path.join(tt, "pc", "build.py"), sub)
    for name in ("README.txt", "action.txt"):
        put(os.path.join(sd, "mod", "tt", name), os.path.join(tt, name), sub)
    put(os.path.join(sd, "mod", "tt", "user", "README.txt"), os.path.join(tt, "user", "README.txt"), sub)
    for src, name in ((o.hook, "libaltscreen111.so"), (o.runtime, "cluster_runtime"),
                      (o.supervisor, "cluster_supervisor.sh"), (o.sha_tool, "altscreen-sha256"), (kit, "tt.sh")):
        shutil.copyfile(src, os.path.join(tt, "payload", name))
    for name in ("LICENSE", "NOTICE"):
        shutil.copyfile(os.path.join(PORT, "..", "..", name), os.path.join(root, name))
    commit = subprocess.run(["git", "rev-parse", "HEAD"], cwd=PORT, capture_output=True, text=True).stdout.strip()
    with open(os.path.join(root, "SOURCE.txt"), "w", newline="\n") as f:
        f.write("Source code: https://github.com/Tristar10/audi-tt-8s-altscreen\nCommit: %s\nLicence: GPL-3.0\n" % commit)

    # our HMI classes (compiled against the stock jar only for type checking; no stock class is kept)
    print("compiling HMI classes")
    jbin = o.jdk_bin
    src = os.path.join(PORT, "hmi", "src")
    srcs = [os.path.relpath(os.path.join(r, f), src) for r, _, fs in os.walk(src) for f in fs if f.endswith(".java")]
    run([os.path.join(jbin, "javac"), "-nowarn", "--release", "8", "-encoding", "UTF-8", "-cp", o.stock_jar,
         "-d", os.path.join(tt, "pc", "classes", "gate")] + srcs, cwd=src)
    asm = [os.path.join(o.asm_dir, n) for n in ("asm-9.7.jar", "asm-tree-9.7.jar", "asm-analysis-9.7.jar", "asm-util-9.7.jar")]
    tools = os.path.join(PORT, "hmi", "tools")
    run([os.path.join(jbin, "javac"), "-nowarn", "--release", "11", "-cp", os.pathsep.join(asm),
         "-d", os.path.join(tt, "pc", "classes", "tools"),
         os.path.join(tools, "PatchZoom.java"), os.path.join(tools, "VerifyZoom.java")])

    if o.test_jxe:
        print("end-to-end test of the PC builder")
        t = tempfile.mkdtemp(prefix="tt-e2e-")
        copy = os.path.join(t, "r")
        shutil.copytree(root, copy)
        shutil.copyfile(o.test_jxe, os.path.join(copy, "mod", "tt", "export", "lsd.jxe"))
        shutil.copyfile(o.test_dio, os.path.join(copy, "mod", "tt", "export", "dio_manager"))
        env = dict(os.environ)
        env["PATH"] = jbin + os.pathsep + env.get("PATH", "")
        run([sys.executable, os.path.join(copy, "mod", "tt", "pc", "build.py")], env=env)
        for f, key in (("tt-zoom.jar", "NEW_JAR"), ("dio_manager", "NEW_DIO")):
            if sha(os.path.join(copy, "mod", "tt", "build", f)) != sub[key]:
                sys.exit("end-to-end: %s does not match" % f)
        shutil.rmtree(t, ignore_errors=True)
        print("end-to-end OK")

    os.makedirs(o.out, exist_ok=True)
    zpath = os.path.join(o.out, "tt-cockpit-carplay-v%s.zip" % o.version)
    names = sorted(os.path.relpath(os.path.join(r, f), stage).replace(os.sep, "/")
                   for r, _, fs in os.walk(stage) for f in fs)
    dirs = sorted(set(os.path.relpath(r, stage).replace(os.sep, "/") + "/" for r, _, _ in os.walk(stage)) - {"./"})
    with zipfile.ZipFile(zpath, "w", zipfile.ZIP_DEFLATED) as z:
        for d in dirs:
            z.writestr(zipfile.ZipInfo(d, (2026, 1, 1, 0, 0, 0)), b"")
        for n in names:
            zi = zipfile.ZipInfo(n, (2026, 1, 1, 0, 0, 0))
            zi.compress_type = zipfile.ZIP_DEFLATED
            zi.external_attr = (0o755 if n.endswith((".sh", ".py")) else 0o644) << 16
            z.writestr(zi, open(os.path.join(stage, *n.split("/")), "rb").read())
    shutil.rmtree(stage, ignore_errors=True)
    print("built %s  sha256 %s" % (zpath, sha(zpath)))


if __name__ == "__main__":
    main()
