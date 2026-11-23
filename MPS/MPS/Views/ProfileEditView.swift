import SwiftUI

struct ProfileEditView: View {
    @Binding var profile: ProxyProfile
    var onSave: () -> Void
    @FocusState private var isNameFocused: Bool

    var body: some View {
        Form {
            TextField("Profile Name", text: $profile.name)
                .focused($isNameFocused)
                .onChange(of: profile.name) { _ in onSave() }

            ForEach($profile.items) { $item in
                ProxyItemRowView(item: $item, onSave: onSave)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear { isNameFocused = true }
    }
}
