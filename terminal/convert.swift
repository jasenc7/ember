import Cocoa

// ── Read palette.toml ───────────────────────────────────────────────

let scriptDir = URL(fileURLWithPath: #file).deletingLastPathComponent()
let paletteURL = scriptDir.deletingLastPathComponent().appendingPathComponent("palette.toml")
let paletteSrc = try! String(contentsOf: paletteURL, encoding: .utf8)

func paletteValue(_ key: String) -> String {
    // Match key = "#hex" in palette.toml
    let pattern = #"(?m)^\s*"# + key + #"\s*=\s*"([^"]+)""#
    let regex = try! NSRegularExpression(pattern: pattern)
    let range = NSRange(paletteSrc.startIndex..., in: paletteSrc)
    guard let match = regex.firstMatch(in: paletteSrc, range: range) else {
        fatalError("palette.toml missing key: \(key)")
    }
    return String(paletteSrc[Range(match.range(at: 1), in: paletteSrc)!])
}

// ── Resolve colors ──────────────────────────────────────────────────

var colorMap: [String: String] = [:]

// Load [colors] section
for name in ["dark", "background", "text", "ember", "sage", "peach", "gold", "sky", "orchid", "muted", "ghost", "selection"] {
    colorMap[name] = paletteValue(name)
}

// Load [ansi] section — these can reference [colors] names or be hex values
for name in ["black", "red", "green", "yellow", "blue", "magenta", "cyan", "white",
             "bright_black", "bright_red", "bright_green", "bright_yellow",
             "bright_blue", "bright_magenta", "bright_cyan", "bright_white"] {
    let value = paletteValue(name)
    if value.hasPrefix("#") {
        colorMap[name] = value
    } else if let resolved = colorMap[value] {
        colorMap[name] = resolved
    } else {
        fatalError("unresolved ansi reference: \(name) -> \(value)")
    }
}

// Load [terminal] section — these reference [colors] or [ansi] names
for name in ["cursor", "bold", "selection"] {
    let value = paletteValue(name)
    if value.hasPrefix("#") {
        colorMap[name] = value
    } else if let resolved = colorMap[value] {
        colorMap[name] = resolved
    } else {
        fatalError("unresolved terminal reference: \(name) -> \(value)")
    }
}

func resolveHex(_ value: String) -> String {
    if value.hasPrefix("#") { return value }
    guard let resolved = colorMap[value] else {
        fatalError("unresolved palette reference: \(value)")
    }
    return resolved
}

func hexToRGB(_ hex: String) -> (CGFloat, CGFloat, CGFloat) {
    let h = hex.dropFirst() // strip #
    let scanner = Scanner(string: String(h))
    var rgb: UInt64 = 0
    scanner.scanHexInt64(&rgb)
    return (CGFloat((rgb >> 16) & 0xFF), CGFloat((rgb >> 8) & 0xFF), CGFloat(rgb & 0xFF))
}

// ── Build ANSI color mapping ────────────────────────────────────────

let ansiKeys: [(String, String)] = [
    ("ANSIBlackColor",         colorMap["black"]!),
    ("ANSIRedColor",           colorMap["red"]!),
    ("ANSIGreenColor",         colorMap["green"]!),
    ("ANSIYellowColor",        colorMap["yellow"]!),
    ("ANSIBlueColor",          colorMap["blue"]!),
    ("ANSIMagentaColor",       colorMap["magenta"]!),
    ("ANSICyanColor",          colorMap["cyan"]!),
    ("ANSIWhiteColor",         colorMap["white"]!),
    ("ANSIBrightBlackColor",   colorMap["bright_black"]!),
    ("ANSIBrightRedColor",     colorMap["bright_red"]!),
    ("ANSIBrightGreenColor",   colorMap["bright_green"]!),
    ("ANSIBrightYellowColor",  colorMap["bright_yellow"]!),
    ("ANSIBrightBlueColor",    colorMap["bright_blue"]!),
    ("ANSIBrightMagentaColor", colorMap["bright_magenta"]!),
    ("ANSIBrightCyanColor",    colorMap["bright_cyan"]!),
    ("ANSIBrightWhiteColor",   colorMap["bright_white"]!),
    ("BackgroundColor",        colorMap["background"]!),
    ("TextColor",              colorMap["text"]!),
    ("TextBoldColor",          colorMap["bold"]!),
    ("SelectionColor",         colorMap["selection"]!),
    ("CursorColor",            colorMap["cursor"]!),
]

// ── Generate Terminal.app profile ───────────────────────────────────

func colorData(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> Data {
    let c = NSColor(srgbRed: r/255, green: g/255, blue: b/255, alpha: 1)
    return try! NSKeyedArchiver.archivedData(withRootObject: c, requiringSecureCoding: true)
}

let srcURL = scriptDir.appendingPathComponent("Dracula.terminal")
let dstURL = scriptDir.appendingPathComponent("Ember.terminal")

var p = try! PropertyListSerialization.propertyList(
    from: Data(contentsOf: srcURL),
    format: nil
) as! [String: Any]

for (key, value) in ansiKeys {
    let hex = resolveHex(value)
    let (r, g, b) = hexToRGB(hex)
    p[key] = colorData(r, g, b)
}

p["name"] = "Ember"

let out = try! PropertyListSerialization.data(fromPropertyList: p, format: .xml, options: 0)
try! out.write(to: dstURL)
print("wrote Ember.terminal")
