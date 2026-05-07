import SwiftUI

struct ManageConfigurationsView: View {
    @ObservedObject var viewModel: ProxyViewModel
    @State private var selectedProfileId: UUID?
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationSplitView {
            List(viewModel.profiles, selection: $selectedProfileId) { profile in
                Text(profile.name)
                    .tag(profile.id)
            }
            .navigationTitle("Profiles")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: addProfile) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { showDeleteConfirmation = true }) {
                        Image(systemName: "minus")
                    }
                    .disabled(selectedProfileId == nil)
                }
            }
            .alert("Delete Profile?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteSelectedProfile()
                }
            } message: {
                if let name = selectedProfileName {
                    Text("Are you sure you want to delete \"\(name)\"? This cannot be undone.")
                } else {
                    Text("Are you sure you want to delete this profile?")
                }
            }
        } detail: {
            if let selectedId = selectedProfileId,
               let index = viewModel.profiles.firstIndex(where: { $0.id == selectedId }) {
                ProfileEditView(profile: $viewModel.profiles[index], onSave: {
                    viewModel.updateProfile(viewModel.profiles[index])
                })
            } else {
                Text("Select a profile to edit")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if selectedProfileId == nil && !viewModel.profiles.isEmpty {
                selectedProfileId = viewModel.profiles.first?.id
            }
        }
    }

    private var selectedProfileName: String? {
        viewModel.profiles.first(where: { $0.id == selectedProfileId })?.name
    }

    private func addProfile() {
        let profile = viewModel.addProfile(name: "New Profile")
        selectedProfileId = profile.id
    }

    private func deleteSelectedProfile() {
        guard let id = selectedProfileId else { return }
        viewModel.deleteProfile(id: id)
        selectedProfileId = viewModel.profiles.first?.id
    }
}