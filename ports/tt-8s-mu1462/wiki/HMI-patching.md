# HMI patching (tt-zoom.jar)

[Home](Home.md)

The jar goes into `/mnt/app/eso/hmi/lsd/jars/`, which the HMI puts ahead of
`lsd.jxe`, so classes in it override stock ones. Nothing stock on flash is
replaced; removing the jar restores stock behaviour.

## How

Stock classes come from `lsd.jxe` converted with jxe2jar. They are patched with
ASM (`hmi/tools/PatchZoom.java`: small hooks at method starts or around single
calls) and rewritten to class version 46.

## What survives on the car

| Override | Result |
|---|---|
| CombiBAPListener, AbstractGUI, DisplayManagerEvo, DSICarTimeUnitsLanguageManager, AnimationMIB2HighSport, ClusterService, ClusterViewMode, KOMOService (small, version 46) | Work |
| `map/Context` (version 49, 57 KB) together with `map/instances/MapMain` | Navigation stuck at 11 % on start-up; removing the jar recovered it |

Lesson: ASM verification does not prove a converted class runs on J9. Add one
override at a time.

## Rules for our own classes

Enforced by PatchZoom and `checklib.py`:

- Java 1.4 class library only: StringBuffer (no StringBuilder), no autoboxing, no generics.
- No string `+` concatenation: it compiles to StringBuilder.
- No class literals: `Foo.class` needs version 49.
- No anonymous or inner classes that capture variables (synthetic members).
- Every `java.*` call must exist in the car's library. Example caught by the
  check: `StringBuffer.insert(int, CharSequence)`.
- An HMI class dump from a newer build differs from the car (no
  `HMITerminal.getEventDispatcher`, no `EALManager.getFontLoader` on MU1462).
  Check every API against your own converted `lsd.jxe`.
