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
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        // Don't load URL here - let updateUIView handle it
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Load initial URL if webView hasn't loaded anything yet
        if uiView.url == nil {
            if let url = url {
                let request = URLRequest(url: url)
                uiView.load(request)
            } else {
                // 기본 홈페이지 로드
                if let defaultURL = URL(string: "https://www.apple.com") {
                    let request = URLRequest(url: defaultURL)
                    uiView.load(request)
                }
            }
        } else if let url = url, uiView.url != url {
            // Update URL if it has changed
            let request = URLRequest(url: url)
            uiView.load(request)
        }
        
        // 고성능 제스처 기반 클릭 처리
        if gestureManager.shouldClick {
            // 화면 좌표를 웹뷰 좌표로 변환
            let webViewFrame = uiView.bounds
            let clickPoint = CGPoint(
                x: gestureManager.screenThumbPosition.x - webViewFrame.origin.x,
                y: gestureManager.screenThumbPosition.y - webViewFrame.origin.y
            )
            
            // 경계 확인
            guard clickPoint.x >= 0 && clickPoint.x <= webViewFrame.width &&
                  clickPoint.y >= 0 && clickPoint.y <= webViewFrame.height else {
                return
            }
            
            // 고성능 JavaScript 클릭 이벤트 - 더 정확하고 빠른 처리
            let jsCode = """
                (function() {
                    var x = \(clickPoint.x);
                    var y = \(clickPoint.y);
                    
                    // 정확한 엘리먼트 찾기
                    var element = document.elementFromPoint(x, y);
                    if (!element) return false;
                    
                    // 클릭 가능한 엘리먼트인지 확인
                    var clickableElement = element;
                    while (clickableElement && 
                           clickableElement.tagName !== 'A' && 
                           clickableElement.tagName !== 'BUTTON' && 
                           clickableElement.tagName !== 'INPUT' &&
                           !clickableElement.onclick &&
                           !clickableElement.hasAttribute('onclick')) {
                        clickableElement = clickableElement.parentElement;
                    }
                    
                    var targetElement = clickableElement || element;
                    
                    // 터치 이벤트 시뮬레이션 (모바일 최적화)
                    var events = ['touchstart', 'touchend', 'mousedown', 'mouseup', 'click'];
                    events.forEach(function(eventType) {
                        var event = new Event(eventType, {bubbles: true, cancelable: true});
                        if (eventType.startsWith('touch')) {
                            event.touches = [{clientX: x, clientY: y}];
                        } else if (eventType.startsWith('mouse') || eventType === 'click') {
                            event.clientX = x;
                            event.clientY = y;
                        }
                        targetElement.dispatchEvent(event);
                    });
                    
                    return true;
                })();
            """
            
            uiView.evaluateJavaScript(jsCode) { result, error in
                if let error = error {
                    print("JavaScript 클릭 실행 오류: \(error)")
                }
            }
            
            // 클릭 상태 즉시 리셋 (중복 클릭 방지)
            DispatchQueue.main.async {
                gestureManager.shouldClick = false
            }
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