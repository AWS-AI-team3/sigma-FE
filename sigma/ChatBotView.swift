//
//  ChatBotView.swift
//  sigma
//
//  Created by ashcircle on 10/9/25.
//

import SwiftUI
import Combine

struct Message: Identifiable, Codable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    init(content: String, isUser: Bool, timestamp: Date) {
        self.id = UUID()
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

class ChatBotManager: ObservableObject {
    @Published var messages: [Message] = [
        Message(content: "안녕하세요! 무엇을 도와드릴까요?", isUser: false, timestamp: Date())
    ]
    @Published var currentMessage: String = ""
    @Published var isTyping: Bool = false
    
    func sendMessage() {
        guard !currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = Message(content: currentMessage, isUser: true, timestamp: Date())
        messages.append(userMessage)
        
        let messageToProcess = currentMessage
        currentMessage = ""
        isTyping = true
        
        // 간단한 챗봇 응답 로직
        Task { @MainActor in
            await processMessage(messageToProcess)
        }
    }
    
    @MainActor
    private func processMessage(_ message: String) async {
        // 1-2초 딜레이로 실제 챗봇처럼 보이게 함
        try? await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...2_000_000_000))
        
        let response = generateResponse(for: message)
        let botMessage = Message(content: response, isUser: false, timestamp: Date())
        
        messages.append(botMessage)
        isTyping = false
    }
    
    private func generateResponse(for message: String) -> String {
        let lowercased = message.lowercased()
        
        if lowercased.contains("안녕") || lowercased.contains("hello") {
            return "안녕하세요! 좋은 하루 보내고 계신가요?"
        } else if lowercased.contains("날씨") {
            return "날씨 정보는 웹에서 확인해보시는 것을 추천드려요!"
        } else if lowercased.contains("도움") || lowercased.contains("help") {
            return "제가 도와드릴 수 있는 것들:\n• 간단한 대화\n• 웹사이트 추천\n• 일반적인 질문 답변"
        } else if lowercased.contains("웹사이트") || lowercased.contains("사이트") {
            return "어떤 종류의 웹사이트를 찾고 계신가요? 뉴스, 쇼핑, 교육 등 말씀해주시면 추천해드릴게요!"
        } else {
            let responses = [
                "흥미로운 질문이네요! 더 자세히 설명해주실 수 있나요?",
                "그것에 대해 더 알고 싶어요. 어떤 부분이 궁금하신가요?",
                "좋은 생각이에요! 다른 관점에서 생각해볼 수도 있을 것 같아요.",
                "그런 것에 관심이 있으시군요. 관련해서 웹에서 더 많은 정보를 찾아보시는 건 어떨까요?",
                "재미있는 주제네요! 제가 더 도움이 될 만한 것이 있다면 말씀해주세요."
            ]
            return responses.randomElement() ?? "죄송해요, 잘 이해하지 못했어요. 다시 말씀해주실 수 있나요?"
        }
    }
}

struct ChatBotView: View {
    @StateObject private var chatManager = ChatBotManager()
    @ObservedObject var gestureManager: GestureRecognitionManager
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Image(systemName: "message.circle.fill")
                    .foregroundColor(.blue)
                Text("AI 어시스턴트")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                // 제스처 상태 표시
                if gestureManager.isRunning {
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(gestureManager.handConfidence > 0.6 ? .green : 
                                     gestureManager.handConfidence > 0.4 ? .orange : .red)
                                .frame(width: 8, height: 8)
                            Text("정확도: \(Int(gestureManager.handConfidence * 100))%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "waveform")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("안정성: \(Int(gestureManager.gestureStability * 100))%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Button(action: {
                    chatManager.messages = [Message(content: "안녕하세요! 무엇을 도와드릴까요?", isUser: false, timestamp: Date())]
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            
            Divider()
            
            // 메시지 목록
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(chatManager.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if chatManager.isTyping {
                            TypingIndicator()
                        }
                    }
                    .padding()
                }
                .onChange(of: chatManager.messages.count) { _, _ in
                    if let lastMessage = chatManager.messages.last {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // 입력 영역
            HStack {
                TextField("메시지를 입력하세요...", text: $chatManager.currentMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        chatManager.sendMessage()
                    }
                
                Button(action: {
                    chatManager.sendMessage()
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                .disabled(chatManager.currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                VStack(alignment: .trailing) {
                    Text(message.content)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading) {
                    Text(message.content)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
    }
}

struct TypingIndicator: View {
    @State private var animating = false
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 6, height: 6)
                        .opacity(animating ? 0.3 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray5))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Spacer()
        }
        .onAppear {
            animating = true
        }
    }
}