TT cockpit CarPlay @@VERSION@@ - Apple/Google Maps on the Audi TT 8S Virtual Cockpit
Head unit MHI2_US_AU43x_P5180 / MU1462 only. Free software (GPL-3.0); if you paid for
this, you were scammed. Full guide: https://github.com/Tristar10/audi-tt-8s-altscreen

You need: the M.I.B. (More Incredible Bash) SD card, a computer with Python 3.8+ and
Java 11+, a parked car with the engine running or a charger on the battery.

Every step: write the step's name into mod/tt/action.txt, put the card in the car,
M.I.B. -> Advanced Settings -> Run Custom Script. The output is also saved in
mod/tt/last-run.txt. Nothing restarts by itself.

 1. check     Is your car supported? Read-only.
 2. export    Copies two files from your head unit to mod/tt/export/ (read-only).
 3. On your computer:  python3 mod/tt/pc/build.py   (Windows: py mod\tt\pc\build.py)
              Builds mod/tt/build/ from those files and checks it matches the tested build.
 4. Optional: chefranov's librgd_hook.so v1.1.10 into mod/tt/user/ for the turn-by-turn panel.
 5. install   Unplug the phone first. Backs up and installs. Then restart the MMI (hold the knob).
 6. restore   Puts every changed file back, then restart the MMI.
    logs      Saves logs to mod/tt/logs/ for a bug report.
