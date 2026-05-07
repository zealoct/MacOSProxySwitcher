import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: ProxyViewModel
    @Environment(\.openWindow) var openWindow

    var body: some View {
        Text(viewModel.currentProxyDescription)
            .font(.caption)

        Divider()

        Button("Direct / No Proxy") {
            viewModel.switchToDirect()
        }
        .checkmark(visible: viewModel.activeProfileId == nil)

        ForEach(viewModel.profiles) { profile in
            Button(profile.name) {
                viewModel.switchToProfile(id: profile.id)
            }
            .checkmark(visible: viewModel.activeProfileId == profile.id)
        }

        Divider()

        Button("Manage Configurations...") {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "manage-configurations")
        }

        Divider()

        Button("Quit MPS") {
            NSApp.terminate(nil)
        }
    }
}

extension Button {
    func checkmark(visible: Bool) -> some View {
        HStack {
            if visible {
                Image(systemName: "checkmark")
            }
            self
            Spacer()
        }
    }
}