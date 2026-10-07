# Triggve Project Rules

Triggve — a REAPER JSFX drum trigger.

## Goal
Build a REAPER JSFX audio-to-sample drum trigger for Linux.

1.0 is released and covers:
- Detect hits from incoming track audio or from MIDI note-ons.
- Play WAV samples from a small randomized round-robin pool (MIDI velocity zones on the MIDI path).
- Support overlapping sample voices with click-free release.
- Output never exceeds 0 dBFS and never pops.

Work after 1.0 is maintenance: small fixes and patch releases such as 1.0.1,
not new feature programs.

## Safety & Scope
- Work only within this repository.
- Never use sudo.
- Do not install packages, download external code, or push commits without explicit approval.
- Do not access secrets, private keys, or unrelated system files.

## Audio & DSP Rules
- Never perform file I/O, memory allocation, or expensive tasks in JSFX @sample.
- Keep detection, sample selection, and playback as separate components.
- Prefer simple, testable changes over complex single rewrites.

## Workflow
- Begin each task with a short plan and affected-file list.
- Do not edit files until the plan is approved.
- Make only the currently approved milestone.
- After edits, explain how to test in REAPER on Linux.
- Report changed files, tests performed, limitations, and next steps.
- Do not create commits unless explicitly asked.
