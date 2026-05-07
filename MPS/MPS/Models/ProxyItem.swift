import Foundation

struct ProxyItem: Codable, Identifiable, Equatable {
    let id: UUID
    let type: ProxyType
    var enabled: Bool

    var pacURL: String?
    var host: String?
    var port: Int?
    var username: String?
    var password: String?

    static func create(type: ProxyType) -> ProxyItem {
        ProxyItem(
            id: UUID(),
            type: type,
            enabled: false,
            pacURL: nil,
            host: nil,
            port: nil,
            username: nil,
            password: nil
        )
    }
}