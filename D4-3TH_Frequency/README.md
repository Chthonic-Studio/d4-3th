# Code Structure

## Table of Contents
- [Code Structure](#code-structure)
  - [Global Scripts](#global-scripts)
- [Milestones and Timeline](#milestones-and-timeline)

## Code Structure

### Global Scripts

### GameManager
It handles core game state management, frequency-related operations, and communication between different game systems using signals. The script is designed to be a central hub for managing gameplay logic and shared data. Tracks: Game State Management, Frequency Management, Signal-Based Communications, Voice Modulation and Status Tracking. 

### TimeManager
Handles in-game time and dates.

### DialogueManager
Handles loading dialogue data, maintaining message histories, and managing active dialogues for different frequencies. It also provides tools for starting and tracking dialogues. Tracks: Dialogue Data Management, Message History Tracking, Active Dialogue Management, Frequency Specific Dialogue, Voice Modulation States. 




## Milestones and Timeline

### Milestone 1: Core Loop, Main Functions, and UI Systems  
**Dates:** May 17th – May 25th

**Goals:**
- Establish project structure in Godot.
- Implement all core gameplay systems in basic form:
  - Comms panel (all toggles, displays, and diagnostics).
  - Security camera feed system with main and mini-feeds.
  - Basic simulation of transmission and relay flow.
- Build UI layout for “one screen” gameplay.

**Tasks:**
- Set up Godot project and version control.
- Prototype comms panel: switches, bars, text outputs.
- Implement camera feed switching logic.
- Create placeholder art for UI and pixel art elements.
- Enable receiving, analyzing, and relaying radio messages (dummy data).
- Add basic procedural logic for threat/allied force randomization.

---

### Milestone 2: Polish, Procedural Content, and Audio  
**Dates:** May 26th – June 1st

**Goals:**
- Polish core gameplay and UI/UX.
- Expand procedural generation: threat traits, allied traits, message types.
- Integrate audio: sound effects and music.
- Add content variety (messages, events, camera scenes).
- (Stretch) Implement music radio station.

**Tasks:**
- Refine comms analysis systems (IFF, modulation, transponder signature).
- Add unique threat and ally characteristics per run.
- Implement and balance message/event pool.
- Integrate SFX for UI, transmissions, in-game actions.
- Add background music (and radio music if possible).
- Polish visuals with improved pixel art and photo edits.

---

### Milestone 3: Playtesting and Optimization  
**Dates:** June 2nd – June 7th

**Goals:**
- Playtest for bugs, balance, and fun factor.
- Optimize for WebGL (browser build).
- Finalize deployment pipeline for Itch.io.

**Tasks:**
- Internal playtesting sessions; gather feedback.
- Debug and fix gameplay/UI issues.
- Optimize assets and code for smooth WebGL performance.
- Prepare build scripts and deployment instructions.

---

### Milestone 4: Final Upload  
**Date:** June 8th

**Goals:**
- Package and upload the final build to Itch.io before deadline.

**Tasks:**
- Final review and checklist runthrough.
- Create Itch.io page (screenshots, description, tags).
- Upload WebGL build and any supporting files.
- Announce submission to team and on social channels (if applicable).



