import Foundation
import Combine

class ProxyViewModel: ObservableObject {
    @Published var profiles: [ProxyProfile] = []
    @Published var activeProfileId: UUID?

    private let storageService = StorageService()
    private let proxyService = ProxyService()

    init() {
        loadFromStorage()
    }

    var activeProfile: ProxyProfile? {
        profiles.first(where: { $0.id == activeProfileId })
    }

    var currentProxyDescription: String {
        if let profile = activeProfile {
            return "Active: \(profile.name)"
        }
        let systemState = proxyService.readAllProxyState()
        let hasAny = systemState.pac.enabled || systemState.http.enabled
            || systemState.https.enabled || systemState.socks.enabled
        if hasAny {
            return "Custom proxy (not managed by MPS)"
        }
        return "Direct connection (No proxy)"
    }

    func loadFromStorage() {
        profiles = storageService.loadProfiles()
        activeProfileId = storageService.loadActiveProfileId()
        reconcileWithSystemState()
    }

    func reconcileWithSystemState() {
        let systemState = proxyService.readAllProxyState()
        let hasAny = systemState.pac.enabled || systemState.http.enabled
            || systemState.https.enabled || systemState.socks.enabled

        if !hasAny {
            activeProfileId = nil
            return
        }

        // Check if current active profile matches system state
        if let profile = activeProfile, systemState.matchesProfile(profile) {
            return
        }

        // Try to find a profile that matches current system state
        let matched = profiles.first(where: { systemState.matchesProfile($0) })
        activeProfileId = matched?.id
    }

    func switchToProfile(id: UUID) {
        guard let profile = profiles.first(where: { $0.id == id }) else { return }
        proxyService.applyProfile(profile)
        activeProfileId = id
        storageService.saveActiveProfileId(id)
        storageService.saveProfiles(profiles)
    }

    func switchToDirect() {
        proxyService.disableAllProxies()
        activeProfileId = nil
        storageService.saveActiveProfileId(nil)
    }

    func addProfile(name: String) -> ProxyProfile {
        let profile = ProxyProfile.createDefault(name: name)
        profiles.append(profile)
        storageService.saveProfiles(profiles)
        return profile
    }

    func deleteProfile(id: UUID) {
        profiles.removeAll(where: { $0.id == id })
        if activeProfileId == id {
            proxyService.disableAllProxies()
            activeProfileId = nil
            storageService.saveActiveProfileId(nil)
        }
        storageService.saveProfiles(profiles)
    }

    func updateProfile(_ profile: ProxyProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
        }
        storageService.saveProfiles(profiles)

        // If this is the active profile, re-apply it
        if activeProfileId == profile.id {
            proxyService.applyProfile(profile)
        }
    }
}