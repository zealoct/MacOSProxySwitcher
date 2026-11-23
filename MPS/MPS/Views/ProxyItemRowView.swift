import SwiftUI

struct ProxyItemRowView: View {
    @Binding var item: ProxyItem
    var onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(item.type.rawValue, isOn: $item.enabled)
                .onChange(of: item.enabled) { _ in onSave() }

            if item.enabled {
                switch item.type {
                case .pac:
                    HStack(spacing: 4) {
                        Text("URL:")
                            .frame(width: 38, alignment: .trailing)
                        TextField("", text: Binding(
                            get: { item.pacURL ?? "" },
                            set: { item.pacURL = $0.isEmpty ? nil : $0; onSave() }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }

                case .http, .https:
                    proxyHostPortRow()
                    proxyAuthRow()

                case .socks:
                    proxyHostPortRow()
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func proxyHostPortRow() -> some View {
        HStack(spacing: 4) {
            Text("Host:")
                .frame(width: 38, alignment: .trailing)
            TextField("", text: Binding(
                get: { item.host ?? "" },
                set: { item.host = $0.isEmpty ? nil : $0; onSave() }
            ))
            .textFieldStyle(.roundedBorder)
            .frame(width: 150)

            Text("Port:")
                .frame(width: 38, alignment: .trailing)
            TextField("", value: Binding(
                get: { item.port ?? 0 },
                set: { item.port = $0 == 0 ? nil : $0; onSave() }
            ), format: .number)
            .textFieldStyle(.roundedBorder)
            .frame(width: 70)
        }
    }

    private func proxyAuthRow() -> some View {
        HStack(spacing: 4) {
            Text("User:")
                .frame(width: 38, alignment: .trailing)
            TextField("", text: Binding(
                get: { item.username ?? "" },
                set: { item.username = $0.isEmpty ? nil : $0; onSave() }
            ))
            .textFieldStyle(.roundedBorder)
            .frame(width: 150)

            Text("Pass:")
                .frame(width: 38, alignment: .trailing)
            SecureField("", text: Binding(
                get: { item.password ?? "" },
                set: { item.password = $0.isEmpty ? nil : $0; onSave() }
            ))
            .textFieldStyle(.roundedBorder)
            .frame(width: 70)
        }
    }
}