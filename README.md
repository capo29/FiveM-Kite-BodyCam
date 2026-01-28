# Axon Body Cam Script

<img width="281" height="116" alt="image" src="https://github.com/user-attachments/assets/af6f1b43-b9f9-4415-b3d7-34ed4632be67" />
(ignore the image lol)

FiveM bodycam script with auto-trigger support for police vehicles. Toggle it manually or let it auto-start when you hit the lights.

## Features

- Manual toggle via command or keybind (default: O)
- Auto-triggers when you activate sirens in a police vehicle
- Supports both Axon and Reveal bodycam models
- Live timestamp overlay that updates in real-time
- Audio feedback when toggling on/off
- Periodic beep sound every 2 minutes while recording (for immersion)
- Clean UI overlay that doesn't get in the way

## Installation

1. Drop the `bodycam` folder into your `resources` directory
2. Add `ensure bodycam` to your `server.cfg`
3. Restart your server or start the resource manually

That's it. Pretty straightforward.

## Configuration

Edit `config.lua` to customize:

```lua
Config.soundVolume = 0.05 
Config.Radius = 1.0         
Config.Model = 'axon'      
```

The sound volume is set low by default because honestly, the sound files are deafening. Adjust as needed.

## Usage

**Manual Toggle:**
- Press `O` (default keybind) or type `/bodycam` in chat
- Plays an animation when toggling
- Shows notification when turning on/off

**Auto-Trigger:**
- Get in a police vehicle (emergency class)
- Activate your sirens/lights
- Bodycam will automatically turn on after 2.5 seconds
- Only triggers once per session (won't spam if you toggle sirens repeatedly)

The auto-trigger is smart - it only fires when you go from sirens OFF to ON, and only if the bodycam isn't already running. Won't annoy you with constant toggles.

## Bodycam Models

**Axon:**
- Shows Axon logo and branding
- Timestamp format: `2020-09-29 T18:29:45`
- Serial number: `AXON BODY 2 X81020805`

**Reveal:**
- Minimalist design
- Timestamp format: `2020/10/09 17:44:32`
- Serial number: `249105`
- Positioned at bottom-right of screen

Switch between them in the config. Both look pretty good.

## Audio

The script plays sounds when toggling:
- `axon_in.ogg` / `reveal_in.ogg` when turning ON
- `axon_out.ogg` / `reveal_out.ogg` when turning OFF (if you add the file)

There's also a periodic beep every 2 minutes while recording. It's a proximity sound so nearby players can hear it too. Adds to the immersion.

## Dependencies

- FiveM server (obviously)
- No external dependencies required - everything is self-contained

The HTML uses Howler.js for audio, but it's loaded via CDN so no need to install anything.

## Notes

- The bodycam overlay shows a live timestamp that updates every 100ms
- Auto-trigger has a 2.5 second delay to prevent accidental activations
- The script checks if you're in an emergency vehicle class (18) for auto-trigger
- Animation uses the `clothingtie` anim dict (the tie adjustment animation)
