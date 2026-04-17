import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var showFileImporter = false
    @State private var openedDocument: OpenedDocument?

    private let markdownType = UTType("net.daringfireball.markdown") ?? .plainText

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 40)

                brandStack

                Spacer()

                actionStack
                    .padding(.horizontal, 24)

                credit
                    .padding(.top, 28)
                    .padding(.bottom, 32)
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
                    Color(red: 0.08, green: 0.06, blue: 0.18),
                    Color(red: 0.14, green: 0.09, blue: 0.26)
                ]
                : [
                    Color(red: 0.93, green: 0.94, blue: 1.00),
                    Color(red: 0.87, green: 0.84, blue: 1.00)
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
                .shadow(
                    color: Color(red: 0.35, green: 0.30, blue: 0.80)
                        .opacity(colorScheme == .dark ? 0.55 : 0.28),
                    radius: 28, x: 0, y: 14
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

            // Secondary — Create
            Button {
                openedDocument = OpenedDocument(text: "", sourceURL: nil)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 18, weight: .medium))
                    Text("Create")
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
        }
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
            HStack(spacing: 4) {
                Text("Made by")
                    .foregroundStyle(.primary.opacity(0.55))
                Text("santiagoalonso.com")
                    .foregroundStyle(.primary.opacity(0.80))
                    .underline()
            }
            .font(.system(size: 13, weight: .medium))
        }
    }

    // MARK: - Opening files

    private func open(url: URL) {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess { url.stopAccessingSecurityScopedResource() }
        }
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            openedDocument = OpenedDocument(text: text, sourceURL: url)
        } catch {
            print("Markflow: failed to read \(url.lastPathComponent): \(error)")
        }
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
