# Releases

A release is two separate ZIP archives. One is for maintaining the themes, the other for
installing them.

```sh
bash scripts/package-themes.sh <version>
```

Run it from anywhere; it works relative to the repository root. It writes:

- `out/ember-source-<version>.zip`
- `out/ember-themes-<version>.zip`

The script packages the listed files exactly as they are in your checkout, including any
uncommitted edits, so package from a clean checkout of the commit you mean to release
(`git status` shows nothing). It doesn't run `make build`, doesn't install anything, and doesn't
touch any application's settings. Regenerate and commit first if the palette has changed.

## Contents

Both archives keep each file at its path in the repository, such as `zed/ember.json`, so every
target keeps its folder layout. Every file is listed by name in the script; nothing gets in by
zipping a whole folder.

### `ember-source-<version>.zip`

| Files | Why |
| --- | --- |
| `palette.toml` | The colors |
| `generate.swift`, `terminal/convert.swift`, `Makefile` | The generators and build targets |
| `terminal/Ember.terminal.template`, `ghostty/config.template`, `btop/ember.theme.template`, `zed/ember.json.template`, `firefox/ember/manifest.json.template`, `chrome/manifest.json.template`, `windows-terminal/ember.json.template`, `chatgpt/ember-dark.txt.template`, `chatgpt/ember-light.txt.template` | Templates for the targets listed below |
| `windows/Install-Ember.ps1` | The Windows installer source |
| `README.md`, `docs/theme-targets.md`, `docs/install-and-restore.md`, `docs/releases.md` | The README plus the target, install/restore and release documents |

VS Code isn't one of these targets. The `Makefile` still lists a `vscode` target, so `make build`
in an unpacked source archive builds every target above and then stops at `vscode`. To build the
targets in this archive without that error, run
`make terminal ghostty btop zed firefox chrome windows-terminal chatgpt`.

### `ember-themes-<version>.zip`

| Target | Files |
| --- | --- |
| Terminal | `terminal/Ember.terminal` |
| Ghostty | `ghostty/config`, `ghostty/config.full` |
| btop | `btop/ember.theme` |
| Zed | `zed/ember.json` |
| Firefox | `firefox/ember-0.2.0-mozilla-signed.xpi` (signed by Mozilla, stored unchanged so the signature stays valid); `firefox/ember/manifest.json` (unsigned, for a temporary local load only) |
| Chrome | `chrome/manifest.json` (an unpacked extension; Chrome loads it from the folder) |
| Windows Terminal | `windows-terminal/ember.json` |
| Starship | `starship/starship.toml` |
| ChatGPT | `chatgpt/ember-dark.txt`, `chatgpt/ember-light.txt` |
| Instructions | `docs/theme-targets.md`, `docs/install-and-restore.md`, `docs/releases.md` |

## Never included

- `DSC_0075.JPG`, the original photograph. It stays in source custody and isn't distributed
  unless someone later explicitly chooses to release the artwork. The script refuses to package
  it even if it's added to a list by mistake. The script never deletes it.
- `.git`, local backups (`*.pre-ember-*.bak`), browser profiles, credentials, temporary renders,
  and `out/` itself.
- Files outside the lists: `chrome/Cached Theme.pak` (a cache Chrome writes when it loads the
  folder), `ghostty/keybinds.txt`, `bone.css`, `vscode/`, and the build outputs `firefox/ember.xpi`
  and `*.vsix`.

The repository has no license file, so neither archive contains one.

## When packaging fails

Nothing is written until these checks pass:

- **No version, or an empty one:** prints usage and exits with status 2.
- **A version containing anything other than letters, digits, `.`, `_` or `-`, or starting with
  `.`:** exits with status 2, so the version can't become a path.
- **A missing listed file:** lists every missing file and exits with status 1. Packaging stops
  rather than produce an incomplete theme set.
- **Either output for that version already exists:** exits with status 1. Earlier releases are
  never overwritten; use a new version.
- **`zip` not installed:** exits with status 1.

Each archive is written to a temporary `<archive>.partial.<pid>` file and renamed into place when
it's complete. If anything fails after writing starts, including an interrupt (Ctrl-C), `TERM` or
`HUP`, the script removes only the files this run created: the partial file, the source archive
if it already finished, and `out/` if this run created it and it's empty. Earlier archives and
everything else under `out/` stay as they are. If a `.partial` file with this run's name is
already there, the script stops rather than add to it.

## Restoring the previous theme package

A package only holds files. Installing one is a separate step for each target, described in
[install-and-restore.md](install-and-restore.md), and you install one target at a time.

To go back to a previous release for one target:

1. Unpack that release's `ember-themes-<version>.zip` into an empty folder. Earlier archives in
   `out/` are never overwritten.
2. Follow that target's install section in `install-and-restore.md`, using the files from that
   folder, and keep the current file aside first, as the instructions describe.
3. To undo instead, follow the same target's restore section.

This only applies to the target you're changing. The packaging script never changes application
settings, and moving one target back doesn't call for touching the others.
