# Theme targets

Where each Ember theme comes from, what file you install, and what it changes on your machine.
Paths in the first three columns are relative to the repository root. Step-by-step install and
restore commands are in [install-and-restore.md](install-and-restore.md).

## Three different things

- **Generation**: `make build` (or one target, e.g. `make zed`) rewrites the committed theme
  files in this repository from `palette.toml` and the `*.template` files. It needs Swift. It
  changes nothing outside the checkout.
- **Distribution**: the files a person downloads or imports: the committed generated files, the
  hand-maintained files below, and the Mozilla-signed Firefox XPI.
- **Installed preference**: what an application on one machine actually has selected. Only you
  change it, one application at a time, by importing or copying a file and choosing the theme
  there. Regenerating or committing new theme files does not update anything you have already
  installed. Reinstall the target to pick up a change.

## Targets

| Application | Source/template | Generated/importable file | Install/import action | Affected setting | Existing configuration backup | Restore action |
| --- | --- | --- | --- | --- | --- | --- |
| Terminal (macOS Terminal.app) | `terminal/Ember.terminal.template` + `palette.toml`, via `terminal/convert.swift` (`make terminal`) | `terminal/Ember.terminal` | Terminal > Settings > Profiles > action menu > Import…, select the file; optionally click Default | Terminal's profile list; the default profile if you change it | Note the current default profile. If an `Ember` profile already exists, Export… it first | Set the previous profile as Default; delete the Ember profile or re-import the exported one |
| Ghostty | `ghostty/config.template` (`make ghostty`). `ghostty/config.full` is hand-maintained | `ghostty/config` (colors and font, plus behavior: cursor style, `bold-is-bright`, window theme and padding, `confirm-close-surface = false`, `resize-overlay = never`) or `ghostty/config.full` (the existing selection: all of that plus keybinds, paste, bell and secure-input settings, font `BlexMono Nerd Font Mono`) | Copy the chosen file over your Ghostty config file, then reload Ghostty's config or restart it | The whole Ghostty config file you replace, not just colors | Copy the current config file to `<file>.pre-ember-<timestamp>.bak` first | Copy the `.bak` back over the config file; reload |
| btop | `btop/ember.theme.template` (`make btop`) | `btop/ember.theme` | Copy to `~/.config/btop/themes/ember.theme`; in btop: `m` > Options > color theme > Ember | `color_theme` in `~/.config/btop/btop.conf` | Record the current `color_theme` value; back up any existing `themes/ember.theme` | Select the previous theme in btop; restore or remove `themes/ember.theme` |
| Zed | `zed/ember.json.template` (`make zed`) | `zed/ember.json` | Copy to `~/.config/zed/themes/ember.json` (Windows: `%APPDATA%\Zed\themes\ember.json`); theme selector (`cmd-k cmd-t`, Windows/Linux `ctrl-k ctrl-t`) > Ember | The `theme` entry in Zed's `settings.json` | Note the current theme; back up any existing `themes/ember.json` | Theme selector > previous theme; restore or remove `themes/ember.json` |
| Firefox | `firefox/ember/manifest.json.template` (`make firefox`); `make firefox-package` zips an unsigned `firefox/ember.xpi` for submission to Mozilla | Signed: `firefox/ember-0.2.0-mozilla-signed.xpi` (committed, signed by Mozilla, not produced by `make`). Local development: `firefox/ember/manifest.json` | Signed: `about:addons` > gear > Install Add-on From File. Local: `about:debugging#/runtime/this-firefox` > Load Temporary Add-on… (gone after restart) | The active theme of that Firefox profile | Note which theme is enabled under `about:addons` > Themes. Firefox keeps the previous theme installed but disabled | Enable the previous theme in `about:addons` > Themes; remove Ember if wanted |
| Chrome | `chrome/manifest.json.template` (`make chrome`) | `chrome/` folder as an unpacked extension (`chrome/manifest.json`; `chrome/Cached Theme.pak` is written by Chrome when it loads the folder and is not produced by `make`) | `chrome://extensions` > Developer mode > Load unpacked > select `chrome/` | Chrome's single active theme | Note the current theme. Chrome keeps one theme, so loading Ember replaces it | Settings > Appearance > Theme > Reset to default, or remove Ember in `chrome://extensions`; reinstall the previous theme from its source |
| Windows Terminal | `windows-terminal/ember.json.template` (`make windows-terminal`) | `windows-terminal/ember.json` (one scheme object) | Manual: add the object to `schemes` in `settings.json` and set `"colorScheme": "Ember"` on the profiles you choose. Or `windows/Install-Ember.ps1` | `schemes`, `colorScheme`; the installer also sets `profiles.defaults.colorScheme` and `profiles.defaults.font` and clears other per-profile `colorScheme` values | Installer: `settings.json.pre-ember-<yyyyMMdd-HHmmss>.bak` beside `settings.json`. Manual: copy `settings.json` first | Close Windows Terminal; copy the backup over `settings.json` |
| ChatGPT | `chatgpt/ember-dark.txt.template`, `chatgpt/ember-light.txt.template` (`make chatgpt`; light colors from `[chatgpt.light]`) | `chatgpt/ember-dark.txt`, `chatgpt/ember-light.txt` | ChatGPT macOS app > Settings > Appearance > Import in the Dark theme or Light theme section; paste the string; Import theme | That app's Dark or Light theme appearance, chosen by you | Note the selected theme; if it is an imported custom theme, keep the string you imported | Select the previous theme in the same section, or re-import the saved string |

### Starship (prompt)

Starship isn't generated from the palette: `starship/starship.toml` is hand-maintained and has
no `make` target.

| Source | Install action | Affected setting | Existing configuration backup | Restore action |
| --- | --- | --- | --- | --- |
| `starship/starship.toml` | Copy to `~/.config/starship.toml` (or the path in `$STARSHIP_CONFIG`). The Windows installer copies to `%USERPROFILE%\.config\starship.toml` | The whole prompt configuration | Copy the current file to `starship.toml.pre-ember-<timestamp>.bak`. The Windows installer does this when the existing file differs | Copy the `.bak` back; open a new shell |

Host-specific prompts stay as they are. `caracal` deliberately runs a derived `starship.toml`
(see "Host variants" in the README). Don't replace it with this file.

### Not in this table

- VS Code: installation and removal are in [vscode/README.md](../vscode/README.md).
- `bone.css`: a stylesheet you include in a page, not an application theme.

## Generation notes

- `make build` runs every generator. Each one is `swift generate.swift <template> <output>`
  except Terminal, which is `swift terminal/convert.swift`.
- `terminal/convert.swift` imports Cocoa, so `make terminal` (and therefore `make build`) runs
  only on macOS. It also stops if the palette font (`BlexMono Nerd Font`) isn't installed,
  because it embeds that font in the profile.
- `make clean` deletes the generated files listed in the Makefile, including committed ones.
  Regenerate before committing after a clean.
- Hand-maintained files that `make` never writes: `ghostty/config.full`, `ghostty/keybinds.txt`,
  `starship/starship.toml`, `firefox/ember-0.2.0-mozilla-signed.xpi`, `chrome/Cached Theme.pak`.
