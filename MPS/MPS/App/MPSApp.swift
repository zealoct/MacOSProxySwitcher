import SwiftUI

@main
struct MPSApp: App {
    @StateObject private var viewModel = ProxyViewModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // ViewModel will load data on first access
    }

    var body: some Scene {
        MenuBarExtra("MPS", systemImage: "globe") {
            MenuBarView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.menu)

        Window("Manage Configurations", id: "manage-configurations") {
            ManageConfigurationsView(viewModel: viewModel)
        }
        .defaultSize(width: 700, height: 450)
    }
}