//
//  ContentView.swift
//  sigma
//
//  Created by ashcircle on 10/9/25.
//

import SwiftUI
import AVFoundation
import UIKit

struct ContentView: View {
    @StateObject private var gestureManager = GestureRecognitionManager()
    @State private var selectedURL: URL?
    @State private var selectedTab: SidebarTab = .chatbot
    @State private var showingPermissionAlert = false
    @State private var showingSafari: Bool = false
    @Environment(\.openURL) private var openURL
    
    enum SidebarTab {
        case chatbot, bookmarks
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                HStack(spacing: 0) {
                    // 왼쪽 사이드바
                    VStack(spacing: 0) {
                        // 탭 선택기
                        HStack {
                            Button(action: { selectedTab = .chatbot }) {
                                Label("챗봇", systemImage: "message.circle")
                                    .foregroundColor(selectedTab == .chatbot ? .blue : .gray)
                                    .font(.headline)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                            
                            Button(action: { selectedTab = .bookmarks }) {
                                Label("즐겨찾기", systemImage: "star.circle")
                                    .foregroundColor(selectedTab == .bookmarks ? .yellow : .gray)
                                    .font(.headline)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        
                        Divider()
                        
                        // 선택된 탭의 내용
                        Group {
                            switch selectedTab {
                            case .chatbot:
                                ChatBotView(gestureManager: gestureManager)
                            case .bookmarks:
                                BookmarksView(selectedURL: $selectedURL, gestureManager: gestureManager)
                            }
                        }
                    }
                    .frame(width: geometry.size.width * 0.35)
                    .background(Color(.systemBackground))
                    
                    Divider()
                    
                    // 오른쪽 웹뷰 영역
                    WebViewComponent(url: $selectedURL, gestureManager: gestureManager)
                    .frame(maxWidth: .infinity)
                }
                
                // 전체 화면에 걸친 제스처 커서 오버레이
                CursorOverlay(gestureManager: gestureManager)
                    .allowsHitTesting(false) // 터치 이벤트가 하위 뷰로 전달되도록
                
                // 제스처 인식 상태 표시 (전체 화면 기준)
                VStack {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            // 성능 정보 표시
                            if gestureManager.isRunning {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("FPS: \(String(format: "%.0f", gestureManager.frameRate))")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                    Text("신뢰도: \(String(format: "%.1f%%", gestureManager.handConfidence * 100))")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                    Text("안정성: \(String(format: "%.1f%%", gestureManager.gestureStability * 100))")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                    // 디버그 좌표 정보 표시
                                    if !gestureManager.debugInfo.isEmpty {
                                        Divider().background(Color.gray)
                                        Text(gestureManager.debugInfo)
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.trailing)
                                    }
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(6)
                            }
                            if gestureManager.isIndexFingerNearThumb {
                                Text("클릭 준비")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.8))
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            if gestureManager.isPinching {
                                Text("클릭!")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.8))
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .padding()
                }
                
                // 제스처 인식 제어 버튼
                VStack {
                    Spacer()
                    HStack {
                        Button(action: {
                            if gestureManager.isRunning {
                                gestureManager.stopGestureRecognition()
                            } else {
                                requestCameraPermission()
                            }
                        }) {
                            HStack {
                                Image(systemName: gestureManager.isRunning ? "video.slash" : "video")
                                Text(gestureManager.isRunning ? "제스처 중지" : "제스처 시작")
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(gestureManager.isRunning ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                    }
                    .padding()
                }
            }
        } // GeometryReader 종료
        .alert("카메라 권한 필요", isPresented: $showingPermissionAlert) {
            Button("설정으로 이동") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("제스처 인식을 위해 카메라 권한이 필요합니다. 설정에서 권한을 허용해주세요.")
        }
        .onAppear {
            // 초기 화면 크기 설정 - UIScreen 사용
            let screenSize = UIScreen.main.bounds.size
            gestureManager.updateScreenSize(screenSize)
            
            // 디바이스 방향 모니터링 시작
            NotificationCenter.default.addObserver(
                forName: UIDevice.orientationDidChangeNotification,
                object: nil,
                queue: .main
            ) { _ in
                gestureManager.updateDeviceOrientation(UIDevice.current.orientation)
                // 방향 변경시 화면 크기도 업데이트
                let newScreenSize = UIScreen.main.bounds.size
                gestureManager.updateScreenSize(newScreenSize)
            }
            
            // 초기 방향 설정
            gestureManager.updateDeviceOrientation(UIDevice.current.orientation)
        }
        // URL 선택 시 내장 사파리(SFSafariViewController)로 표시
        .onChange(of: selectedURL) { url in
            if url != nil {
                showingSafari = true
            }
        }
        .sheet(isPresented: $showingSafari, onDismiss: {
            // 닫힐 때 선택 URL 초기화
            selectedURL = nil
        }) {
            if let url = selectedURL {
                SafariView(url: url)
            }
        }
    }
    
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    gestureManager.startGestureRecognition()
                } else {
                    showingPermissionAlert = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

