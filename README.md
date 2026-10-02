# ember

Joshua Tree at dusk on Halloween.

This is my config repo. This is not a theme that I'm offering to manage for users, but on the other hand I didn't fail kindergarten either.
(i.e. I'm happy to share in case anyone else needs a refresh for their eyeballs or some light install help but I'm hoping not to get sucked in to this.)

The selection is intentionally tight - and changes as my stack changes. I'd suggest forking for your own security.

## Font

BlexMono Nerd Font. It is installed on the systems this personal configuration targets; other systems fall back to their local monospace stack where the format permits one.

The Windows installer can put down Maple Mono NF or CommitMono Nerd Font instead — see below. That
choice only affects Windows Terminal. The font baked into the generated theme files still comes from
`palette.toml`, so changing it everywhere means editing the palette and re-running `make build` on a
machine with Swift.

## Windows

Everything above is written for macOS. On Windows, run the installer instead:

```powershell
pwsh -File windows/Install-Ember.ps1
```

It installs a patched Nerd Font for the current user, adds the Ember scheme to Windows Terminal and
applies it to every profile, drops `starship.toml` into `~/.config`, and installs the Zed theme.
Windows Terminal settings are backed up before the first change, and the script is safe to re-run —
a run that would change nothing leaves the file alone.

Useful flags:

| Flag | Effect |
| --- | --- |
| `-Font MapleMono` | Default. Also accepts `BlexMono`, `CommitMono`, or `None`. |
| `-FontSize 14` | Point size for Windows Terminal. Defaults to 12. |
| `-IncludeWsl` | Also install the btop theme inside WSL. |
| `-WslDistribution Fedora` | Target a specific distro instead of the WSL default. |
| `-WhatIf` | Show what would happen and change nothing. |

Two things stay manual, because neither browser can be themed from a script:

- **Chrome** — `chrome://extensions`, enable Developer mode, Load unpacked, pick the `chrome/` folder.
- **Firefox** — `about:addons`, gear icon, Install Add-on From File, pick the signed `.xpi`.

Ghostty and Terminal.app have no Windows build and are skipped. btop has no native Windows build
either, which is why its theme goes into a WSL guest. Regenerating themes from `palette.toml` still
requires Swift, so `make build` remains a macOS or Linux job; the installer only applies files that
are already committed.

## Terminal

Download [ember.terminal](https://github.com/axiomlayer/ember/blob/main/terminal/Ember.terminal) and import it as a Theme in Terminal.app. Set it as default; the generated profile includes BlexMono Nerd Font at 14pt.

## Prompt

[starship](https://starship.rs/guide/#%F0%9F%9A%80-installation)

Once you're done with that copy [starship.toml](https://github.com/axiomlayer/ember/blob/main/starship/starship.toml) to `~/.config/starship.toml`.

### Host variants

Ember is the prompt source for my machines, but `caracal` deliberately runs a derived
`starship.toml`: hostname always shown, `add_newline = false`, remote branch in the git
segment. That's SSH-box ergonomics rather than drift, and it's recorded as an exception in
caracal's own `docs/OWNERSHIP.md` instead of being reconciled away.

One exception is fine and doesn't need solving. If a second host wants that prompt, that's
the signal ember should grow a real host-variant mechanism rather than quietly accumulate
forks — at which point the fork stops being an exception and becomes a missing feature.

## Ghostty

[👻 Ghostty](https://ghostty.org/)

Copy [ghostty/config.full](https://github.com/axiomlayer/ember/blob/main/ghostty/config.full) and put it in your Ghostty settings.

## Firefox

[Firefox](https://www.firefox.com)

Download [firefox/ember-0.2.0-mozilla-signed.xpi](https://github.com/axiomlayer/ember/blob/main/firefox/ember-0.2.0-mozilla-signed.xpi). Open Firefox > shift+cmd+A > click the gear > Install Add-on From File > import the thing you just downloaded.

## Zed

[Zed](https://zed.dev/)

Copy [zed/ember.json](https://github.com/axiomlayer/ember/blob/main/zed/ember.json) and put it in `~/.config/zed/themes/ember.json`. Open Zed > cmd+k > cmd+t > "Ember".

## btop

[btop](https://github.com/aristocratos/btop)

Copy [btop/ember.theme](https://github.com/axiomlayer/ember/blob/main/btop/ember.theme) to `~/.config/btop/themes/ember.theme`. Open btop > m > enter > left/right until you find TTY or Ember - check both and land on whichever you like more.

## ChatGPT

Copy the contents of [chatgpt/ember-dark.txt](https://github.com/axiomlayer/ember/blob/main/chatgpt/ember-dark.txt) or [chatgpt/ember-light.txt](https://github.com/axiomlayer/ember/blob/main/chatgpt/ember-light.txt). In the ChatGPT macOS app, open Settings > Appearance, use Import in the matching Dark theme or Light theme section, paste the theme string, then click Import theme.

## bone.css

[bone.css](https://github.com/axiomlayer/ember/blob/main/bone.css) is a classless CSS base that makes unstyled HTML look clean out of the box. It prefers a locally installed BlexMono Nerd Font and falls back through the local monospace stack. Drop it in and you're done — no classes, no configuration.

## Generating themes

The palette lives in [palette.toml](https://github.com/axiomlayer/ember/blob/main/palette.toml). If you want to riff on the colors and regenerate all the theme files from scratch:

```sh
# Requires Xcode Command Line Tools
# xcode-select --install

make build
```

[generate.swift](https://github.com/axiomlayer/ember/blob/main/generate.swift) reads `palette.toml` and writes out the config files for each tool in the repo. Edit the palette, run `make`, done.
