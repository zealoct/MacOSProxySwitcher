import Foundation
import SystemConfiguration

class ProxyMonitor {
    private var store: SCDynamicStore?
    private var callback: (() -> Void)?
    private var runLoopSource: CFRunLoopSource?

    func start(onChange: @escaping () -> Void) {
        self.callback = onChange

        var context = SCDynamicStoreContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        guard let store = SCDynamicStoreCreate(
            nil,
            "MPS" as CFString,
            { _, _, info in
                guard let info = info else { return }
                let monitor = Unmanaged<ProxyMonitor>.fromOpaque(info).takeUnretainedValue()
                monitor.callback?()
            },
            &context
        ) else { return }

        self.store = store

        let patterns = [
            "State:/Network/Global/Proxies" as CFString,
            "Setup:/Network/Service/.*/Proxies" as CFString
        ] as CFArray

        SCDynamicStoreSetNotificationKeys(store, nil, patterns)

        let source = SCDynamicStoreCreateRunLoopSource(nil, store, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, CFRunLoopMode.defaultMode)
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, CFRunLoopMode.defaultMode)
        }
        runLoopSource = nil
        store = nil
        callback = nil
    }
}