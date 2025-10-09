//
//  WebViewComponent.swift
//  sigma
//
//  Created by ashcircle on 10/9/25.
//

import SwiftUI
import WebKit

struct WebViewComponent: UIViewRepresentable {
    @Binding var url: URL?
    @ObservedObject var gestureManager: GestureRecognitionManager
    @State private var webView: WKWebView?
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptEnabled = true
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        self.webView = webView
        
        if let url = url {
            let request = URLRequest(url: url)
            webView.load(request)
        } else {
            // 기본 홈페이지 로드
            if let defaultURL = URL(string: "https://www.apple.com") {
                let request = URLRequest(url: defaultURL)
                webView.load(request)
            }
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = url, uiView.url != url {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
        
        // 제스처 기반 클릭 처리
        if gestureManager.shouldClick {
            let normalizedPoint = CGPoint(
                x: gestureManager.thumbPosition.x * uiView.bounds.width,
                y: gestureManager.thumbPosition.y * uiView.bounds.height
            )
            
            // JavaScript를 사용해서 해당 위치에 클릭 이벤트 생성
            let jsCode = """
                var element = document.elementFromPoint(\(normalizedPoint.x), \(normalizedPoint.y));
                if (element) {
                    element.click();
                }
            """
            uiView.evaluateJavaScript(jsCode, completionHandler: nil)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebViewComponent
        
        init(_ parent: WebViewComponent) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // 페이지 로딩 완료 처리
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("웹뷰 로딩 실패: \(error)")
        }
    }
}

// 커서 오버레이 뷰
struct CursorOverlay: View {
    @ObservedObject var gestureManager: GestureRecognitionManager
    
    var body: some View {
        GeometryReader { geometry in
            Circle()
                .fill(gestureManager.isPinching ? Color.red : Color.blue)
                .frame(width: 20, height: 20)
                .position(
                    x: gestureManager.thumbPosition.x * geometry.size.width,
                    y: gestureManager.thumbPosition.y * geometry.size.height
                )
                .opacity(0.8)
                .animation(.easeInOut(duration: 0.1), value: gestureManager.thumbPosition)
                .animation(.easeInOut(duration: 0.1), value: gestureManager.isPinching)
        }
        .allowsHitTesting(false)
    }
}