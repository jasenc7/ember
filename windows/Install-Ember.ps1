<#
.SYNOPSIS
    Installs the Ember theme on Windows.

.DESCRIPTION
    Applies the parts of Ember that have a Windows target: a patched Nerd Font,
    the Windows Terminal colour scheme, the starship prompt config, the Zed
    theme, and (optionally) the btop theme inside a WSL guest.

    Ghostty and Terminal.app have no Windows target and are skipped. Regenerating
    the theme files from palette.toml still requires Swift, so `make build` stays
    a macOS/Linux job; this script only installs what is already committed.

    Every step is idempotent and re-runnable. Windows Terminal settings are backed
    up before the first modification.

.PARAMETER Font
    Which patched font to install and reference. 'None' skips font installation
    and leaves whatever Windows Terminal already uses.

.PARAMETER FontSize
    Point size applied to the Windows Terminal profile defaults.

.PARAMETER IncludeWsl
    Also install the btop theme into a WSL distribution. btop has no native
    Windows build, so this is the only way to theme it on this platform.

.PARAMETER WslDistribution
    Name of the WSL distribution to target. Defaults to the WSL default distro.

.EXAMPLE
    pwsh -File windows/Install-Ember.ps1

.EXAMPLE
    pwsh -File windows/Install-Ember.ps1 -Font CommitMono -IncludeWsl -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('BlexMono', 'MapleMono', 'CommitMono', 'None')]
    [string] $Font = 'MapleMono',

    [ValidateRange(6, 72)]
    [int] $FontSize = 12,

    [switch] $IncludeWsl,

    [string] $WslDistribution
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot

# Pinned so a rebuild a year from now installs the same glyphs. Bump deliberately.
$NerdFontsTag = 'v3.5.1'
$MapleFontTag = 'v7.9'

# Windows resolves these family names; they are not the archive names.
$FontCatalog = @{
    BlexMono   = @{
        Family = 'BlexMono Nerd Font Mono'
        Url    = "https://github.com/ryanoasis/nerd-fonts/releases/download/$NerdFontsTag/IBMPlexMono.zip"
        Sha    = $null
    }
    CommitMono = @{
        Family = 'CommitMono Nerd Font Mono'
        Url    = "https://github.com/ryanoasis/nerd-fonts/releases/download/$NerdFontsTag/CommitMono.zip"
        Sha    = $null
    }
    MapleMono  = @{
        Family = 'Maple Mono NF'
        Url    = "https://github.com/subframe7536/maple-font/releases/download/$MapleFontTag/MapleMono-NF.zip"
        Sha    = "https://github.com/subframe7536/maple-font/releases/download/$MapleFontTag/MapleMono-NF.sha256"
    }
}

function Write-Step { param($Message) Write-Host "==> $Message" -ForegroundColor Cyan }
function Write-Ok { param($Message) Write-Host "    $Message" -ForegroundColor Green }
function Write-Skip { param($Message) Write-Host "    $Message" -ForegroundColor DarkGray }

function Get-JsonContent {
    <#
        Windows Terminal permits JSONC. ConvertFrom-Json does not, so strip
        comments only if a strict parse fails.
    #>
    param([string] $Path)
    $raw = Get-Content -LiteralPath $Path -Raw
    try {
        return $raw | ConvertFrom-Json
    } catch {
        $stripped = [regex]::Replace($raw, '(?m)^\s*//.*$', '')
        $stripped = [regex]::Replace($stripped, '/\*.*?\*/', '', 'Singleline')
        return $stripped | ConvertFrom-Json
    }
}

function Install-EmberFont {
    param([string] $Key)

    if ($Key -eq 'None') {
        Write-Skip 'Font installation skipped (-Font None).'
        return $null
    }

    $spec = $FontCatalog[$Key]
    $fontDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
    $regPath = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'

    # A font is "already installed" when its registry entries exist; copying the
    # files alone does not make Windows aware of them.
    $existing = @(Get-ItemProperty -Path $regPath |
        ForEach-Object { $_.PSObject.Properties } |
        Where-Object { $_.Name -like "$Key*" })
    if ($existing.Count -gt 0) {
        Write-Skip "$($spec.Family) already installed ($($existing.Count) faces)."
        return $spec.Family
    }

    if (-not $PSCmdlet.ShouldProcess($spec.Family, 'Install font')) { return $spec.Family }

    $work = Join-Path ([IO.Path]::GetTempPath()) "ember-font-$Key-$(Get-Random)"
    New-Item -ItemType Directory -Force -Path $work | Out-Null
    New-Item -ItemType Directory -Force -Path $fontDir | Out-Null

    $zip = Join-Path $work "$Key.zip"
    Write-Host "    downloading $($spec.Url)"
    Invoke-WebRequest -Uri $spec.Url -OutFile $zip -UseBasicParsing

    if ($spec.Sha) {
        $response = Invoke-WebRequest -Uri $spec.Sha -UseBasicParsing
        $body = if ($response.Content -is [byte[]]) {
            [Text.Encoding]::UTF8.GetString($response.Content)
        } else {
            [string]$response.Content
        }
        $expected = $body.Trim().Split()[0].ToLower()
        $actual = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLower()
        if ($expected -ne $actual) {
            throw "Checksum mismatch for $Key. Expected $expected, got $actual."
        }
        Write-Ok 'checksum verified'
    }

    $extracted = Join-Path $work 'extracted'
    Expand-Archive -LiteralPath $zip -DestinationPath $extracted -Force

    $count = 0
    foreach ($file in Get-ChildItem -LiteralPath $extracted -Recurse -Include '*.ttf', '*.otf') {
        # Variable fonts confuse Windows font enumeration; static instances ship alongside.
        if ($file.Name -match 'Variable') { continue }

        $target = Join-Path $fontDir $file.Name
        Copy-Item -LiteralPath $file.FullName -Destination $target -Force

        $face = [IO.Path]::GetFileNameWithoutExtension($file.Name)
        $kind = if ($file.Extension -eq '.otf') { 'OpenType' } else { 'TrueType' }
        New-ItemProperty -Path $regPath -Name "$face ($kind)" -Value $target -PropertyType String -Force | Out-Null
        $count++
    }

    Write-Ok "$($spec.Family): $count faces installed for the current user"
    return $spec.Family
}

function Install-EmberWindowsTerminal {
    param([string] $FontFamily, [int] $Size)

    $candidates = @(
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
        "$env:LOCALAPPDATA\Microsoft\Windows Terminal\settings.json"
    )
    $settingsPath = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $settingsPath) {
        Write-Skip 'Windows Terminal settings.json not found; skipping.'
        return
    }

    $schemePath = Join-Path $RepoRoot 'windows-terminal\ember.json'
    if (-not (Test-Path $schemePath)) { throw "Missing generated scheme: $schemePath" }
    $scheme = Get-JsonContent -Path $schemePath

    if (-not $PSCmdlet.ShouldProcess($settingsPath, 'Apply Ember scheme')) { return }

    $originalRaw = Get-Content -LiteralPath $settingsPath -Raw
    $settings = Get-JsonContent -Path $settingsPath

    # Replace any existing Ember scheme rather than appending a duplicate.
    $schemes = @($settings.schemes | Where-Object { $_.name -ne $scheme.name })
    $schemes += $scheme
    $settings.schemes = $schemes

    if (-not $settings.profiles.PSObject.Properties['defaults'] -or -not $settings.profiles.defaults) {
        $settings.profiles | Add-Member -NotePropertyName defaults -NotePropertyValue ([pscustomobject]@{}) -Force
    }
    $defaults = $settings.profiles.defaults
    $defaults | Add-Member -NotePropertyName colorScheme -NotePropertyValue $scheme.name -Force

    # Collect what changed but report only if the file is actually rewritten.
    $changes = @()

    if ($FontFamily) {
        $font = [pscustomobject]@{ face = $FontFamily; size = $Size }
        $defaults | Add-Member -NotePropertyName font -NotePropertyValue $font -Force
        $changes += "font: $FontFamily ${Size}pt"
    }

    # A per-profile colorScheme shadows defaults, so clear those overrides.
    foreach ($profile in $settings.profiles.list) {
        if ($profile.PSObject.Properties['colorScheme'] -and $profile.colorScheme -ne $scheme.name) {
            $changes += "cleared override on $($profile.name) (was $($profile.colorScheme))"
            $profile.PSObject.Properties.Remove('colorScheme')
        }
    }

    # A running Windows Terminal rewrites settings.json whenever it saves, and
    # holds a brief lock while doing so. Set-Content asks for sharing that WT
    # will not grant mid-save, so write through a FileStream that tolerates a
    # concurrent reader, and back off if the window is genuinely busy.
    $json = $settings | ConvertTo-Json -Depth 64

    # Re-running with nothing to change should not churn the file or leave
    # another backup behind.
    if ($json.Trim() -eq $originalRaw.Trim()) {
        Write-Skip 'Windows Terminal already matches; left untouched.'
        return
    }

    $backup = "$settingsPath.pre-ember-$(Get-Date -Format 'yyyyMMdd-HHmmss').bak"
    Copy-Item -LiteralPath $settingsPath -Destination $backup
    Write-Ok "backup: $(Split-Path -Leaf $backup)"

    $bytes = [Text.UTF8Encoding]::new($false).GetBytes($json)

    $written = $false
    foreach ($attempt in 1..6) {
        try {
            $stream = [IO.File]::Open($settingsPath, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::ReadWrite)
            try {
                $stream.Write($bytes, 0, $bytes.Length)
                $stream.Flush()
            } finally {
                $stream.Dispose()
            }
            $written = $true
            break
        } catch [IO.IOException] {
            if ($attempt -eq 6) { throw }
            Write-Skip "settings.json is busy; retrying ($attempt/6)"
            Start-Sleep -Milliseconds (500 * $attempt)
        }
    }
    if (-not $written) { throw 'Could not write Windows Terminal settings.' }

    foreach ($change in $changes) { Write-Ok $change }
    Write-Ok "scheme '$($scheme.name)' applied to all profiles"
}

function Install-EmberStarship {
    $source = Join-Path $RepoRoot 'starship\starship.toml'
    $targetDir = Join-Path $env:USERPROFILE '.config'
    $target = Join-Path $targetDir 'starship.toml'

    if (-not $PSCmdlet.ShouldProcess($target, 'Install starship config')) { return }

    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    if ((Test-Path $target) -and -not ((Get-FileHash $target).Hash -eq (Get-FileHash $source).Hash)) {
        $backup = "$target.pre-ember-$(Get-Date -Format 'yyyyMMdd-HHmmss').bak"
        Copy-Item -LiteralPath $target -Destination $backup
        Write-Ok "backup: $(Split-Path -Leaf $backup)"
    }
    Copy-Item -LiteralPath $source -Destination $target -Force
    Write-Ok "starship config -> $target"

    # A shell started before starship was installed still has the old PATH, so
    # check the machine PATH too before claiming it is missing.
    $onPath = [bool](Get-Command starship -ErrorAction SilentlyContinue)
    $machinePath = [Environment]::GetEnvironmentVariable('PATH', 'Machine') -split ';'
    $userPath = [Environment]::GetEnvironmentVariable('PATH', 'User') -split ';'
    $installed = @(
        @($machinePath + $userPath) |
            Where-Object { $_ } |
            Where-Object { Test-Path (Join-Path $_ 'starship.exe') -ErrorAction SilentlyContinue }
    )

    if ($onPath) {
        Write-Ok "starship found: $((Get-Command starship).Source)"
    } elseif ($installed) {
        Write-Ok "starship installed at $($installed[0]); open a new shell to pick it up"
    } else {
        Write-Skip 'starship is not installed. winget install --id Starship.Starship'
    }
}

function Install-EmberZed {
    $source = Join-Path $RepoRoot 'zed\ember.json'
    # Zed on Windows keeps its config under APPDATA (roaming), unlike ~/.config elsewhere.
    $targetDir = Join-Path $env:APPDATA 'Zed\themes'
    $target = Join-Path $targetDir 'ember.json'

    if (-not $PSCmdlet.ShouldProcess($target, 'Install Zed theme')) { return }

    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    Copy-Item -LiteralPath $source -Destination $target -Force
    Write-Ok "Zed theme -> $target"
    Write-Skip 'In Zed: ctrl+k ctrl+t, then pick "Ember".'
}

function Install-EmberBtopWsl {
    param([string] $Distribution)

    $wsl = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\wsl.exe'
    if (-not (Test-Path $wsl)) { $wsl = 'wsl.exe' }

    $source = Join-Path $RepoRoot 'btop\ember.theme'
    if (-not (Test-Path $source)) { throw "Missing generated theme: $source" }

    $distroArgs = if ($Distribution) { @('-d', $Distribution) } else { @() }

    # Spelled out rather than using PowerShell 7's ternary. That operator is a
    # PARSE error under Windows PowerShell 5.1, and PowerShell parses the whole
    # file before executing any of it -- so this line, inside an optional code
    # path that only runs with -IncludeWsl, would stop the font, the terminal
    # scheme, the prompt and the editor theme from being installed at all. It
    # fails with a wall of brace-matching noise that never mentions versions.
    # 5.1 ships on every Windows machine and pwsh 7 does not, so
    # `powershell -File windows/Install-Ember.ps1` is a plausible thing to type.
    # Found by Siberian, which confirmed it against 5.1's own parser.
    if ($Distribution) { $target = $Distribution } else { $target = 'default WSL distro' }
    if (-not $PSCmdlet.ShouldProcess($target, 'Install btop theme')) { return }

    # Two Windows-specific hazards here, both learned the hard way:
    #  1. PowerShell strips backslashes from native command arguments, so the
    #     Windows path must be handed to wslpath with forward slashes.
    #  2. Piping the file over stdin appends a CR. Copy the file instead, and
    #     strip any CRs in case the checkout itself used CRLF endings.
    $forwardSlashSource = $source -replace '\\', '/'
    $wslSource = (& $wsl @distroArgs -- wslpath -a $forwardSlashSource | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or -not $wslSource) { throw 'Could not translate the theme path into the WSL guest.' }

    $target = '~/.config/btop/themes/ember.theme'
    $command = "mkdir -p ~/.config/btop/themes && cp '$wslSource' $target && sed -i 's/\r`$//' $target"
    & $wsl @distroArgs -- bash -c $command

    if ($LASTEXITCODE -ne 0) { throw "Failed to write btop theme into WSL (exit $LASTEXITCODE)." }
    Write-Ok 'btop theme -> ~/.config/btop/themes/ember.theme inside WSL'
    Write-Skip 'In btop: press m, Enter, then arrow to "ember".'
}

# ---------------------------------------------------------------------------

Write-Host ''
Write-Host 'Ember - Windows install' -ForegroundColor Yellow
Write-Host "repo: $RepoRoot"
Write-Host ''

Write-Step "Font ($Font)"
$family = Install-EmberFont -Key $Font

Write-Step 'Windows Terminal'
Install-EmberWindowsTerminal -FontFamily $family -Size $FontSize

Write-Step 'starship'
Install-EmberStarship

Write-Step 'Zed'
Install-EmberZed

if ($IncludeWsl) {
    Write-Step 'btop (WSL)'
    Install-EmberBtopWsl -Distribution $WslDistribution
}

Write-Step 'Manual steps'
Write-Host @"
    Chrome   load $RepoRoot\chrome as an unpacked extension:
             chrome://extensions -> Developer mode -> Load unpacked
    Firefox  install $RepoRoot\firefox\ember-0.2.0-mozilla-signed.xpi:
             about:addons -> gear -> Install Add-on From File
"@
Write-Host ''
Write-Host 'Done. Open a new terminal to pick up the prompt.' -ForegroundColor Yellow
