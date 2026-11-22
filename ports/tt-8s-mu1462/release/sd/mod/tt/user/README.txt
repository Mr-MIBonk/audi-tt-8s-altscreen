librgd_hook.so goes here: chefranov's route-guidance hook v1.1.10, for the turn-by-turn panel.

The PC builder (mod/tt/pc/build.py) fetches it for you from chefranov's official release
https://github.com/chefranov/mhi2-au37x-carplay/releases/tag/v1.1.10 (the SD package
mhi2-au37x-carplay-v1.1.10-sd.zip), checks it and puts it here. His licence allows free use
but not redistribution of single files, so it is not in this zip. Without internet: download
that package yourself and run  python3 mod/tt/pc/build.py --rgd-zip <that zip>.
The installer accepts only that exact file: SHA-256 @@RGD_HOOK@@

Without it (build.py --no-rgd, or delete the file) you get the CarPlay map in the cockpit,
but no turn panel.
