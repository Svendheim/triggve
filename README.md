<p align="center">
  <img src="triggve-logo.jpeg" alt="Triggve logo" width="420">
</p>

A lightweight, 100% vibecoded low-latency REAPER JSFX drum replacement and sample
triggering plugin for Linux and cross-platform REAPER environments. Current
version: **1.0**.

Triggve turns drum hits into samples. Trigger from **audio transients** or from
**MIDI note-ons**, load one folder per articulation, and play up to 32 samples
with overlapping, click-free voices. By default the dry input is replaced
(**Mix** = 1), so it acts as a full drum replacement.

<p align="center">
  <img src="triggve-gui.png" alt="Triggve plugin window, MIDI mode, four loaded velocity zones" width="720">
</p>

The controls reference, detector and MIDI behaviour, what gets saved in a project,
and the known limitations live in **[TECHNICAL.md](TECHNICAL.md)**.

## Installation

REAPER **6.29 or newer** (any current REAPER 7 build is fine).

```bash
git clone https://github.com/svendheim/triggve.git
cd triggve && ./install.sh
```

Then **restart REAPER**. That is the whole installation: `install.sh` copies the
plugin and its folder loader into REAPER's resource path and makes REAPER start
the loader at launch — the loader is what the plugin's **Load** buttons talk to.
It finds your resource path by itself, and running it again is harmless.

To check it worked: add **JS: Triggve** to a track, open it and press `Load` on a
row. REAPER's file picker opening is the proof.

**Upgrading** is the same command:

```bash
cd triggve && git pull && ./install.sh
```

Portable install, or Windows? Tell the script where REAPER keeps its settings
(Windows is usually `%APPDATA%\REAPER`):

```bash
REAPER_DIR="$HOME/portable/REAPER" ./install.sh
```

### Manual install

Find your resource path in REAPER under **Options → Show REAPER resource path**,
then copy `Triggve.jsfx` to `<resource path>/Effects/Triggve/` and
`scripts/Triggve_Load.lua` to `<resource path>/Scripts/`. For the `Load` buttons
to work, also add this one line to
`<resource path>/Scripts/__startup.lua`, creating the file if you don't have one:

```lua
dofile(reaper.GetResourcePath() .. "/Scripts/Triggve_Load.lua")
```

Without it the plugin still works, but only through drag & drop.

### Uninstall

Delete `<resource path>/Effects/Triggve/` and
`<resource path>/Scripts/Triggve_Load.lua`, and remove the line marked
`Triggve folder loader` from `<resource path>/Scripts/__startup.lua`.

## Using Triggve

1. Add **JS: Triggve** to the drum track (or to a track fed by your pad
   controller / MIDI drum source).
2. Set **Trigger Source** to **MIDI** (notes trigger samples) or **Audio** (hits
   on the incoming audio trigger samples).
3. Press **Load** on a row and pick the folder for that articulation. The row
   fills itself.
4. Play. A loaded slot is tinted green with a green dot, the row of the last
   trigger is highlighted, and the status line counts hits and active voices.

**MIDI velocity picks the row.** These ranges are fixed, so they are the ones to
aim for when recording or quantising velocities:

| Row | MIDI velocity | Use it for |
|-----|---------------|------------|
| Low | 1–40 | light hits, ghosts |
| Medium | 41–89 | everyday playing |
| Hard | 90–126 | accents |
| Rimshot | 127 | your hardest articulation |

In **Audio** mode there is one row, the **Hits** bank: every detected hit plays
from it, and the detector controls appear instead of the MIDI ones.

### Loading samples

Press **`Load`** on a row, then pick *any* file from the folder you want — REAPER
opens its own picker, so nothing depends on desktop drag & drop. The folder's
**first 8** WAV / OGG / FLAC files, in name order, become that row. Files past
the eighth are ignored, and any slot the folder cannot fill is emptied, so a row
always holds exactly what you pointed at. A kit is four clicks: one folder per
articulation.

- **Drag & drop** still works for a single slot, or several files onto the grid.
- **Unload** one slot with its `x` (or right-click it); **Clear All** empties
  everything.
- Loading while it plays is safe: any voice in the way fades out first.
- `choose a folder ...` in the status line means the picker is open.
  `no folder received` means nothing came back, usually because the loader is not
  running — see Installation.

### Getting it to sound right

| Want | Change |
|------|--------|
| Keep some of the original drum in the mix | lower **Mix** |
| Samples louder or quieter | **Output Gain (dB)** |
| Volume to follow how hard you hit (or MIDI velocity) | **Dynamic Velocity** |
| Always the same sample | **Sample Selection → Single** |
| Alternating samples for repeated hits | **Sample Selection → Round-robin** |
| No obvious repetition | **Sample Selection → Random** |
| Detect fewer ghost hits from audio | raise **Threshold**, raise **Retrigger Holdoff** |
| Let the MIDI notes carry on to a synth as well | keep **MIDI Passthrough** on |

The status line at the top shows how many slots are loaded, how many hits have
triggered, how many voices are playing, and which slot last fired.

### Saving and moving a project

A project stores the **paths** to your samples, not the audio. Reopening the
project re-reads those files, so keep the kit where it was: move or rename the
folder and those slots show `load error` (they stay silent, the rest keep
working). Fix it by pressing `Load` on the affected rows again. Same goes for
opening a project on another machine — details in
[TECHNICAL.md](TECHNICAL.md#what-a-project-stores).

## License

Released under the [MIT License](LICENSE).
