# Dead Frequency

> For thatgamecompany x COREBLAZER Game Jam 2025  
> **A Radio Management & Simulator Game with Procedural Worldbuilding**  
> _Every new game is unique_

---

## Table of Contents

- [Game Overview (GDD)](#game-overview-gdd)
- [Core Systems](#core-systems)
  - [Comms Panel](#comms-panel)
  - [Security Camera Feed](#security-camera-feed)
  - [Procedural Elements](#procedural-elements)
- [How to Handle Game Elements](#how-to-handle-game-elements)
  - [Transmissions & Signals](#transmissions--signals)
  - [The Threat: Entity](#the-threat-entity)
  - [Interrogation System](#interrogation-system)
- [References & Inspirations](#references--inspirations)

---

## Game Overview (GDD)

**Dead Frequency** is a procedural management & simulation game where you play as a radio communications operator in a post-apocalyptic world. A mysterious, evolving threat—_The Entity_—is wiping out what's left of humanity. Your job: receive radio transmissions, analyze and relay them to the right base, and outsmart the Entity, which adapts and sabotages each run differently.

- **Platform:** WebGL/PC
- **Engine:** Godot
- **Genre:** Management, Simulation
- **Jam Release Date:** June 8th, 2025

### Gameplay Pillars

- **No run is like any other:** The characteristics of the mysterious threat change with every new game, as well as all the characteristics of your allied forces. You have to get to discover them for the first time, every time.
- **An unseen hero:** You are meant to be the hero of the story, but you won’t meet your allies except through the comms panel. You have to receive, analyze, understand, categorize and forward comms messages to make sure that humanity survives this crisis. 
- **One screen challenge:** All gameplay occurs on a single interactive screen.
- **Trust no one:** The mysterious entity attacking humanity is known to be able to mimic humans in some ways, so every new piece of information, every strange situation happening in your home base, can be real, or it can be the entity, it’s up to you to discern it.

### Narrative

You are the sole radio operator in the central base of communications of the united military, what is left of humanity’s military as the whole world has been ravaged by an unknown threat called The Entity. Very little is known about the Entity, and you and your whole base are part of a regional effort made to identify the key characteristics of it and find its weaknesses, in hopes of eventually defeating it and saving the world. 

You mission is to be the center of communications for the whole operation: You are to receive allied transmissions, analyze its contents, and relay them to the appropriate recipient. You will receive data about the movements of the entity forces, weaknesses and strengths of them, allied casualty reports, emergency broadcasts, reinforcements requests, and more. Inside your base there’s also a soldier of the entity captured, the first one ever captured alive, and you are also in charge of its interrogation, where you can use diplomacy or torture to get additional information, while making sure it doesn’t escape. 

But be wary. There are reports that the entity and its forces are able to somehow mimic humans, so not every voice your hear though the radio might be who they claim to be. 

---

## Core Systems

### Comms Panel

- **IFF Data:** Helps identify if a transmission is human, civilian, or the Entity.
- **Signal Integrity:** Shows the quality of received signals (distance affects this).
- **Voice Modulation:** AI-assisted analysis for vocal stress or mimicry—displays as text.
- **Transponder Signature:** Scans for known/unknown/anomalous signal signatures.
- **Comm Modes:**
  - **Reply:** Toggle to reply on the active frequency.
  - **Listen:** Toggle to receive transmissions.
  - **Mic:** Toggle to send messages.
- **Frequency Diagnostics:**
  - **Error Rate:** Monitors corruption in signals.
  - **Latency:** Shows delay in message receipt.
  - **Active Signal:** Displays current 4-digit frequency.

### Security Camera Feed

- **Main Monitor + 4 Mini Feeds:** Observe three base areas, monitor soldiers’ behaviors (from routine to suspicious).
- **Feed Switching:** Click a mini-feed to enlarge it.
- **Surveillance:** Spot illegal or suspicious activities; discern possible Entity infiltrators.

### Procedural Elements

- Every run, both the Entity and allied forces have randomized traits.
- Threat behaviors, strengths, weaknesses, and comms change each playthrough.

---

## How to Handle Game Elements

### Transmissions & Signals

- **Receiving:** Always listen first; analyze IFF/Voice/Signature before replying.
- **Relaying:** Only relay after verifying authenticity and interpreting urgency.
- **Error Handling:** Use Frequency Diagnostics to judge if a message is compromised.

### The Threat: Entity

- **Mimicry:** Be skeptical—odd or inconsistent behavior may indicate the Entity.
- **Adaptation:** The Entity learns and adapts through your actions; expect evolving sabotage.

### Interrogation System

- **Captured Entity:** Use diplomacy or coercion to extract information.
- **Risk:** Aggressive tactics may escalate danger; balance interrogation methods.

---

## References & Inspirations

- [Radio Commander](https://store.steampowered.com/app/871530/Radio_Commander/)
- [Killer Frequency](https://store.steampowered.com/app/1686030/Killer_Frequency/)
- [Radio General](https://store.steampowered.com/app/1010130/Radio_General/)
