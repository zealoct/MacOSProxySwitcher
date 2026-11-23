import Foundation

private final class MemoryStorage: StorageService {
    var savedProfiles: [ProxyProfile] = []

    override func loadProfiles() -> [ProxyProfile] { savedProfiles }
    override func saveProfiles(_ profiles: [ProxyProfile]) { savedProfiles = profiles }
    override func loadActiveProfileId() -> UUID? { nil }
    override func saveActiveProfileId(_ id: UUID?) {}
}

private final class SnapshotProxyService: ProxyService {
    var snapshot: SystemProxyState?
    var captureCount = 0
    var applyCount = 0

    override func readCurrentProxyState() -> SystemProxyState? {
        captureCount += 1
        return snapshot
    }

    override func readAllProxyState() -> SystemProxyState { .empty() }
    override func applyProfile(_ profile: ProxyProfile) { applyCount += 1 }
    override func disableAllProxies() { applyCount += 1 }
}

private final class InactiveMonitor: ProxyMonitor {
    override func start(onChange: @escaping () -> Void) {}
}

@main
enum ProxySnapshotTests {
    static func main() throws {
        let snapshot = SystemProxyState.fromProxySettings([
            "ProxyAutoConfigEnable": 1,
            "ProxyAutoConfigURLString": "https://proxy.test/config.pac",
            "HTTPEnable": 1,
            "HTTPProxy": "http.proxy.test",
            "HTTPPort": 8080,
            "HTTPSEnable": 0,
            "HTTPSProxy": "https.proxy.test",
            "HTTPSPort": 8443,
            "SOCKSEnable": true,
            "SOCKSProxy": "::1",
            "SOCKSPort": 1080
        ])
        let profile = snapshot.makeProfile(name: "Captured")
        precondition(profile.items.map(\.type) == [.pac, .http, .https, .socks])
        precondition(profile.items.map(\.enabled) == [true, true, false, true])
        precondition(profile.items[0].pacURL == "https://proxy.test/config.pac")
        precondition(profile.items[1].host == "http.proxy.test" && profile.items[1].port == 8080)
        precondition(profile.items[2].host == "https.proxy.test" && profile.items[2].port == 8443,
                     "Disabled proxy addresses must be preserved when macOS supplies them")
        precondition(profile.items[3].host == "::1" && profile.items[3].port == 1080)
        precondition(profile.items.allSatisfy { $0.username == nil && $0.password == nil })
        precondition(snapshot.matchesProfile(profile))
        let encoded = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(ProxyProfile.self, from: encoded)
        precondition(decoded == profile, "A captured profile must survive storage unchanged")

        let duplicate = snapshot.makeProfile(name: "Captured")
        precondition(duplicate.id != profile.id)
        precondition(Set(duplicate.items.map(\.id)).isDisjoint(with: profile.items.map(\.id)))
        let direct = SystemProxyState.fromProxySettings([:]).makeProfile(name: "Direct")
        precondition(direct.items.count == 4 && direct.items.allSatisfy { !$0.enabled })

        let storage = MemoryStorage()
        storage.savedProfiles = [
            .createDefault(name: "Current Proxy"),
            .createDefault(name: "Current Proxy 2")
        ]
        let existingProfiles = storage.savedProfiles
        let service = SnapshotProxyService()
        service.snapshot = snapshot
        let viewModel = ProxyViewModel(
            storageService: storage,
            proxyService: service,
            proxyMonitor: InactiveMonitor()
        )
        viewModel.selectedProfileId = existingProfiles[0].id
        viewModel.saveCurrentProfile()
        precondition(viewModel.isSavingCurrentProfile)
        viewModel.saveCurrentProfile()
        waitUntil { !viewModel.isSavingCurrentProfile }
        precondition(service.captureCount == 1, "Repeated clicks during capture must not add duplicates")
        precondition(viewModel.profiles.count == 3)
        precondition(Array(viewModel.profiles.prefix(2)) == existingProfiles)
        let captured = viewModel.profiles[2]
        precondition(captured.name == "Current Proxy 3")
        precondition(viewModel.selectedProfileId == captured.id,
                     "The new profile must replace any previous editor selection")
        precondition(snapshot.matchesProfile(captured))
        precondition(storage.savedProfiles == viewModel.profiles)
        precondition(viewModel.activeProfileId == nil && service.applyCount == 0,
                     "Saving a snapshot must not apply it to the system")

        var renamed = captured
        renamed.name = "Office"
        viewModel.updateProfile(renamed)
        precondition(storage.savedProfiles[2].name == "Office")
        precondition(service.applyCount == 0)

        service.snapshot = nil
        viewModel.saveCurrentProfile()
        waitUntil { !viewModel.isSavingCurrentProfile }
        precondition(viewModel.saveCurrentError != nil)
        precondition(viewModel.profiles.count == 3 && storage.savedProfiles.count == 3,
                     "A failed read must not create an empty profile")
        precondition(viewModel.selectedProfileId == captured.id)

        service.snapshot = .empty()
        viewModel.saveCurrentProfile()
        precondition(viewModel.saveCurrentError == nil)
        waitUntil { !viewModel.isSavingCurrentProfile }
        precondition(viewModel.profiles.count == 4)
        precondition(viewModel.profiles[3].items.allSatisfy { !$0.enabled })
        precondition(viewModel.selectedProfileId == viewModel.profiles[3].id)
        precondition(storage.savedProfiles == viewModel.profiles)
        precondition(service.applyCount == 0)
        print("Proxy snapshot tests passed: capture, persistence, selection, renaming, direct mode, and retry.")
    }

    private static func waitUntil(_ condition: () -> Bool) {
        let deadline = Date().addingTimeInterval(5)
        while !condition() && Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.01))
        }
        precondition(condition(), "Timed out waiting for the background snapshot")
    }
}
