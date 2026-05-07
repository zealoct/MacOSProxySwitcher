import Foundation
import Combine

class ProxyViewModel: ObservableObject {
    @Published var profiles: [ProxyProfile] = []
    @Published var activeProfileId: UUID?
    @Published var currentProxyDescription: String = "Direct connection (No proxy)"
    @Published var proxyDetailLines: [String] = ["PAC: disabled", "HTTP: disabled", "HTTPS: disabled", "SOCKS: disabled"]

    private let storageService = StorageService()
    private let proxyService = ProxyService()
    private let proxyMonitor = ProxyMonitor()
    private let workQueue = DispatchQueue(label: "mps.proxy", qos: .userInitiated)

    init() {
        loadFromStorage()
        proxyMonitor.start { [weak self] in
            self?.workQueue.async {
                self?.reconcileWithSystemState()
            }
        }
    }

    var activeProfile: ProxyProfile? {
        profiles.first(where: { $0.id == activeProfileId })
    }

    // MARK: - Heavy I/O on background queue, publish on main

    private func refreshDisplayState() {
        let state = proxyService.readAllProxyState()
        let hasAny = state.pac.enabled || state.http.enabled
            || state.https.enabled || state.socks.enabled

        let desc: String
        if let profile = activeProfile {
            desc = "Active: \(profile.name)"
        } else if hasAny {
            desc = "Custom proxy (not managed by MPS)"
        } else {
            desc = "Direct connection (No proxy)"
        }

        let items: [(String, Bool, String?)] = [
            ("PAC", state.pac.enabled, state.pac.enabled ? state.pac.url : nil),
            ("HTTP", state.http.enabled, state.http.enabled ? "\(state.http.host ?? ""):\(state.http.port ?? 0)" : nil),
            ("HTTPS", state.https.enabled, state.https.enabled ? "\(state.https.host ?? ""):\(state.https.port ?? 0)" : nil),
            ("SOCKS", state.socks.enabled, state.socks.enabled ? "\(state.socks.host ?? ""):\(state.socks.port ?? 0)" : nil),
        ]
        let lines = items.map { type, enabled, detail in
            enabled ? "\(type): \(detail ?? "—")" : "\(type): disabled"
        }

        DispatchQueue.main.async {
            self.currentProxyDescription = desc
            self.proxyDetailLines = lines
        }
    }

    func reconcileWithSystemState() {
        let systemState = proxyService.readAllProxyState()
        let hasAny = systemState.pac.enabled || systemState.http.enabled
            || systemState.https.enabled || systemState.socks.enabled

        var newActiveId: UUID? = nil
        if !hasAny {
            newActiveId = nil
        } else if let profile = activeProfile, systemState.matchesProfile(profile) {
            newActiveId = profile.id
        } else {
            newActiveId = profiles.first(where: { systemState.matchesProfile($0) })?.id
        }

        DispatchQueue.main.async {
            self.activeProfileId = newActiveId
        }

        refreshDisplayState()
    }

    func loadFromStorage() {
        profiles = storageService.loadProfiles()
        activeProfileId = storageService.loadActiveProfileId()

        workQueue.async {
            self.reconcileWithSystemState()
        }
    }

    func switchToProfile(id: UUID) {
        guard let profile = profiles.first(where: { $0.id == id }) else { return }

        // Update UI instantly from profile data (no I/O needed)
        DispatchQueue.main.async {
            self.activeProfileId = id
            self.currentProxyDescription = "Active: \(profile.name)"
            let items: [(String, Bool, String?)] = profile.items.map { item in
                let detail: String?
                switch item.type {
                case .pac:
                    detail = item.enabled ? item.pacURL : nil
                case .http, .https, .socks:
                    detail = item.enabled ? "\(item.host ?? ""):\(item.port ?? 0)" : nil
                }
                return (item.type.rawValue, item.enabled, detail)
            }
            self.proxyDetailLines = items.map { type, enabled, detail in
                enabled ? "\(type): \(detail ?? "—")" : "\(type): disabled"
            }
        }

        storageService.saveActiveProfileId(id)
        storageService.saveProfiles(profiles)

        // Apply proxy and refresh display from system state on background queue
        workQueue.async {
            self.proxyService.applyProfile(profile)
            self.refreshDisplayState()
        }
    }

    func switchToDirect() {
        DispatchQueue.main.async {
            self.activeProfileId = nil
            self.currentProxyDescription = "Direct connection (No proxy)"
            self.proxyDetailLines = ["PAC: disabled", "HTTP: disabled", "HTTPS: disabled", "SOCKS: disabled"]
        }

        storageService.saveActiveProfileId(nil)

        workQueue.async {
            self.proxyService.disableAllProxies()
            self.refreshDisplayState()
        }
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
            workQueue.async {
                self.proxyService.disableAllProxies()
                DispatchQueue.main.async {
                    self.activeProfileId = nil
                }
                self.refreshDisplayState()
            }
            storageService.saveActiveProfileId(nil)
        }
        storageService.saveProfiles(profiles)
    }

    func updateProfile(_ profile: ProxyProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
        }
        storageService.saveProfiles(profiles)

        if activeProfileId == profile.id {
            workQueue.async {
                self.proxyService.applyProfile(profile)
                self.refreshDisplayState()
            }
        }
    }
}