//
//  CursorOverlay.swift
//  sigma
//
//  Created by ashcircle on 10/9/25.
//

import SwiftUI

struct CursorOverlay: View {
    @ObservedObject var gestureManager: GestureRecognitionManager
    @State private var cursorScale: CGFloat = 1.0
    @State private var cursorOpacity: Double = 0.8
    @State private var rippleScale: CGFloat = 1.0
    @State private var showRipple: Bool = false
    
    var body: some View {
        ZStack {
            // 메인 커서
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            gestureManager.isPinching ? .red : .blue,
                            gestureManager.isPinching ? .orange : .cyan
                        ]),
                        center: .center,
                        startRadius: 2,
                        endRadius: 15
                    )
                )
                .frame(width: 30, height: 30)
                .scaleEffect(cursorScale)
                .opacity(cursorOpacity)
                .overlay {
                    // 커서 테두리
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 30, height: 30)
                        .scaleEffect(cursorScale)
                }
                .position(gestureManager.screenThumbPosition)
                .animation(.easeInOut(duration: 0.1), value: gestureManager.screenThumbPosition)
                .animation(.spring(response: 0.2, dampingFraction: 0.8), value: gestureManager.isPinching)
            
            // 클릭 리플 효과
            if showRipple {
                Circle()
                    .stroke(Color.red.opacity(0.6), lineWidth: 3)
                    .frame(width: 60, height: 60)
                    .scaleEffect(rippleScale)
                    .opacity(2.0 - rippleScale)
                    .position(gestureManager.screenThumbPosition)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.5)) {
                            rippleScale = 2.0
                        }
                    }
            }
            
            // 신뢰도 기반 시각적 피드백
            if gestureManager.isRunning && gestureManager.handConfidence > 0.3 {
                // 신뢰도 링
                Circle()
                    .trim(from: 0, to: CGFloat(gestureManager.handConfidence))
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.green, .yellow, .red]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                    .position(
                        x: gestureManager.screenThumbPosition.x,
                        y: gestureManager.screenThumbPosition.y - 40
                    )
                    .opacity(0.7)
                
                // 안정성 표시기
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.green.opacity(Double(gestureManager.gestureStability)))
                    .frame(width: 60 * CGFloat(gestureManager.gestureStability), height: 4)
                    .position(
                        x: gestureManager.screenThumbPosition.x,
                        y: gestureManager.screenThumbPosition.y + 40
                    )
            }
        }
        .onChange(of: gestureManager.isPinching) { newValue in
            if newValue {
                // 핀치 시작
                cursorScale = 1.5
                cursorOpacity = 1.0
                triggerRipple()
                
                // 햅틱 피드백
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
            } else {
                // 핀치 종료
                cursorScale = 1.0
                cursorOpacity = 0.8
            }
        }
        .onChange(of: gestureManager.isIndexFingerNearThumb) { newValue in
            if newValue && !gestureManager.isPinching {
                cursorScale = 1.2
                cursorOpacity = 0.9
            } else if !gestureManager.isPinching {
                cursorScale = 1.0
                cursorOpacity = 0.8
            }
        }
        .onChange(of: gestureManager.isRunning) { newValue in
            if !newValue {
                cursorScale = 0
                cursorOpacity = 0
            } else {
                cursorScale = 1.0
                cursorOpacity = 0.8
            }
        }
    }
    
    private func triggerRipple() {
        showRipple = true
        rippleScale = 1.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showRipple = false
            rippleScale = 1.0
        }
    }
}

#Preview {
    CursorOverlay(gestureManager: GestureRecognitionManager())
}