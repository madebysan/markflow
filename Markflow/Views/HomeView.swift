import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(AppPreferences.themeIDKey) private var themeID: String = AppThemeCatalog.defaultID
    @State private var showFileImporter = false
    @State private var openedDocument: OpenedDocument?
    @State private var accessURL: URL?
    @State private var didAnimateIn = false
    @State private var showSettings = false
    @State private var recents = RecentsStore.shared

    private var themeColor: Color {
        AppThemeCatalog.theme(for: themeID).accentColor
    }

    private let markdownType = UTType("net.daringfireball.markdown") ?? .plainText
    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: hasRecents ? 56 : 40)

                brandStack
                    .opacity(didAnimateIn ? 1 : 0)
                    .offset(y: didAnimateIn ? 0 : 14)

                Spacer()

                if hasRecents {
                    recentsSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                        .opacity(didAnimateIn ? 1 : 0)
                        .offset(y: didAnimateIn ? 0 : 14)
                }

                actionStack
                    .padding(.horizontal, 24)
                    .opacity(didAnimateIn ? 1 : 0)
                    .offset(y: didAnimateIn ? 0 : 18)

                credit
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                    .opacity(didAnimateIn ? 1 : 0)
            }

            settingsButton
                .opacity(didAnimateIn ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                didAnimateIn = true
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [markdownType, .plainText]
        ) { result in
            if case .success(let url) = result {
                open(url: url)
            }
        }
        .fullScreenCover(item: $openedDocument) { doc in
            DocumentContainer(openedDocument: doc) {
                releaseAccess()
                openedDocument = nil
            }
        }
        .onOpenURL { url in
            open(url: url)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private var settingsButton: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.primary.opacity(0.6))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Settings")
            }
            Spacer()
        }
        .padding(.top, 8)
        .padding(.trailing, 8)
    }

    // MARK: - Subviews

    private var backgroundGradient: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    Color(red: 0.10, green: 0.10, blue: 0.13),
                    Color(red: 0.14, green: 0.12, blue: 0.18)
                ]
                : [
                    Color(red: 0.98, green: 0.98, blue: 0.99),
                    Color(red: 0.94, green: 0.93, blue: 0.97)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var brandStack: some View {
        VStack(spacing: 20) {
            Image("HomeIcon")
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: 128, height: 128)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.25 : 0.6),
                                    Color.white.opacity(0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: themeColor.opacity(colorScheme == .dark ? 0.45 : 0.25),
                    radius: 18, x: 0, y: 10
                )

            VStack(spacing: 8) {
                Text("Markflow")
                    .font(.system(size: 42, weight: .bold))
                    .tracking(-0.8)
                    .foregroundStyle(.primary)

                Text("The markdown reader\nyou've been missing.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.primary.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
    }

    private var actionStack: some View {
        VStack(spacing: 12) {
            // Primary — Browse
            Button {
                showFileImporter = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Browse")
                        .font(.system(size: 18, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .foregroundStyle(.white)
                .background(themeColor)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(
                    color: themeColor.opacity(colorScheme == .dark ? 0.55 : 0.4),
                    radius: 18, x: 0, y: 10
                )
            }
            .buttonStyle(PressScaleStyle())

            // Secondary — Create
            Button {
                openedDocument = OpenedDocument(text: Self.newDocumentTemplate(), sourceURL: nil)
            } label: {
                whiteLabel(icon: "square.and.pencil", title: "Create")
            }
            .buttonStyle(PressScaleStyle())

            if !hasRecents {
                // Secondary — Welcome tour (hidden once user has any recents)
                Button {
                    openedDocument = OpenedDocument(text: Self.welcomeTemplate(), sourceURL: nil)
                } label: {
                    whiteLabel(icon: "sparkles", title: "Welcome to Markflow")
                }
                .buttonStyle(PressScaleStyle())
            }
        }
    }

    private var hasRecents: Bool {
        !recents.entries.isEmpty
    }

    private var recentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.55))
                    .textCase(.uppercase)
                    .tracking(0.4)
                Spacer()
            }
            .padding(.horizontal, 4)

            VStack(spacing: 6) {
                ForEach(recents.entries.prefix(4)) { entry in
                    Button {
                        openRecent(entry)
                    } label: {
                        recentRow(entry)
                    }
                    .buttonStyle(PressScaleStyle())
                }
            }
        }
    }

    private func recentRow(_ entry: RecentEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.primary.opacity(0.55))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(Self.relativeFormatter.localizedString(for: entry.lastOpened, relativeTo: Date()))
                    .font(.system(size: 12))
                    .foregroundStyle(.primary.opacity(0.5))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.3))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
    }

    private func openRecent(_ entry: RecentEntry) {
        guard let url = recents.resolve(entry) else { return }
        open(url: url)
    }

    private func whiteLabel(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
            Text(title)
                .font(.system(size: 18, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .foregroundStyle(.black)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    }

    private var credit: some View {
        Link(destination: URL(string: "https://santiagoalonso.com")!) {
            Text("Made by santiagoalonso.com")
                .font(.system(size: 13, weight: .medium))
        }
        .tint(.primary.opacity(0.5))
    }

    // MARK: - Welcome template

    private static func welcomeTemplate() -> String {
        if let url = Bundle.main.url(forResource: "welcome", withExtension: "md"),
           let text = try? String(contentsOf: url, encoding: .utf8) {
            return text
        }
        return "# Welcome\n\nStart writing…"
    }

    private static func newDocumentTemplate() -> String {
        """
        # Untitled

        Start writing your markdown here.

        """
    }

    // MARK: - Opening files

    private func open(url: URL) {
        // Guard re-entry: rapid taps (e.g. recent + onOpenURL race) could
        // orphan a startAccessingSecurityScopedResource by claiming a new
        // URL while the previous fullScreenCover is still presenting.
        guard openedDocument == nil else { return }

        // Release any prior access before claiming a new one (defensive).
        releaseAccess()
        let didAccess = url.startAccessingSecurityScopedResource()
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            openedDocument = OpenedDocument(text: text, sourceURL: url)
            recents.add(url: url)
            // Keep access alive until the document view closes so Save can
            // write back to the original file.
            if didAccess {
                accessURL = url
            }
        } catch {
            if didAccess { url.stopAccessingSecurityScopedResource() }
            print("Markflow: failed to read \(url.lastPathComponent): \(error)")
        }
    }

    private func releaseAccess() {
        if let url = accessURL {
            url.stopAccessingSecurityScopedResource()
            accessURL = nil
        }
    }
}

// MARK: - Press-state button style

private struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Opened document model

struct OpenedDocument: Identifiable {
    let id = UUID()
    let text: String
    let sourceURL: URL?
}

// MARK: - Document container

private struct DocumentContainer: View {
    let openedDocument: OpenedDocument
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            DocumentView(
                documentText: openedDocument.text,
                sourceURL: openedDocument.sourceURL,
                onClose: onClose
            )
        }
    }
}

#Preview {
    HomeView()
}
