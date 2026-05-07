import Foundation

struct ProxyStateItem: Equatable {
    var enabled: Bool
    var host: String?
    var port: Int?
    var url: String?
}

struct SystemProxyState: Equatable {
    var pac: ProxyStateItem
    var http: ProxyStateItem
    var https: ProxyStateItem
    var socks: ProxyStateItem

    static func empty() -> SystemProxyState {
        SystemProxyState(
            pac: ProxyStateItem(enabled: false, host: nil, port: nil, url: nil),
            http: ProxyStateItem(enabled: false, host: nil, port: nil, url: nil),
            https: ProxyStateItem(enabled: false, host: nil, port: nil, url: nil),
            socks: ProxyStateItem(enabled: false, host: nil, port: nil, url: nil)
        )
    }

    func matchesProfile(_ profile: ProxyProfile) -> Bool {
        for item in profile.items {
            let state: ProxyStateItem
            switch item.type {
            case .pac: state = pac
            case .http: state = http
            case .https: state = https
            case .socks: state = socks
            }

            if item.enabled != state.enabled { return false }
            if item.enabled {
                if item.type == .pac {
                    if item.pacURL != state.url { return false }
                } else {
                    if item.host != state.host { return false }
                    if item.port != state.port { return false }
                }
            }
        }
        return true
    }
}

class ProxyService {
    private let networksetupPath = "/usr/sbin/networksetup"

    func listNetworkServices() -> [String] {
        let output = runCommand(arguments: ["-listallnetworkservices"])
        let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }
        // First line is a header description, skip it
        // Lines starting with * are disabled services, skip those too
        var services: [String] = []
        for line in lines.dropFirst() {
            let trimmed = line.trimmingCharacters(in: CharacterSet.whitespaces)
            if !trimmed.hasPrefix("*") && !trimmed.isEmpty {
                services.append(trimmed)
            }
        }
        return services
    }

    func readProxyState(for service: String) -> SystemProxyState {
        SystemProxyState(
            pac: readPACState(for: service),
            http: readHTTPState(for: service),
            https: readHTTPSState(for: service),
            socks: readSOCKSState(for: service)
        )
    }

    func readAllProxyState() -> SystemProxyState {
        let services = listNetworkServices()
        if services.isEmpty { return .empty() }
        // Use the first active service (typically Wi-Fi) as representative
        let state = readProxyState(for: services[0])
        return state
    }

    func applyProfile(_ profile: ProxyProfile) {
        let services = listNetworkServices()
        for service in services {
            // First, disable all proxy types
            disableAllProxiesForService(service)

            // Then, enable and configure each enabled item
            for item in profile.items where item.enabled {
                switch item.type {
                case .pac:
                    if let url = item.pacURL {
                        setAutoProxyURL(for: service, url: url)
                        setProxyState(for: service, proxyType: "autoproxy", enabled: true)
                    }
                case .http:
                    if let host = item.host, let port = item.port {
                        setWebProxy(for: service, host: host, port: port)
                        setProxyState(for: service, proxyType: "webproxy", enabled: true)
                        if let user = item.username, let pass = item.password {
                            setWebProxyAuth(for: service, username: user, password: pass)
                        }
                    }
                case .https:
                    if let host = item.host, let port = item.port {
                        setSecureWebProxy(for: service, host: host, port: port)
                        setProxyState(for: service, proxyType: "securewebproxy", enabled: true)
                        if let user = item.username, let pass = item.password {
                            setSecureWebProxyAuth(for: service, username: user, password: pass)
                        }
                    }
                case .socks:
                    if let host = item.host, let port = item.port {
                        setSOCKSProxy(for: service, host: host, port: port)
                        setProxyState(for: service, proxyType: "socksfirewallproxy", enabled: true)
                    }
                }
            }
        }
    }

    func disableAllProxies() {
        let services = listNetworkServices()
        for service in services {
            disableAllProxiesForService(service)
        }
    }

    // MARK: - Private methods

    private func disableAllProxiesForService(_ service: String) {
        setProxyState(for: service, proxyType: "webproxy", enabled: false)
        setProxyState(for: service, proxyType: "securewebproxy", enabled: false)
        setProxyState(for: service, proxyType: "socksfirewallproxy", enabled: false)
        setProxyState(for: service, proxyType: "autoproxy", enabled: false)
    }

    private func readPACState(for service: String) -> ProxyStateItem {
        let output = runCommand(arguments: ["-getautoproxyurl", service])
        let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }
        var enabled = false
        var url: String? = nil
        for line in lines {
            if line.hasPrefix("Enabled:") {
                enabled = line.contains("Yes")
            } else if line.hasPrefix("URL:") {
                let value = String(line.dropFirst(4)).trimmingCharacters(in: CharacterSet.whitespaces)
                if value != "(null)" && !value.isEmpty {
                    url = value
                }
            }
        }
        return ProxyStateItem(enabled: enabled, host: nil, port: nil, url: url)
    }

    private func readHTTPState(for service: String) -> ProxyStateItem {
        let output = runCommand(arguments: ["-getwebproxy", service])
        return parseHostPortOutput(output)
    }

    private func readHTTPSState(for service: String) -> ProxyStateItem {
        let output = runCommand(arguments: ["-getsecurewebproxy", service])
        return parseHostPortOutput(output)
    }

    private func readSOCKSState(for service: String) -> ProxyStateItem {
        let output = runCommand(arguments: ["-getsocksfirewallproxy", service])
        return parseHostPortOutput(output)
    }

    private func parseHostPortOutput(_ output: String) -> ProxyStateItem {
        let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }
        var enabled = false
        var host: String? = nil
        var port: Int? = nil
        for line in lines {
            if line.hasPrefix("Enabled:") {
                enabled = line.contains("Yes")
            } else if line.hasPrefix("Server:") {
                let value = String(line.dropFirst(7)).trimmingCharacters(in: CharacterSet.whitespaces)
                if value != "(null)" && !value.isEmpty {
                    host = value
                }
            } else if line.hasPrefix("Port:") {
                let value = String(line.dropFirst(5)).trimmingCharacters(in: CharacterSet.whitespaces)
                if let p = Int(value) {
                    port = p
                }
            }
        }
        return ProxyStateItem(enabled: enabled, host: host, port: port, url: nil)
    }

    private func setProxyState(for service: String, proxyType: String, enabled: Bool) {
        let state = enabled ? "on" : "off"
        _ = runCommand(arguments: ["-setproxystate", service, proxyType, state])
    }

    private func setWebProxy(for service: String, host: String, port: Int) {
        _ = runCommand(arguments: ["-setwebproxy", service, host, String(port)])
    }

    private func setWebProxyAuth(for service: String, username: String, password: String) {
        _ = runCommand(arguments: ["-setwebproxyauthenticationcredential", service, username, password])
    }

    private func setSecureWebProxy(for service: String, host: String, port: Int) {
        _ = runCommand(arguments: ["-setsecurewebproxy", service, host, String(port)])
    }

    private func setSecureWebProxyAuth(for service: String, username: String, password: String) {
        _ = runCommand(arguments: ["-setsecurewebproxyauthenticationcredential", service, username, password])
    }

    private func setSOCKSProxy(for service: String, host: String, port: Int) {
        _ = runCommand(arguments: ["-setsocksfirewallproxy", service, host, String(port)])
    }

    private func setAutoProxyURL(for service: String, url: String) {
        _ = runCommand(arguments: ["-setautoproxyurl", service, url])
    }

    private func runCommand(arguments: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: networksetupPath)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
}