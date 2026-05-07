import Foundation

enum ProxyType: String, CaseIterable, Codable {
    case pac = "PAC"
    case http = "HTTP"
    case https = "HTTPS"
    case socks = "SOCKS"
}