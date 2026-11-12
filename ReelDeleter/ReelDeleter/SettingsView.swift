import SwiftUI

/// Opens with a two-finger long press anywhere in the app, or from reeldeleter://settings.
struct SettingsView: View {
    @ObservedObject private var settings = FilterSettings.shared
    private let store = WebStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var confirmClear = false
    @State private var reportStatus: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Hide Reels tabs", isOn: $settings.hideReelsTab)
                    Toggle("Block every Reels page", isOn: $settings.blockReels)
                    Toggle("Still allow Reels sent in DMs", isOn: $settings.allowDMReels)
                        .disabled(!settings.blockReels)
                } header: {
                    Text("Reels")
                } footer: {
                    Text("A blocked page sends you back to where you were.")
                }

                Section {
                    Toggle("Hide and block Explore", isOn: $settings.hideExplore)
                } header: {
                    Text("Other tabs")
                }

                Section {
                    TextEditor(text: $settings.customCSS)
                        .font(.system(.footnote, design: .monospaced))
                        .frame(minHeight: 150)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Custom CSS")
                } footer: {
                    Text("Added to every Instagram page. Example: a[href=\"/explore/\"] { display: none !important }")
                }

                Section {
                    Toggle("Send a Safari-style user agent", isOn: $settings.safariUserAgent)
                    Button("Copy page report") {
                        store.copyPageReport { ok in
                            reportStatus = ok ? "Copied. Paste it into your chat." : "Couldn't read the page."
                        }
                    }
                    Button("Reload Instagram") { store.webView.reload() }
                    Button("Log out and clear site data", role: .destructive) { confirmClear = true }
                } header: {
                    Text("Advanced")
                } footer: {
                    Text(reportStatus ?? "The page report lists link paths and labels from the screen behind this sheet, to help work out why something isn't hidden. It can include usernames.")
                }
            }
            .navigationTitle("Reel Deleter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Log out of Instagram in this app?",
                                isPresented: $confirmClear,
                                titleVisibility: .visible) {
                Button("Log out and clear data", role: .destructive) {
                    store.clearData()
                    dismiss()
                }
            }
        }
    }
}
