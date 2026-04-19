import Foundation

// ── Usage ───────────────────────────────────────────────────────────
// swift generate.swift <template> <output>
// Reads palette.toml, resolves all color references, replaces {{key}}
// placeholders in the template, writes the result.

let args = CommandLine.arguments
guard args.count == 3 else {
    fputs("usage: swift generate.swift <template> <output>\n", stderr)
    exit(1)
}

let templatePath = args[1]
let outputPath = args[2]

// ── Read palette.toml ───────────────────────────────────────────────

let scriptDir = URL(fileURLWithPath: #file).deletingLastPathComponent()
let paletteURL = scriptDir.appendingPathComponent("palette.toml")
let paletteSrc = try! String(contentsOf: paletteURL, encoding: .utf8)

func paletteValue(_ key: String) -> String {
    let pattern = #"(?m)^\s*"# + key + #"\s*=\s*"([^"]+)""#
    let regex = try! NSRegularExpression(pattern: pattern)
    let range = NSRange(paletteSrc.startIndex..., in: paletteSrc)
    guard let match = regex.firstMatch(in: paletteSrc, range: range) else {
        fatalError("palette.toml missing key: \(key)")
    }
    return String(paletteSrc[Range(match.range(at: 1), in: paletteSrc)!])
}

// ── Build resolved color map ────────────────────────────────────────

var values: [String: String] = [:]

// Top-level
values["font"] = paletteValue("font")

// [colors]
for name in ["dark", "background", "text", "ember", "sage", "peach", "gold", "sky", "orchid", "muted", "ghost", "selection"] {
    values[name] = paletteValue(name)
}

// [ansi] — resolve references to [colors]
for name in ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white",
             "bright_black", "bright_red", "bright_green", "bright_yellow",
             "bright_blue", "bright_magenta", "bright_cyan", "bright_white"] {
    let value = paletteValue(name)
    if value.hasPrefix("#") {
        values[name] = value
    } else if let resolved = values[value] {
        values[name] = resolved
    } else {
        fatalError("unresolved ansi reference: \(name) -> \(value)")
    }
}

// [terminal] — resolve references to [colors] or [ansi]
for name in ["cursor", "bold", "selection"] {
    let value = paletteValue(name)
    if value.hasPrefix("#") {
        values[name] = value
    } else if let resolved = values[value] {
        values[name] = resolved
    } else {
        fatalError("unresolved terminal reference: \(name) -> \(value)")
    }
}

// ── Render template ─────────────────────────────────────────────────

var template = try! String(contentsOfFile: templatePath, encoding: .utf8)

let placeholder = try! NSRegularExpression(pattern: #"\{\{(\w+)\}\}"#)
let fullRange = NSRange(template.startIndex..., in: template)
var result = template

// Iterate matches in reverse so replacements don't shift offsets
let matches = placeholder.matches(in: template, range: fullRange)
for match in matches.reversed() {
    let keyRange = Range(match.range(at: 1), in: template)!
    let key = String(template[keyRange])
    guard let value = values[key] else {
        fatalError("template references unknown key: {{\(key)}}")
    }
    let matchRange = Range(match.range, in: result)!
    result.replaceSubrange(matchRange, with: value)
}

try! result.write(toFile: outputPath, atomically: true, encoding: .utf8)
print("wrote \(outputPath)")
