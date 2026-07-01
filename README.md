# DNR DJ Booth System For FiveM

# PLEASE NOTE DNR DEVELOPMENTS NOR NR DEVELOPMENTS ALLOW REDISTRIBNUTION OF ANY CODE INSIDE THIS RESOURCE HOWEVER YOU ARE FREE TO MODIFY TO YOUR OWNN LIKING.

A modern, fully configurable DJ Booth system for FiveM built with **ox_lib** and **XSound**. Players can stream music directly from supported URLs through an immersive in-game DJ interface with synchronized playback for everyone nearby.

---

## ✨ Features

- 🎵 Stream music directly from supported URLs
- 🎧 High-quality 3D positional audio
- 📻 Multiple independent DJ booths
- 🔒 Job restrictions per booth
- 👮 Admin override support
- 🎚️ Volume controls
- 📍 Configurable stream radius
- 🖥️ Clean modern NUI interface
- ⚡ Lightweight and optimized
- 🔄 Synced playback for all nearby players

## 📦 Requirements

This resource requires:
- ox_lib
- xsound

> **IMPORTANT**
>
> **The included version of `xsound` MUST be used with this resource.**
> **DjBooth must be started after the `xsound` resource i reccommend adding xsound to the standalone  folder.**
>
> This script was built and tested specifically with the included `xsound` resource. Using another version may cause playback issues, synchronization problems, or prevent audio from working correctly.

## Installation

```cfg
ensure ox_lib
ensure xsound
ensure dnr-djbooth
```

## Configuration

Edit `config.lua` to configure:

- DJ booth locations
- Labels
- Stream radius
- Volume
- Job restrictions
- Allowed URL domains
- Admin permissions

## How It Works

Players interact with a configured DJ booth to open the UI, paste a supported music URL, and start playback. Music is streamed using XSound with synchronized positional audio so everyone within range hears the same music.

Each DJ booth operates independently, allowing multiple booths to play different music simultaneously.

## Permissions

Booths can be public or restricted to specific jobs. Configurable admin groups may bypass these restrictions.

## Notes

- Optimized for OneSync.
- Multiple independent DJ booths supported.
- Large stream radii may increase network usage.
- **Always use the included `xsound` resource for full compatibility.**

## Credits

**Author:** NightRider - DNR-Developments / NR-Developments
**Special Thanks** To Xogy for creating xsound which makes this djbooth script possible.
**Link to Xogy/xsound Resource.** https://github.com/Xogy/xsound
