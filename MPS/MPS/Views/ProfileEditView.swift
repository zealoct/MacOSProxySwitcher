import SwiftUI

struct ProfileEditView: View {
    @Binding var profile: ProxyProfile
    var onSave: () -> Void

    var body: some View {
        Form {
            TextField("Profile Name", text: $profile.name)
                .onChange(of: profile.name) { _ in onSave() }

            ForEach($profile.items) { $item in
                ProxyItemRowView(item: $item, onSave: onSave)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}