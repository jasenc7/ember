#!/usr/bin/env bash
# Package Ember as two separate archives:
#   out/ember-source-<version>.zip  what you need to maintain and regenerate the themes
#   out/ember-themes-<version>.zip  the importable theme files plus install/restore docs
#
# It packages the listed files as they are in this checkout, including uncommitted edits.
# It never generates, installs or changes any application setting. See docs/releases.md.
#
# usage: bash scripts/package-themes.sh <version>

set -euo pipefail

die() { echo "package-themes: $*" >&2; exit 1; }

if [ "$#" -ne 1 ] || [ -z "$1" ]; then
    echo "usage: bash scripts/package-themes.sh <version>" >&2
    exit 2
fi
version="$1"
# The version becomes part of a file name, so it must not carry path separators.
case "$version" in
    .* | *[!A-Za-z0-9._-]*)
        echo "package-themes: version '$version' must use only letters, digits, '.', '_' or '-', and must not start with '.'" >&2
        exit 2
        ;;
esac

cd "$(dirname "$0")/.."

# Every entry is a single file named explicitly. Nothing is added by walking a directory,
# so .git, backups, browser profiles, credentials, renders and out/ cannot get in.
source_files=(
    palette.toml
    generate.swift
    terminal/convert.swift
    Makefile
    terminal/Ember.terminal.template
    ghostty/config.template
    btop/ember.theme.template
    zed/ember.json.template
    firefox/ember/manifest.json.template
    chrome/manifest.json.template
    windows-terminal/ember.json.template
    chatgpt/ember-dark.txt.template
    chatgpt/ember-light.txt.template
    windows/Install-Ember.ps1
    README.md
    docs/theme-targets.md
    docs/install-and-restore.md
    docs/releases.md
)

theme_files=(
    terminal/Ember.terminal
    ghostty/config
    ghostty/config.full
    btop/ember.theme
    zed/ember.json
    firefox/ember-0.2.0-mozilla-signed.xpi
    firefox/ember/manifest.json
    chrome/manifest.json
    windows-terminal/ember.json
    starship/starship.toml
    chatgpt/ember-dark.txt
    chatgpt/ember-light.txt
    windows/Install-Ember.ps1
    docs/theme-targets.md
    docs/install-and-restore.md
    docs/releases.md
)

source_zip="out/ember-source-$version.zip"
themes_zip="out/ember-themes-$version.zip"

# ── Checks. Nothing is written until all of them pass. ─────────────────

command -v zip >/dev/null 2>&1 || die "zip is not installed"

missing=()
for f in "${source_files[@]}" "${theme_files[@]}"; do
    case "$f" in
        DSC_0075.JPG | */DSC_0075.JPG)
            die "DSC_0075.JPG is kept in source custody and is not distributed" ;;
    esac
    [ -f "$f" ] || missing+=("$f")
done
if [ "${#missing[@]}" -gt 0 ]; then
    printf 'package-themes: missing required file: %s\n' "${missing[@]}" >&2
    die "nothing written; packaging stops rather than produce an incomplete set"
fi

for z in "$source_zip" "$themes_zip"; do
    [ ! -e "$z" ] || die "$z already exists; nothing written (pick a new version)"
done

# ── Build. On failure, remove only what this run created. ──────────────

created=()
made_out_dir=0
# The archive being published right now. A signal can land after ln creates $dest but
# before $dest is recorded in created; $dest is this run's only if it is the same file
# (same inode) as this run's temporary file, so a concurrent run's archive is never touched.
publishing_tmp=""
publishing_dest=""
cleanup() {
    status=$?
    if [ "$status" -ne 0 ]; then
        if [ -n "$publishing_tmp" ] && [ "$publishing_dest" -ef "$publishing_tmp" ]; then
            rm -f -- "$publishing_dest"
        fi
        for f in ${created[@]+"${created[@]}"}; do rm -f -- "$f"; done
        if [ "$made_out_dir" -eq 1 ]; then rmdir out 2>/dev/null || true; fi
        echo "package-themes: failed; removed the files this run created" >&2
    fi
}
trap cleanup EXIT
# bash skips the EXIT trap on an untrapped TERM or HUP, so turn those into a normal failing exit.
trap 'exit 130' INT TERM HUP

if [ ! -d out ]; then
    mkdir out
    made_out_dir=1
fi

build() {
    local dest="$1"; shift
    local tmp="$dest.partial.$$"
    # zip would append to a leftover file, so refuse one that this run did not create.
    [ ! -e "$tmp" ] || die "$tmp is left over from an earlier run; remove it and retry"
    created+=("$tmp")
    # -X drops owner/permission extras; -D writes no directory entries. Files are
    # stored byte for byte, so the signed XPI keeps its Mozilla signature.
    zip -q -X -D "$tmp" "$@"
    # Publish with a hard link, not mv: ln checks and creates in one step and fails if
    # $dest exists, so a second run for the same version can never replace (and later
    # clean up) an archive another run published.
    publishing_tmp="$tmp"
    publishing_dest="$dest"
    if ! ln "$tmp" "$dest" 2>/dev/null; then
        [ -e "$dest" ] && die "$dest was created by another run while packaging; not overwriting it"
        die "could not publish $dest (out/ must be on a filesystem that supports hard links)"
    fi
    created+=("$dest")
    rm -f "$tmp"
    publishing_tmp=""
    publishing_dest=""
}

build "$source_zip" "${source_files[@]}"
build "$themes_zip" "${theme_files[@]}"

echo "wrote $source_zip (${#source_files[@]} files)"
echo "wrote $themes_zip (${#theme_files[@]} files)"
