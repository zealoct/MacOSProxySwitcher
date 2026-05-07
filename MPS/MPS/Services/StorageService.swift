import Foundation

class StorageService {
    private let profilesKey = "mps_profiles"
    private let activeProfileIdKey = "mps_active_profile_id"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func saveProfiles(_ profiles: [ProxyProfile]) {
        guard let data = try? encoder.encode(profiles) else { return }
        UserDefaults.standard.set(data, forKey: profilesKey)
    }

    func loadProfiles() -> [ProxyProfile] {
        guard let data = UserDefaults.standard.data(forKey: profilesKey),
              let profiles = try? decoder.decode([ProxyProfile].self, from: data) else {
            return []
        }
        return profiles
    }

    func saveActiveProfileId(_ id: UUID?) {
        if let id = id {
            UserDefaults.standard.set(id.uuidString, forKey: activeProfileIdKey)
        } else {
            UserDefaults.standard.removeObject(forKey: activeProfileIdKey)
        }
    }

    func loadActiveProfileId() -> UUID? {
        guard let string = UserDefaults.standard.string(forKey: activeProfileIdKey),
              let id = UUID(uuidString: string) else {
            return nil
        }
        return id
    }
}