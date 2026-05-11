import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(AppPreferences.themeIDKey) private var themeID: String = AppThemeCatalog.defaultID
    @AppStorage(AppPreferences.appearanceKey) private var appearance: String = AppearancePreference.system.rawValue
    @AppStorage(AppPreferences.documentFontKey) private var fontRaw: String = DocumentFont.system.rawValue
    @AppStorage(AppPreferences.editorFontSizeKey) private var editorFontSize: Double = 16
    @AppStorage(AppPreferences.previewFontSizeKey) private var previewFontSize: Double = 17
    @AppStorage(AppPreferences.newFileModeKey) private var newFileMode: String = NewFileMode.edit.rawValue

    @State private var recents = RecentsStore.shared
    @State private var showClearRecentsConfirm = false

    private var themeColor: Color {
        AppThemeCatalog.theme(for: themeID).accentColor
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Mode", selection: $appearance) {
                        ForEach(AppearancePreference.allCases) { pref in
                            Text(pref.label).tag(pref.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Appearance")
                }

                Section {
                    ForEach(AppThemeCatalog.all) { theme in
                        Button {
                            themeID = theme.id
                        } label: {
                            HStack(spacing: 14) {
                                Circle()
                                    .fill(theme.accentColor)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                                    )
                                Text(theme.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if themeID == theme.id {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.tint)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Theme")
                }

                Section {
                    NavigationLink {
                        FontPickerList(selection: $fontRaw)
                    } label: {
                        HStack {
                            Text("Font")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text((DocumentFont(rawValue: fontRaw) ?? .system).label)
                                .font((DocumentFont(rawValue: fontRaw) ?? .system).swiftUIFont)
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Editor size")
                            Spacer()
                            Text("\(Int(editorFontSize))pt")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $editorFontSize, in: 12...24, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Preview size")
                            Spacer()
                            Text("\(Int(previewFontSize))pt")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $previewFontSize, in: 12...24, step: 1)
                    }
                } header: {
                    Text("Text")
                } footer: {
                    Text("Font applies to both Edit and Preview. Pinch-to-zoom still adjusts sizes per document.")
                }

                Section {
                    Picker("New files open in", selection: $newFileMode) {
                        ForEach(NewFileMode.allCases) { mode in
                            Text(mode.label).tag(mode.rawValue)
                        }
                    }
                } header: {
                    Text("Behavior")
                }

                if !recents.entries.isEmpty {
                    Section {
                        Button(role: .destructive) {
                            showClearRecentsConfirm = true
                        } label: {
                            HStack {
                                Text("Clear recents")
                                Spacer()
                                Text("\(recents.entries.count)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text("Recents")
                    }
                }

                Section {
                    Link("santiagoalonso.com", destination: URL(string: "https://santiagoalonso.com")!)
                    Link("Support", destination: URL(string: "https://github.com/madebysan/markflow/blob/main/docs/support.md")!)
                    Link("Privacy", destination: URL(string: "https://github.com/madebysan/markflow/blob/main/docs/privacy-policy.md")!)
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .confirmationDialog(
                "Clear all recents?",
                isPresented: $showClearRecentsConfirm,
                titleVisibility: .visible
            ) {
                Button("Clear", role: .destructive) {
                    recents.clear()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes the list of recently opened files. Your actual files are not deleted.")
            }
            .tint(themeColor)
        }
        .preferredColorScheme(AppearancePreference(rawValue: appearance)?.colorScheme)
        .tint(themeColor)
    }
}

private struct FontPickerList: View {
    @Binding var selection: String

    var body: some View {
        Form {
            ForEach(DocumentFont.allCases) { font in
                Button {
                    selection = font.rawValue
                } label: {
                    HStack {
                        Text(font.label)
                            .font(font.swiftUIFont)
                            .foregroundStyle(.primary)
                        Spacer()
                        if font.rawValue == selection {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.tint)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Font")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
}
