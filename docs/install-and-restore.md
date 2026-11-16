# Install and restore

How to install one Ember target and put it back the way it was. The table in
[theme-targets.md](theme-targets.md) summarizes the same targets.

## Ground rules

- **One target at a time.** Installing Ember in one application doesn't mean installing it in the
  others. Pick the target you want and touch only that one.
- **Keep the previous file before you replace one.** For targets you install by copying a file,
  first find where the current file is, copy it aside, then replace it. The examples use the same
  suffix the Windows installer uses: `.pre-ember-<yyyyMMdd-HHmmss>.bak`.
- **Restore touches only that target.** Put back the file or the theme selection you changed.
  Don't reset the application's other settings.
- **Leave your custom and host-specific choices alone.** If an application already has a
  hand-tuned or host-specific config (for example `caracal`'s derived `starship.toml`, or your
  own Ghostty keybinds), don't overwrite it with the Ember file.
- **Regenerating isn't reinstalling.** `make build` rewrites the files in this repository from
  `palette.toml`. It doesn't change anything you've installed. To pick up a regenerated file,
  install that target again.

macOS and Linux commands below run from the repository root.

## Terminal (macOS Terminal.app)

Install:

1. In Terminal > Settings > Profiles, note which profile is marked Default.
2. If a profile named `Ember` already exists, select it and choose Export… from the action menu
   at the bottom of the profile list, to keep the previous version.
3. Choose Import… from the same menu and select `terminal/Ember.terminal`. You can also open the
   file in Finder.
4. Optional: select Ember and click Default.

Restore: select the profile you noted and click Default. Then delete the Ember profile with the
minus button, or re-import the version you exported.

## Ghostty

Pick the file first. Neither is appearance-only, and either one replaces your whole config file.

- `ghostty/config`, the generated file, sets the colors, `font-family = "BlexMono Nerd Font"`
  and `font-size = 14`. It also sets behavior: `cursor-style = block`,
  `cursor-style-blink = false`, `bold-is-bright = false`, `window-theme = ghostty`,
  `window-padding-x = 14`, `window-padding-y = 14`, `confirm-close-surface = false` (no
  confirmation when closing a running terminal) and `resize-overlay = never`.
- `ghostty/config.full` is the existing personal selection. It has all of the above, uses
  `font-family = "BlexMono Nerd Font Mono"`, and adds Home/End/Page Up/Page Down keybinds,
  `clipboard-paste-bracketed-safe = true`, `bell-features = audio` and
  `macos-secure-input-indication = false`.

If you want to keep any of your current settings, such as close confirmation, add them back to
the copied file after installing it.

Ghostty reads these files, in this order. Later files override earlier ones, and the macOS paths
load after the XDG paths. The `config.ghostty` name is used from Ghostty 1.2.3; `config` before
that.

- `~/.config/ghostty/config.ghostty` or `~/.config/ghostty/config`
- macOS only: `~/Library/Application Support/com.mitchellh.ghostty/config.ghostty` or `.../config`

Install (replace `$dest` with the file you actually use):

```sh
dest=~/.config/ghostty/config
mkdir -p "$(dirname "$dest")"
[ -e "$dest" ] && cp -p "$dest" "$dest.pre-ember-$(date +%Y%m%d-%H%M%S).bak"
cp ghostty/config.full "$dest"     # or ghostty/config
```

Reload the configuration from Ghostty's menu, or restart Ghostty.

Restore: copy the `.bak` back over `$dest` and reload. If no previous file existed, delete `$dest`.

## btop

Install:

```sh
grep '^color_theme' ~/.config/btop/btop.conf     # note the current theme
dest=~/.config/btop/themes/ember.theme
mkdir -p "$(dirname "$dest")"
[ -e "$dest" ] && cp -p "$dest" "$dest.pre-ember-$(date +%Y%m%d-%H%M%S).bak"
cp btop/ember.theme "$dest"
```

In btop press `m`, open Options, and use left/right on the color theme setting until it shows
Ember.

Restore: choose the theme you noted in the same setting. You can also quit btop and edit
`color_theme` in `~/.config/btop/btop.conf`. Then copy the `.bak` back, or delete `$dest` if
there wasn't one.

## Zed

Install:

```sh
dest=~/.config/zed/themes/ember.json
mkdir -p "$(dirname "$dest")"
[ -e "$dest" ] && cp -p "$dest" "$dest.pre-ember-$(date +%Y%m%d-%H%M%S).bak"
cp zed/ember.json "$dest"
```

On Windows the folder is `%APPDATA%\Zed\themes`. Before switching, note the current theme in
Zed's theme selector (`cmd-k cmd-t`; `ctrl-k ctrl-t` on Windows and Linux), which is the `theme`
entry in `settings.json`. Then choose Ember there.

Restore: open the theme selector and choose the theme you noted. Then copy the `.bak` back, or
delete `ember.json` if there wasn't one.

## Firefox

There are two separate routes:

- **Signed distribution:** `firefox/ember-0.2.0-mozilla-signed.xpi` is the copy Mozilla signed,
  and it installs permanently. Open `about:addons` > gear > Install Add-on From File and pick it.
- **Local development:** open `about:debugging#/runtime/this-firefox` > Load Temporary Add-on…
  and pick `firefox/ember/manifest.json`. Firefox drops it on the next restart.
  `make firefox-package` builds an unsigned `firefox/ember.xpi` to submit for signing. That file
  is for submission, not for installing.

Before installing, note which theme is enabled under `about:addons` > Themes. Firefox keeps the
previous theme installed but disabled.

Restore: in `about:addons` > Themes, enable the theme you noted, and remove Ember if you want.
For a temporary add-on, restart Firefox or click Remove in `about:debugging`.

## Chrome

Chrome loads Ember as a local unpacked extension. It isn't installed from the Chrome Web Store.

1. Note the current theme under Settings > Appearance > Theme. Chrome keeps only one theme, so
   loading Ember replaces it.
2. Open `chrome://extensions`, turn on Developer mode, click Load unpacked, and select the
   `chrome/` folder.

Chrome reads the folder in place, so keep the checkout where it is. Chrome writes
`chrome/Cached Theme.pak` there when it loads the theme.

Restore: Settings > Appearance > Theme > Reset to default, or remove Ember in
`chrome://extensions`. Then reinstall the previous theme from wherever it came from, such as the
Chrome Web Store.

## Windows Terminal

Manual, one profile at a time:

1. Copy `settings.json` aside, for example to `settings.json.pre-ember-<yyyyMMdd-HHmmss>.bak`.
   Find it from Settings > Open JSON file.
2. Add the object from `windows-terminal/ember.json` to the `schemes` array. The file has
   comments, which Windows Terminal accepts.
3. Set `"colorScheme": "Ember"` on the profiles you choose.

Restore: close Windows Terminal and copy the backup over `settings.json`. Or change the
`colorScheme` values back and remove the Ember scheme.

With the installer: see [Windows installer](#windows-installer). It applies Ember to every
profile.

## ChatGPT

Importing is an appearance choice you make in the app. Nothing in this repository changes your
ChatGPT settings for you.

1. In the ChatGPT macOS app, open Settings > Appearance and note the selected theme in the Dark
   theme or Light theme section. If it's a custom imported theme, keep the string you imported.
2. Copy the contents of `chatgpt/ember-dark.txt` or `chatgpt/ember-light.txt`, click Import in the
   matching section, paste, and click Import theme.

Restore: select the theme you noted in that section, or re-import the saved string.

## Starship

Install:

```sh
dest="${STARSHIP_CONFIG:-$HOME/.config/starship.toml}"
mkdir -p "$(dirname "$dest")"
[ -e "$dest" ] && cp -p "$dest" "$dest.pre-ember-$(date +%Y%m%d-%H%M%S).bak"
cp starship/starship.toml "$dest"
```

Skip hosts that deliberately run a derived prompt. `caracal` does (README, "Host variants").

Restore: copy the `.bak` back over `$dest` and open a new shell. If no previous file existed,
delete `$dest`.

## Windows installer

```powershell
pwsh -File windows/Install-Ember.ps1 -WhatIf     # preview, change nothing
pwsh -File windows/Install-Ember.ps1
```

`windows/Install-Ember.ps1` installs only files already committed here. It doesn't run
`make build`. One run always does the font, Windows Terminal, Starship and Zed steps, and adds
btop with `-IncludeWsl`. There's no switch to skip one of the first four, except `-Font None` for
the font. To install just one of them, use the manual steps above instead.

| Option | Behavior |
| --- | --- |
| `-WhatIf` | Each step asks before changing anything, so this prints what would happen and writes nothing. It still reads existing state, such as installed fonts and `settings.json`. |
| `-Font MapleMono` (default), `BlexMono`, `CommitMono`, `None` | Downloads and installs that Nerd Font for the current user. Maple Mono's checksum is verified; the other two have none. Skips if the font's registry entries already exist. `None` installs nothing and leaves the Windows Terminal font alone. Only Windows Terminal uses this font; the generated theme files keep the font from `palette.toml`. |
| `-FontSize 12` | Point size written to `profiles.defaults.font` together with the font face. |
| `-IncludeWsl` | Also copies `btop/ember.theme` to `~/.config/btop/themes/ember.theme` inside WSL. |
| `-WslDistribution <name>` | Targets that WSL distribution instead of the default one. |

What each step changes, and its backup:

| Step | Change | Backup | Restore |
| --- | --- | --- | --- |
| Font | Font files in `%LOCALAPPDATA%\Microsoft\Windows\Fonts` plus registry values under `HKCU\Software\Microsoft\Windows NT\CurrentVersion\Fonts` | None | Only if this run installed it (the step says "faces installed" rather than "already installed"): Settings > Personalization > Fonts > the family > Uninstall |
| Windows Terminal | Adds or replaces the `Ember` scheme, sets `profiles.defaults.colorScheme` (and `profiles.defaults.font` unless `-Font None`), and removes per-profile `colorScheme` values that name another scheme | `settings.json.pre-ember-<yyyyMMdd-HHmmss>.bak` beside `settings.json`, written only when the file is about to change | Close Windows Terminal and copy that `.bak` over `settings.json`. This also brings back the per-profile schemes the installer removed |
| Starship | Copies `starship.toml` to `%USERPROFILE%\.config\starship.toml` | `starship.toml.pre-ember-<yyyyMMdd-HHmmss>.bak`, only when an existing file differs. If your file already matches Ember's, there's no backup and no change | Copy that `.bak` back. With no `.bak`, delete the file only if it didn't exist before the run; if it already matched, leave it |
| Zed | Copies `ember.json` to `%APPDATA%\Zed\themes\ember.json`, overwriting any existing file | None. Copy any existing `ember.json` aside before running | Choose your previous theme in Zed (`ctrl-k ctrl-t`). Put back the copy you saved, or delete `ember.json` if there wasn't one |
| btop (WSL) | Copies the theme into the guest, overwriting any existing `ember.theme` | None. Copy any existing `~/.config/btop/themes/ember.theme` in the guest aside before running | Choose your previous theme in btop. Put back the copy you saved, or delete the file in the guest if there wasn't one |

The installer clears per-profile Windows Terminal schemes. If you've given particular profiles
their own scheme on purpose, use the manual steps, or restore from the `.bak` afterwards.

Chrome and Firefox are manual on Windows too. The installer prints the same steps as above.
Ghostty and Terminal.app have no Windows version.
