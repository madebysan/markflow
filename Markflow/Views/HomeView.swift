import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var showFileImporter = false
    @State private var openedDocument: OpenedDocument?
    @State private var accessURL: URL?
    @State private var didAnimateIn = false
    @State private var orbDrift = false

    private let markdownType = UTType("net.daringfireball.markdown") ?? .plainText

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            // Ambient orbs — transform-based drift (GPU only, no layout pass).
            ZStack {
                orb(
                    color: Color(red: 0.56, green: 0.42, blue: 0.95),
                    size: 360,
                    opacity: colorScheme == .dark ? 0.55 : 0.40
                )
                .offset(x: orbDrift ? -100 : 100, y: -240)

                orb(
                    color: Color(red: 0.40, green: 0.58, blue: 1.00),
                    size: 320,
                    opacity: colorScheme == .dark ? 0.45 : 0.30
                )
                .offset(x: orbDrift ? 120 : -120, y: 260)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer(minLength: 40)

                brandStack
                    .opacity(didAnimateIn ? 1 : 0)
                    .offset(y: didAnimateIn ? 0 : 14)

                Spacer()

                actionStack
                    .padding(.horizontal, 24)
                    .opacity(didAnimateIn ? 1 : 0)
                    .offset(y: didAnimateIn ? 0 : 18)

                credit
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                    .opacity(didAnimateIn ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) {
                didAnimateIn = true
            }
            withAnimation(.easeInOut(duration: 14).repeatForever(autoreverses: true)) {
                orbDrift.toggle()
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
    }

    // MARK: - Subviews

    private var backgroundGradient: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [
                    Color(red: 0.06, green: 0.04, blue: 0.14),
                    Color(red: 0.12, green: 0.07, blue: 0.22)
                ]
                : [
                    Color(red: 0.95, green: 0.96, blue: 1.00),
                    Color(red: 0.89, green: 0.86, blue: 1.00)
                ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func orb(color: Color, size: CGFloat, opacity: Double) -> some View {
        // Radial gradient is already soft — no extra blur needed.
        RadialGradient(
            colors: [color.opacity(opacity), color.opacity(0)],
            center: .center,
            startRadius: 0,
            endRadius: size / 2
        )
        .frame(width: size, height: size)
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
                    color: Color(red: 0.35, green: 0.30, blue: 0.80)
                        .opacity(colorScheme == .dark ? 0.55 : 0.28),
                    radius: 18, x: 0, y: 10
                )

            VStack(spacing: 8) {
                Text("Markflow")
                    .font(.system(size: 42, weight: .bold))
                    .tracking(-0.8)
                    .foregroundStyle(.primary)

                Text("The iOS reader markdown\nwas missing.")
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
                .background(primaryGradient)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(
                    color: Color(red: 0.42, green: 0.38, blue: 0.92)
                        .opacity(colorScheme == .dark ? 0.65 : 0.45),
                    radius: 18, x: 0, y: 10
                )
            }
            .buttonStyle(PressScaleStyle())

            // Secondary — Create
            Button {
                openedDocument = OpenedDocument(text: "", sourceURL: nil)
            } label: {
                secondaryLabel(icon: "square.and.pencil", title: "Create")
            }
            .buttonStyle(PressScaleStyle())

            // Tertiary — Welcome tour
            Button {
                openedDocument = OpenedDocument(text: Self.welcomeTemplate(), sourceURL: nil)
            } label: {
                secondaryLabel(icon: "sparkles", title: "Welcome to Markflow")
            }
            .buttonStyle(PressScaleStyle())
        }
    }

    private func secondaryLabel(icon: String, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
            Text(title)
                .font(.system(size: 18, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .foregroundStyle(.primary)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
        )
    }

    private var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.46, green: 0.50, blue: 0.95),
                Color(red: 0.56, green: 0.42, blue: 0.95)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var credit: some View {
        Link(destination: URL(string: "https://santiagoalonso.com")!) {
            Text("Made by santiagoalonso.com")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    // MARK: - Welcome template

    private static func welcomeTemplate() -> String {
        if let url = Bundle.main.url(forResource: "welcome", withExtension: "md"),
           let text = try? String(contentsOf: url, encoding: .utf8) {
            return text
        }
        return "# Welcome\n\nStart writing…"
    }

    // MARK: - Opening files

    private func open(url: URL) {
        // Release any prior access before claiming a new one.
        releaseAccess()
        let didAccess = url.startAccessingSecurityScopedResource()
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            openedDocument = OpenedDocument(text: text, sourceURL: url)
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
            .navigationTitle(title)
            .toolbarTitleDisplayMode(.inline)
        }
    }

    private var title: String {
        openedDocument.sourceURL?.lastPathComponent ?? "Untitled.md"
    }
}

#Preview {
    HomeView()
}
