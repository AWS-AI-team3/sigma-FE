import Flutter
import WebKit

class WebViewConfigurator: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        // Configure WKWebView for inline playback
        configureWebView()
    }
    
    static func configureWebView() {
        // Swizzle WKWebViewConfiguration to force inline playback
        let originalMethod = class_getInstanceMethod(
            WKWebViewConfiguration.self,
            #selector(getter: WKWebViewConfiguration.allowsInlineMediaPlayback)
        )
        let swizzledMethod = class_getInstanceMethod(
            WKWebViewConfiguration.self,
            #selector(WKWebViewConfiguration.swizzled_allowsInlineMediaPlayback)
        )
        
        if let original = originalMethod, let swizzled = swizzledMethod {
            method_exchangeImplementations(original, swizzled)
        }
    }
}

extension WKWebViewConfiguration {
    @objc dynamic var swizzled_allowsInlineMediaPlayback: Bool {
        get { return true }
        set { }
    }
}
