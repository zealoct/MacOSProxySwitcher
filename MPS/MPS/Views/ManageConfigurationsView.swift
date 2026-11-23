import SwiftUI

struct ManageConfigurationsView: View {
    @ObservedObject var viewModel: ProxyViewModel
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                List(viewModel.profiles, selection: $viewModel.selectedProfileId) { profile in
                    Text(profile.name)
                        .tag(profile.id)
                }

                HStack(spacing: 12) {
                    Button(action: addProfile) {
                        Image(systemName: "plus")
                    }
                    Button(action: { showDeleteConfirmation = true }) {
                        Image(systemName: "minus")
                    }
                    .disabled(viewModel.selectedProfileId == nil)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .navigationTitle("Profiles")
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
            if viewModel.isSavingCurrentProfile {
                ProgressView("Reading current proxy settings...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let selectedId = viewModel.selectedProfileId,
               let index = viewModel.profiles.firstIndex(where: { $0.id == selectedId }) {
                ProfileEditView(profile: $viewModel.profiles[index], onSave: {
                    viewModel.updateProfile(viewModel.profiles[index])
                })
                .id(selectedId)
            } else {
                Text("Select a profile to edit")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if viewModel.selectedProfileId == nil && !viewModel.profiles.isEmpty {
                viewModel.selectedProfileId = viewModel.profiles.first?.id
            }
        }
        .alert("Couldn't Save Current Settings", isPresented: Binding(
            get: { viewModel.saveCurrentError != nil },
            set: { if !$0 { viewModel.saveCurrentError = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.saveCurrentError = nil }
        } message: {
            Text(viewModel.saveCurrentError ?? "")
        }
    }

    private var selectedProfileName: String? {
        viewModel.profiles.first(where: { $0.id == viewModel.selectedProfileId })?.name
    }

    private func addProfile() {
        let profile = viewModel.addProfile(name: "New Profile")
        viewModel.selectedProfileId = profile.id
    }

    private func deleteSelectedProfile() {
        guard let id = viewModel.selectedProfileId else { return }
        viewModel.deleteProfile(id: id)
        viewModel.selectedProfileId = viewModel.profiles.first?.id
    }
}
