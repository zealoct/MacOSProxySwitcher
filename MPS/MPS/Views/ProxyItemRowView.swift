import SwiftUI

struct ProxyItemRowView: View {
    @Binding var item: ProxyItem
    var onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Toggle(item.type.rawValue, isOn: $item.enabled)
                    .onChange(of: item.enabled) { _ in onSave() }
                Spacer()
            }

            if item.enabled {
                switch item.type {
                case .pac:
                    HStack {
                        Text("URL:")
                            .frame(width: 60, alignment: .trailing)
                        TextField("PAC URL", text: Binding(
                            get: { item.pacURL ?? "" },
                            set: { item.pacURL = $0.isEmpty ? nil : $0; onSave() }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }

                case .http, .https:
                    proxyHostPortFields()
                    proxyAuthFields()

                case .socks:
                    proxyHostPortFields()
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func proxyHostPortFields() -> some View {
        HStack {
            Text("Host:")
                .frame(width: 60, alignment: .trailing)
            TextField("Host", text: Binding(
                get: { item.host ?? "" },
                set: { item.host = $0.isEmpty ? nil : $0; onSave() }
            ))
            .textFieldStyle(.roundedBorder)

            Text("Port:")
                .frame(width: 60, alignment: .trailing)
            TextField("Port", value: Binding(
                get: { item.port ?? 0 },
                set: { item.port = $0 == 0 ? nil : $0; onSave() }
            ), format: .number)
            .textFieldStyle(.roundedBorder)
            .frame(width: 80)
        }
    }

    private func proxyAuthFields() -> some View {
        HStack {
            Text("User:")
                .frame(width: 60, alignment: .trailing)
            TextField("Username", text: Binding(
                get: { item.username ?? "" },
                set: { item.username = $0.isEmpty ? nil : $0; onSave() }
            ))
            .textFieldStyle(.roundedBorder)

            Text("Pass:")
                .frame(width: 60, alignment: .trailing)
            SecureField("Password", text: Binding(
                get: { item.password ?? "" },
                set: { item.password = $0.isEmpty ? nil : $0; onSave() }
            ))
            .textFieldStyle(.roundedBorder)
        }
    }
}