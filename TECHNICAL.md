# Triggve — technical reference

Companion to the [README](README.md). Everything below is the detail behind the
plugin: the controls, how detection and triggering work, how samples get loaded
and stored, and what is known to misbehave.

## Requirements

- **REAPER 6.29 or newer.** Samples are resampled to the project rate with a JSFX
  file feature added in 6.29. Any current REAPER 7 build is fine.
- Linux is the primary target; the plugin itself is plain JSFX and also runs on
  macOS and Windows.
- The folder loader is a Lua ReaScript using only REAPER's bundled Lua and native
  API — no ReaPack, no SWS.

## Controls

All eleven controls are drawn in the plugin's own window, two per row (the
dropdowns sit at the bottom). They are hidden REAPER parameters, so they remain
automatable and are stored with the project. The panel is **source-aware**: Audio
shows the detector faders, MIDI shows the MIDI controls, and only the controls
that actually do something for the current **Trigger Source** are displayed.
Hidden controls keep their values and stay automatable. Drag a control to set it,
or hover it and use the mouse wheel (hold **Shift** for coarser steps).

| # | Control | Default | Range | Summary |
|---|---------|---------|-------|---------|
| 1 | Threshold (dB) | −18 | −60 … 0 | How loud a hit must be to trigger (Audio source only). |
| 2 | Envelope Attack (ms) | 0.3 | 0.1 … 50 | How quickly the detector reacts to a rising hit. |
| 3 | Envelope Release (ms) | 5 | 1 … 45 | How quickly the detector lets go after a hit (also sets re-arm speed). |
| 4 | Retrigger Holdoff (ms) | 20 | 1 … 100 | Minimum time between two triggers. |
| 5 | Hysteresis (dB) | 6 | 0 … 24 | How far the signal must drop before the detector can fire again. |
| 6 | Mix | 1.0 | 0 … 1 | Blend of dry input vs. triggered samples. |
| 7 | Dynamic Velocity | On | Off / On | Gain follows hit strength (audio peak / MIDI velocity). Off = samples play at their original volume. |
| 8 | Sample Selection | Random | Single / Round-robin / Random | Which loaded slot plays next within the chosen zone/bank. |
| 9 | Output Gain (dB) | 0 | −24 … +24 | Makeup gain for the triggered samples. |
| 13 | Trigger Source | MIDI | Audio / MIDI | What fires the samples: the audio detector or incoming MIDI note-ons. |
| 15 | MIDI Passthrough | On | Off / On | On: notes continue downstream. Off: notes Triggve consumes are swallowed. |

Two further hidden parameters exist for the folder loader (a request counter and
a row number, see [How loading is wired](#how-loading-is-wired)). They are
plumbing, not controls, and are stored with the project like everything else.

## Slot and zone layout

32 slots, drawn as four rows of eight. In MIDI mode each row is a velocity zone;
in Audio mode the first row is the **Hits** bank and the other rows are hidden —
they keep their samples, but Audio triggering never reaches into them.

Each slot holds up to **4 seconds of stereo** at the project rate. A longer file
is trimmed when it is loaded.

## How the detector works (Audio source)

The plugin follows the input with an **envelope**: it rises quickly (Attack) when
a hit arrives and falls slowly (Release) when it ends. A trigger fires
**immediately** when the envelope crosses the **Threshold**. After firing, the
detector is "disarmed" and only re-arms once the envelope falls below *Threshold
minus Hysteresis*; the **Holdoff** also enforces a minimum gap between triggers.
Release and Hysteresis together control how fast the next hit can be detected.
Audio hits play from the single 8-slot **Hits** bank (slots 1–8).

## How MIDI triggering works (MIDI source)

MIDI is drained once per block in `@block` and queued; each note-on is fired
inside `@sample` at its **exact sample offset**, so timing is sample-accurate
regardless of the audio block size. Note-ons with velocity 0 are note-offs and are
ignored. The note's **velocity picks the zone** — this is exact, unlike audio peak
classification:

- **Low** — velocity 1–40.
- **Medium** — velocity 41–89.
- **Hard** — velocity 90–126.
- **Rimshot** — velocity 127 (a dedicated top-velocity articulation).

A sample is then chosen **within that zone** using the Sample Selection mode; an
empty zone falls back to the nearest loaded one. **Dynamic Velocity** decides
whether gain also follows velocity (`vel / 127`) or every voice plays at full
level — zone selection itself always applies. Note-ons on **any** MIDI channel
trigger; with **MIDI Passthrough** On (default) the notes keep flowing
downstream, e.g. to a soft synth later in the chain.

## Sample selection

- **Single** — the first loaded slot in the zone.
- **Round-robin** — cycles through the loaded slots in order.
- **Random** — random, but never the same slot twice in a row.

Selection only ever looks inside the chosen zone, except that an empty zone falls
back to the nearest loaded zone so a hit is never dropped.

## Audio engine

- A **96-voice** pool. Voices read straight out of the slot's sample buffer rather
  than copying it, so 32 slots hold the kit and the voice count only limits
  polyphony. When the pool is full the oldest voice is stolen — faded, not cut.
- A **32-voice release pool**: a voice that gets stolen, or whose slot is unloaded
  or re-loaded while it is still playing, hands off to a tail and ramps to silence
  over ~4 ms. Nothing is ever cut mid-sample, which is what keeps unloading and
  reloading click-free.
- A voice snapshots its slot's length and channel count at trigger time, so
  reloading a slot underneath a playing voice cannot stretch or misread it.
- Voice gain is seeded from the trigger amplitude and, on the audio path, refined
  for ~25 ms from the incoming signal; on the MIDI path it is frozen, because
  velocity is already exact.
- The output is the summed voices through **Output Gain** and **Mix**, plus the
  dry signal, into a **soft-clip ceiling**: transparent below −1 dBFS, saturating
  above it. The output can therefore never exceed 0 dBFS, and the ceiling is
  smooth enough not to click.
- Detection, slot selection and playback are deliberately separate stages, and
  `@sample` does no file I/O, allocation or heavy work.

Memory: `options:maxmem=120000000` — about 1.5 MB per slot at 48 kHz stereo
(4 s), roughly 49 MB for a full 32-slot kit.

## How loading is wired

JSFX cannot open a file dialog, cannot list a directory, and cannot write a file
outside its own project state. So the two halves are split:

- **The plugin** draws the `Load` buttons, owns the slots, decodes and resamples
  audio, and reads the answer.
- **[scripts/Triggve_Load.lua](scripts/Triggve_Load.lua)** shows REAPER's native
  file picker, lists the folder and writes the answer.

The handshake:

1. Pressing `Load` increments a hidden **Load request** counter and stores the
   clicked row in a hidden **Load zone** parameter, then notifies the host.
2. The script polls every 0.25 s over the track FX chains **and** the master
   chain. It recognises Triggve instances by those two parameter *names*, so old
   builds without the buttons and renamed instances are handled correctly. A
   parameter cache is invalidated by a cheap fingerprint of the FX layout.
3. The script opens `GetUserFileNameForRead` — REAPER has no folder-only dialog,
   so the user picks any file and the folder is taken from it — filters the folder
   to WAV/OGG/FLAC, sorts by name and takes the first eight.
4. It writes `<resource path>/Data/triggve_load.txt`: the request id, the row,
   then up to eight absolute paths.
5. The plugin polls that file from `@gfx` (never from `@sample`), a few times a
   second, and applies it: fade out any voice in the affected slots, store the
   path, decode and resample into the slot buffer — the same path drag & drop
   uses. Slots the folder could not fill are cleared.

The request id is what makes this safe. A hand-off is only applied by the instance
whose counter matches, and only once — `load_done` is saved with the project.
Cancelling the picker writes nothing, and a hand-off file left on disk can never
refill a row later or on another machine.

The script starts with REAPER through `Scripts/__startup.lua` (REAPER's native
startup hook) and refuses to start a second time in the same session, so a click
never asks twice.

## What a project stores

The project stores **paths, not audio**: the `@serialize` payload is 32 absolute
sample paths plus the last applied request id, alongside all parameter values.
When a project opens, each path is re-read and decoded into the plugin's own
memory at the current project rate.

| Situation | What happens |
|-----------|--------------|
| Sample files are where they were | Loads exactly as before |
| Folder moved, renamed, different user, drive unmounted | Those slots show `load error` and stay silent; everything else keeps working |
| Machine runs a different project sample rate | Samples are re-decoded and resampled at load; nothing to do |

- There is **no filename search**: paths are absolute. Relinking is `Load` on the
  affected row, pointing at the kit folder again.
- Files longer than 4 s were already trimmed when they were loaded, so trimming is
  not re-applied differently on another machine.
- `Data/triggve_load.txt` is a transient channel, not storage. Deleting it is
  always safe.

## Known Limitations

- **On Wayland, drag & drop can break outside the plugin's control.** REAPER is an
  XWayland client on Linux, and **GNOME 51 / mutter 51** shipped a Wayland→XWayland
  drag-and-drop regression (Ubuntu LP #2168597) that was fixed upstream in October
  2026. On an affected system drops fail into *any* REAPER window — the arrange
  view included — not just Triggve. This is why every row has a **Load** button: it
  goes through REAPER's own dialog instead of the desktop's drag-and-drop bridge.
  Failing that, load samples via REAPER's **Media Explorer**, or drag from an
  **X11** file manager (e.g. `GDK_BACKEND=x11 nautilus`, or Dolphin).
- **The `Load` button needs the helper script running.** REAPER does the folder
  dialog and directory listing for the plugin, so the plugin alone cannot fill a
  row — `install.sh` (or the manual install) arranges for the script to start at
  launch. Without it, clicking `Load` does nothing beyond the `no folder received`
  note in the status line.
- **The `Load` button needs room.** It is drawn only when a row is about 80 px
  tall or more, so a very short plugin window hides it. Widen the window.
- **Item and take FX are not scanned by the loader.** Track chains and the master
  chain are; a Triggve instance on an item will not respond to `Load` (drag & drop
  still works there).
- **WAV is the guaranteed format.** `.ogg` and `.flac` are accepted by the loader
  and decoded by REAPER's own decoder behind `file_riff`; if a build cannot decode
  one, the slot shows `load error`.
- **No append mode for folders.** `Load` makes a row hold exactly the picked
  folder's first eight files; use drag & drop to edit one slot at a time.
- **MIDI timing is sample-accurate within an audio block.** Notes are fired at
  their exact offset inside the block they arrive in, so the worst-case delay is
  one block — smaller blocks, tighter timing.

## Source layout

| File | Role |
|------|------|
| [Triggve.jsfx](Triggve.jsfx) | Everything: `@init` state and helper functions, `@slider`, `@block` MIDI queue, `@sample` detector + selection + mixing, `@gfx` panel, grid, loading, `@serialize` persistence |
| [scripts/Triggve_Load.lua](scripts/Triggve_Load.lua) | Folder loader script (dialog, directory listing, hand-off file) |
| [install.sh](install.sh) | Installs both and registers the loader as a startup script |

Slider numbers 10–12 and 14 are left unallocated on purpose: development builds
used them for features that were later removed, and keeping them empty means
values saved by those projects can never shift into a different control.
