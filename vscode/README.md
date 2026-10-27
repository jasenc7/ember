# Ember for Visual Studio Code

Joshua Tree at dusk on Halloween.

The same palette and syntax roles as Ember for Zed, with the Windows Terminal ANSI
palette in VS Code's integrated terminal. Dark plum chrome, warm text, ember
keywords, sage strings, gold functions, orchid types, and peach constants.
Includes TextMate and semantic highlighting. Fonts remain a user setting.

## Install from this checkout

From the repository root, copy the extension directory into your VS Code extensions
folder. No Node.js, Swift, or Marketplace account is required for this installation.

Windows PowerShell:

```powershell
$destination = Join-Path $env:USERPROFILE '.vscode\extensions\jasenc7.ember-theme-0.1.0'
New-Item -ItemType Directory -Force -Path $destination | Out-Null
Copy-Item -Path .\vscode\* -Destination $destination -Recurse -Force
```

macOS / Linux:

```sh
mkdir -p ~/.vscode/extensions/jasenc7.ember-theme-0.1.0
cp -R vscode/. ~/.vscode/extensions/jasenc7.ember-theme-0.1.0/
```

Run **Developer: Reload Window**, then **Preferences: Color Theme** and select
**Ember**. For VS Code Insiders, use `.vscode-insiders/extensions` instead.

To uninstall a manually copied extension, remove that directory and reload VS Code.

## Build a VSIX

With Node.js installed, run from `vscode/`:

```sh
npx @vscode/vsce package --no-dependencies --skip-license
```

In VS Code, run **Extensions: Install from VSIX...** and select the resulting file,
or use `code --install-extension ember-theme-0.1.0.vsix`. This packages the theme
locally; it does not publish it to the Marketplace.

## Regenerate

Edit `../palette.toml`, then run `make vscode` from the repository root on a machine
with Swift. `make build` also includes this theme. Edit
`themes/ember-color-theme.json.template` for VS Code-specific mappings; the adjacent
JSON file is generated and committed for installation without build tools.

The template uses the existing `generate.swift` placeholders, including alpha
suffixes for selections and diff highlights. The extension has no executable code,
dependencies, or activation events.
