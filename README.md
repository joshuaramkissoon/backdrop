# Backdrop

A menu bar app for macOS that turns your desktop into a slow, blurred gradient for screen recordings. It covers your desktop icons and widgets, sits behind every window and lets clicks pass straight through.

- 8 palettes with live previews, or Cycle to drift between the light ones
- Motion speed, film grain (stops banding once the video is compressed), hide the Dock while on
- Use as wallpaper: keeps your real desktop picture, on every Space, set to a still of the palette, so the menu bar, lock screen and Mission Control match. Leave the moving backdrop off for just the still (kind to a laptop battery), or on for the full effect
- One click to hide every app except the one you're recording, and bring them all back after

## Install

Needs macOS 14+ and the Xcode command line tools.

```sh
git clone https://github.com/joshuaramkissoon/backdrop.git
cd backdrop
./build.sh
```

This builds the app, installs it in `/Applications` and opens it. Look for the half-filled circle in the menu bar.
