# ember

Joshua Tree at dusk on Halloween.

This is my config repo. This is not a theme that I'm offering to manage for users, but on the other hand I didn't fail kindergarten either.
(i.e. I'm happy to share in case anyone else needs a refresh for their eyeballs or some light install help but I'm hoping not to get sucked in to this.)

The selection is intentionally tight - and changes as my stack changes. I'd suggest forking for your own security.

## Font

IBM Plex Mono

Here are step-by-step instructions to manually install the BlexMono Nerd Font (a patched version of IBM Plex Mono) on major operating systems by downloading the ZIP archive from the official Nerd Fonts site and installing the TTF files directly, without using package managers like Homebrew, apt, or pacman. [NerdFont GitHub](https://github.com/ryanoasis/nerd-fonts)

Download the [BlexMono ZIP](https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/IBMPlexMono.zip).

### Linux

- Create a fonts directory if needed: `mkdir -p ~/.local/share/fonts`.
- Unzip the archive: `unzip 'BlexMono.zip' -d ~/.local/share/fonts/`.
- Refresh the font cache: `fc-cache -fv`.
- Verify with `fc-list | grep "BlexMono"`.


### macOS

- Double-click the ZIP to extract it.
- Open Font Book (built-in app).
- Select all `.ttf` files in the extracted folder, then drag them into Font Book or use File > Add Fonts.
- Click Install if prompted (installs for current user).


### Windows

- Right-click the ZIP and extract all files to a folder.
- Select all `.ttf` files (Ctrl+A).
- Right-click the selection and choose "Install" (or "Install for all users" as admin).
- No restart needed; fonts appear immediately in apps like Windows Terminal.

## Terminal

Download [ember.terminal](https://github.com/jasenc7/ember/blob/main/terminal/Ember.terminal) and import it as a Theme in Terminal.app. Set it as default. Set font to BlexMono and increase font size to 14.

## Prompt

[starship](https://starship.rs/guide/#%F0%9F%9A%80-installation)

Once you're done with that copy [starship.toml](https://github.com/jasenc7/ember/blob/main/starship/starship.toml) to `~/.config/starship.toml`.

## Ghostty

[👻 Ghostty](https://ghostty.org/)

Copy [ghostty/config.full](https://github.com/jasenc7/ember/blob/main/ghostty/config.full) and put it in your Ghostty settings.

## FireFox

[FireFox](https://www.firefox.com)

Download [firefox/ember-0.2.0-mozilla-signed.xpi](https://github.com/jasenc7/ember/blob/main/firefox/ember-0.2.0-mozilla-signed.xpi). Open FireFox > shift+cmd+A > click the gear > Install Add on From File > import the thing you just downloaded.

## Zed

[Zed](https://zed.dev/)

Copy [zed/ember.json](https://github.com/jasenc7/ember/blob/main/zed/ember.json) and put it in `~/.config/zed/themes/ember.json`. Open Zed > cmd+k > cmd+t > "Ember".

## btop

[btop](https://github.com/aristocratos/btop)

Copy [btop/ember.json](https://github.com/jasenc7/ember/blob/main/btop/ember.theme) and put it in `~/.config/btop/themes/ember.json`. Open btop > m > enter > left/right until you find TTY or Ember - check both and land on whichever you like more.

## bone.css

[bone.css](https://github.com/jasenc7/ember/blob/main/bone.css) is a classless CSS base that makes unstyled HTML look clean out of the box. It pulls IBM Plex Mono through Google Fonts. Drop it in and you're done — no classes, no configuration.

## Generating themes

The palette lives in [palette.toml](https://github.com/jasenc7/ember/blob/main/palette.toml). If you want to riff on the colors and regenerate all the theme files from scratch:

```sh
# Requires Xcode Command Line Tools
# xcode-select --install

make build
```

[generate.swift](https://github.com/jasenc7/ember/blob/main/generate.swift) reads `palette.toml` and writes out the config files for each tool in the repo. Edit the palette, run `make`, done.
