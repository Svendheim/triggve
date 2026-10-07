# Changelog

All notable changes to **Triggve** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project uses a beta versioning scheme (`beta1`, `beta2`, … → `1.0`).

## [Unreleased]

### Added
- **MIDI triggering** — new **Trigger Source** control (Audio / MIDI, default **MIDI**). Note-ons are drained once per block in `@block` and fired inside `@sample` at their **exact sample offset**, so timing is sample-accurate at any audio block size. Note-ons with velocity 0 are treated as note-offs and never trigger.
- **MIDI velocity zones** — the four rows are now fixed zones driven by note velocity: **Low 1–40**, **Medium 41–89**, **Hard 90–126**, **Rimshot 127**. Empty zones fall back to the nearest loaded zone, so a hit is never dropped.
- **MIDI Channel filter** (**All** / 1–16): notes on non-matching channels never trigger and always pass through untouched.
- **MIDI Passthrough** toggle (default **On**). Off swallows the note-on/note-off messages Triggve consumes on the selected channel; every other event (CC, pitch bend, program change, other channels) still flows downstream.
- **Source-aware GUI** — MIDI mode shows the four zone rows and a `N/32` status; Audio mode shows a single 8-slot **Hits** bank and a `N/8` status.

### Changed
- **Audio triggers fire immediately at the threshold crossing.** The ~1 ms velocity-measurement window is gone: no more added latency per triggered voice, which removes the comb filtering against the dry input at Mix < 1. Voice gain still converges — the per-voice 25 ms peak tracker refines it *after* the voice has started.
- **Audio uses a single 8-slot bank** (slots 1–8). It never falls back into the MIDI zones, which are hidden in Audio mode.
- **Velocity layers removed from the audio path.** Hit-strength classification proved unreliable from audio peaks; it lives on exactly where velocity *is* exact — MIDI note velocity.
- **Dynamic Velocity now defaults to On** (it was Off in beta2, because layers carried the loudness). In MIDI mode gain = `velocity / 127`; in Audio mode it is the hit's peak. Zone/bank selection is unaffected by the toggle; set it Off to let your zone samples carry the loudness at original volume.
- UI rows: the three layer-boundary faders are replaced by **Trigger Source**, **MIDI Channel**, and **MIDI Passthrough** dropdowns.
- **Source-aware control panel** — the detector faders (Threshold / Attack / Release / Holdoff / Hysteresis) are hidden in MIDI mode, and **MIDI Channel** / **MIDI Passthrough** are hidden in Audio mode, so only live controls are shown. The parameters still exist and keep their values; switching source brings them back.

### Removed
- Velocity-layer boundary sliders (10–12) and dBFS boundary classification. Slider numbers 10–12 stay unallocated on purpose, so boundary values saved by beta2 projects cannot shift into the new MIDI controls.

## [beta2] — 2026-10-06

### Added
- **Velocity layers** — Ghost / Low / Medium / Hard, selected from each hit's measured peak.
- **32-slot sample pool** (4 layers × up to 8 slots), arranged in a layer-per-row grid.
- **Layer boundary sliders** (sliders 10–12) defining the dB offsets above Threshold where each layer begins, with fallback to the nearest loaded layer when a layer is empty.
- **Per-layer selection state** — Single / Round-robin / Random now cycle within the chosen layer, giving up to 8 samples per hit strength.
- **Deferred velocity measurement** — a short (~1 ms) window captures the true hit peak before the layer and sample are chosen.
- **Dynamic Velocity** toggle (off = samples play at their original volume).

### Changed
- **Dynamic Velocity** now defaults to **Off**, since velocity layers already carry loudness.
- Sample capacity raised from 8 to **32** slots; `maxmem` raised to 120M slots to cover high sample rates.
- GUI widened to a 4×8 layer grid with row labels showing each layer's velocity range.
- **Controls are now drawn in the plugin's own UI**, two per row, replacing REAPER's full-width slider strip (parameters are hidden with the `-` prefix and remain automatable). Numeric controls support drag and mouse wheel; the two dropdowns use REAPER's native popup menu.
- Renamed the internal `trigger` flag to `trig`. `trigger` is a reserved JSFX variable — using it made REAPER show its 10-button trigger panel and meant we were writing to a host-owned variable every sample.
- Dropped the in-canvas "Triggve" title; REAPER's FX title bar already names the plugin. The status strip moved up and the window is 50 px shorter overall.
- **Envelope Attack default lowered from 1 ms to 0.3 ms**, so the detector adds less lag between the dry hit and the triggered sample. Defaults only apply to freshly inserted instances — existing projects keep their saved value.

### Notes
- The velocity-measurement window is ~1 ms (`vel_window`). It is also the added latency per triggered sample, which colours the dry/wet sum at Mix < 1 (comb-filter nulls sit at odd multiples of `1 / (2 × window)`, so 8 ms landed them at 62/187/312 Hz and 1 ms pushes them to 500/1500/2500 Hz). Making the window adjustable or adaptive remains a beta3 candidate.

## [beta1] — 2026-10-05

First beta release. **Triggve** is a REAPER JSFX audio-to-sample drum trigger for Linux and cross-platform REAPER.

### Added
- **Real-time transient detector** with controls for Threshold, Envelope Attack, Envelope Release, Retrigger Holdoff, and Hysteresis.
- **8-slot sample pool** with drag & drop loading, plus unloading via right-click, a per-slot `x`, or **Clear All**.
- **Per-slot readout** (length, channels, sample rate); samples are resampled to the project rate and capped at 4 seconds.
- **Project persistence** of sample paths via `@serialize`, so loaded slots survive project reloads.
- **96-voice polyphonic playback** with oldest-voice stealing as a fallback.
- **Peak-accurate velocity** — each sample plays at the hit's peak level (measured over a short window), so triggered samples match the source loudness.
- **Selection modes** — Single (slot 1), Round-robin, and Random (no immediate repeat).
- **Output Gain** (−24 … +24 dB makeup) and a **soft-clip safety ceiling** so the output never exceeds 0 dBFS.
- **Wet/dry Mix** — a linear blend between the dry input and the triggered samples.
- **Click-free transport stop** via a short fade.
- **Custom GUI** — a readable slot grid showing loaded state and the last-played slot.

### Changed
- Defaults to **full replacement** (Mix = 1) rather than mixing the source back in.
- Velocity now uses the input **peak** instead of the threshold-crossing envelope value, fixing quiet playback.

### Removed
- Redundant **Sample Level** slider (use **Output Gain** instead).

### Pre-beta history
Development milestones before beta1: v0.1 (architecture), v0.2 (detection), v0.3 (sample loading + persistence), v0.31 (polyphonic playback, defaults), v0.4 (selection modes + GUI), v0.4.1 (safety ceiling + anti-click stop), v0.5 (peak velocity, Output Gain, wet/dry Mix, 96 voices).

[beta2]: #beta2--2026-10-06
[beta1]: #beta1--2026-10-05
