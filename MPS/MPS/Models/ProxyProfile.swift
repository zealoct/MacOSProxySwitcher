import Foundation

struct ProxyProfile: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var items: [ProxyItem]

    static func createDefault(name: String) -> ProxyProfile {
        ProxyProfile(
            id: UUID(),
            name: name,
            items: ProxyType.allCases.map { ProxyItem.create(type: $0) }
        )
    }
}