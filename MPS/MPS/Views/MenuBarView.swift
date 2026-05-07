import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: ProxyViewModel
    @Environment(\.openWindow) var openWindow

    var body: some View {
        Text(viewModel.currentProxyDescription)
            .font(.caption)

        ForEach(viewModel.proxyDetailLines, id: \.self) { line in
            Text(line)
                .font(.caption2)
                .foregroundColor(.secondary)
        }

        Divider()

        Picker(selection: Binding(
            get: { viewModel.activeProfileId },
            set: { newId in
                DispatchQueue.main.async {
                    if let id = newId {
                        viewModel.switchToProfile(id: id)
                    } else {
                        viewModel.switchToDirect()
                    }
                }
            }
        ), label: EmptyView()) {
            Text("Direct / No Proxy").tag(nil as UUID?)
            ForEach(viewModel.profiles) { profile in
                Text(profile.name).tag(profile.id as UUID?)
            }
        }
        .pickerStyle(.inline)

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