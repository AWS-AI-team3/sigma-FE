import SwiftUI
import WebKit

struct WebViewContainer: View {
    @ObservedObject var handTracker: HandTrackingManager
    @State private var cursorPosition: CGPoint = .zero
    @State private var showCursor: Bool = false

    var body: some View {
        ZStack {
            WebView(cursorPosition: $cursorPosition, handTracker: handTracker)

            // 가상 커서
            if showCursor {
                Circle()
                    .fill(handTracker.isPinching ? Color.green : Color.blue)
                    .frame(width: 20, height: 20)
                    .position(cursorPosition)
                    .shadow(radius: 5)
            }
        }
        .onAppear {
            handTracker.startTracking()
        }
        .onDisappear {
            handTracker.stopTracking()
        }
        .onReceive(handTracker.$thumbPosition) { position in
            updateCursorPosition(position)
        }
        .onReceive(handTracker.$isTracking) { tracking in
            showCursor = tracking
        }
    }

    private func updateCursorPosition(_ position: CGPoint) {
        // 카메라 좌표를 화면 좌표로 변환
        cursorPosition = position
    }
}

struct WebView: UIViewRepresentable {
    @Binding var cursorPosition: CGPoint
    @ObservedObject var handTracker: HandTrackingManager

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)

        // 초기 URL 로드
        if let url = URL(string: "https://www.apple.com") {
            webView.load(URLRequest(url: url))
        }

        // 클릭 이벤트 수신
        NotificationCenter.default.addObserver(
            forName: .handGestureClick,
            object: nil,
            queue: .main
        ) { notification in
            if let clickPosition = notification.object as? CGPoint {
                context.coordinator.handleClick(at: clickPosition, in: webView)
            }
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // 필요시 업데이트
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        func handleClick(at position: CGPoint, in webView: WKWebView) {
            // 화면 좌표를 웹뷰 내 좌표로 변환
            let webViewBounds = webView.bounds
            let normalizedX = position.x / UIScreen.main.bounds.width
            let normalizedY = position.y / UIScreen.main.bounds.height

            let webX = normalizedX * webViewBounds.width
            let webY = normalizedY * webViewBounds.height

            // JavaScript를 사용하여 해당 위치의 요소를 클릭
            let script = """
            (function() {
                var element = document.elementFromPoint(\(webX), \(webY));
                if (element) {
                    element.click();
                    return true;
                }
                return false;
            })();
            """

            webView.evaluateJavaScript(script) { result, error in
                if let error = error {
                    print("클릭 실행 실패: \(error)")
                } else {
                    print("클릭 성공 at (\(webX), \(webY))")
                }
            }
        }
    }
}
