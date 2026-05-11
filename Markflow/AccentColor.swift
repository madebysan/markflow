import SwiftUI
import UIKit

struct AppTheme: Identifiable, Hashable {
    let id: String
    let name: String
    let lightHex: String
    let darkHex: String

    var accentColor: Color {
        Color(UIColor { trait in
            let hex = trait.userInterfaceStyle == .dark ? darkHex : lightHex
            return UIColor(HexColor.color(fromHex: hex))
        })
    }
}

enum AppThemeCatalog {
    static let all: [AppTheme] = [
        AppTheme(id: "indigo",   name: "Indigo",   lightHex: "#7869E4", darkHex: "#9489F3"),
        AppTheme(id: "forest",   name: "Forest",   lightHex: "#2C9F65", darkHex: "#4FBE85"),
        AppTheme(id: "sunset",   name: "Sunset",   lightHex: "#E16A3D", darkHex: "#F39163"),
        AppTheme(id: "ocean",    name: "Ocean",    lightHex: "#2A8DBE", darkHex: "#5BB0DC"),
        AppTheme(id: "graphite", name: "Graphite", lightHex: "#4F5560", darkHex: "#A0A6B0")
    ]

    static let defaultID = "indigo"

    static func theme(for id: String) -> AppTheme {
        all.first(where: { $0.id == id }) ?? all[0]
    }
}

enum AppearancePreference: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

enum AppPreferences {
    static let themeIDKey = "themeID"
    static let appearanceKey = "appearancePreference"
    static let documentFontKey = "documentFont"
    static let editorFontSizeKey = "editFontSize"     // existing key; reused
    static let previewFontSizeKey = "previewFontSize"
    static let newFileModeKey = "newFileMode"
}

enum DocumentFont: String, CaseIterable, Identifiable {
    case system, rounded, serif, mono, writer, code

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system:  return "System"
        case .rounded: return "Rounded"
        case .serif:   return "Charter"
        case .mono:    return "Monospace"
        case .writer:  return "iA Writer"
        case .code:    return "JetBrains"
        }
    }

    func uiFont(size: CGFloat) -> UIFont {
        switch self {
        case .system:
            return .systemFont(ofSize: size)
        case .rounded:
            // Build the descriptor from preferredFontDescriptor — using the
            // descriptor on .systemFont(ofSize:) sometimes drops the
            // attributes needed for .rounded design substitution.
            if let descriptor = UIFontDescriptor
                .preferredFontDescriptor(withTextStyle: .body)
                .withDesign(.rounded) {
                return UIFont(descriptor: descriptor, size: size)
            }
            return .systemFont(ofSize: size)
        case .serif:
            // Charter is bundled in iOS for iBooks; prefer it when available,
            // fall back to the system serif design (New York) otherwise.
            if let charter = UIFont(name: "Charter-Roman", size: size) {
                return charter
            }
            if let descriptor = UIFontDescriptor
                .preferredFontDescriptor(withTextStyle: .body)
                .withDesign(.serif) {
                return UIFont(descriptor: descriptor, size: size)
            }
            return .systemFont(ofSize: size)
        case .mono:
            return .monospacedSystemFont(ofSize: size, weight: .regular)
        case .writer:
            return UIFont(name: "iAWriterQuattroS-Regular", size: size)
                ?? .systemFont(ofSize: size)
        case .code:
            return UIFont(name: "JetBrainsMono-Regular", size: size)
                ?? .monospacedSystemFont(ofSize: size, weight: .regular)
        }
    }

    var swiftUIFont: Font {
        switch self {
        case .system:
            return .system(.body, design: .default)
        case .rounded:
            return .system(.body, design: .rounded)
        case .serif:
            return .custom("Charter-Roman", size: 17, relativeTo: .body)
        case .mono:
            return .system(.body, design: .monospaced)
        case .writer:
            return .custom("iAWriterQuattroS-Regular", size: 17, relativeTo: .body)
        case .code:
            return .custom("JetBrainsMono-Regular", size: 17, relativeTo: .body)
        }
    }

    var cssFamily: String {
        switch self {
        case .system:  return "-apple-system, system-ui, sans-serif"
        case .rounded: return "ui-rounded, -apple-system, sans-serif"
        case .serif:   return "Charter, 'Charter-Roman', ui-serif, 'New York', Georgia, serif"
        case .mono:    return "ui-monospace, 'SF Mono', Menlo, monospace"
        case .writer:  return "'iAWriterQuattroS-Regular', 'iA Writer Quattro S', -apple-system, sans-serif"
        case .code:    return "'JetBrainsMono-Regular', 'JetBrains Mono', ui-monospace, monospace"
        }
    }

    var cssStretch: String { "normal" }
}

enum NewFileMode: String, CaseIterable, Identifiable {
    case edit, preview

    var id: String { rawValue }

    var label: String {
        switch self {
        case .edit:    return "Edit"
        case .preview: return "Preview"
        }
    }
}

// Kept for migration from the old free-form accent color picker.
enum AccentColorStore {
    static let storageKey = "accentColorHex"
    static let defaultHex = "#7869E4"
}

struct HexColor {
    static func color(fromHex hex: String) -> Color {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6, let value = UInt32(cleaned, radix: 16) else {
            return color(fromHex: AccentColorStore.defaultHex)
        }
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b)
    }

    static func hex(from color: Color) -> String {
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        let ri = Int((r * 255).rounded())
        let gi = Int((g * 255).rounded())
        let bi = Int((b * 255).rounded())
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }
}
