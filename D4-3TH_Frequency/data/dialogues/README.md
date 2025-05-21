# Dialogue JSON Format Guide

This file defines dialogue trees for the `DialogueManager` system.  
Each dialogue is a branching structure, supporting flags, conditions, audio, and flexible reply options.

---

## Top-Level Structure
```json
{
  "dialogues": [
    {
      "id": "unique_dialogue_id", // REQUIRED: Unique identifier for the dialogue tree
      "tree": { ... }             // REQUIRED: Dialogue nodes
    }
    // More dialogues...
  ]
}

## Dialogue Nodes (tree)
Each key in tree is a node ID (e.g., start, branch1, end).
A node can have the following fields:

- `message`: (string, REQUIRED) The text displayed by the sender (word-by-word effect for non-player).
- `sender`: (string, REQUIRED) Who is sending the message. Use "operator", "player", or a string.
- `voice_modulation`: (string, OPTIONAL) Voice modulation enum ("Normal", "Hostile", "Distressed", ...).
- `audio`: (string, OPTIONAL) Path to audio/voice for this message.
- `bg_audio`: (string, OPTIONAL) Path to background noise/music for this branch (usually set at start node).
- `date`: (null or string, IGNORED) Will be set at runtime.
- `conditions`: (array of strings, OPTIONAL) List of flags/vars required for this node to be active. Use "not_flagname" for negation (e.g., "not_radio_contact").
- `replies`: (array of objects, OPTIONAL) Choices for the player, or [] for end.

**Reply Options**
Each reply option can have:

- `text`: (string, REQUIRED) Text shown on the reply button.
- `next`: (string, REQUIRED) ID of the next node.
- `set_flags`: (array of strings, OPTIONAL) Flags/variables to set when chosen.
- `conditions`: (array of strings, OPTIONAL) List of flags required for this reply to be shown.
- `audio`: (string, OPTIONAL) SFX/audio when reply is chosen.
- `play_voice`: (string, OPTIONAL) Path to voice audio to play on click.
- `play_bg_audio`: (string, OPTIONAL) Path to background noise/music for this reply branch.
- `end_dialogue`: (bool, OPTIONAL) If true, ends the dialogue after this reply.
- `custom_event`: (string, OPTIONAL) EventManager event key to trigger on reply.
- `custom_payload`: (object, OPTIONAL) Data to send to custom event.
(Extend with other fields as needed.)

--------------------
### EXAMPLE DIALOGUE TREE
--------------------
{
  "dialogues": [
    {
      "id": "example_dialogue",
      "tree": {
        "start": {
          "message": "Hello, how can I help you?",
          "sender": "operator",
          "replies": [
            {
              "text": "I need assistance.",
              "next": "help",
              "set_flags": ["asked_for_help"]
            },
            {
              "text": "Never mind.",
              "next": "end",
              "end_dialogue": true
            }
          ]
        },
        "help": {
          "message": "Sure, what do you need help with?",
          "sender": "operator",
          "replies": [
            {
              "text": "Technical support.",
              "next": "tech_support"
            },
            {
              "text": "Billing issues.",
              "next": "billing"
            }
          ]
        },
        "end": {
          "message": "Goodbye!",
          "sender": "operator"
        }
      }
    }
  ]
}