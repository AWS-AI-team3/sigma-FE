import SwiftUI

struct ContentView: View {
    @StateObject private var handTracker = HandTrackingManager()
    @State private var selectedTab: SidebarTab = .chat

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left Sidebar
                SidebarView(selectedTab: $selectedTab)
                    .frame(width: geometry.size.width * 0.3)
                    .background(Color(.systemBackground))

                Divider()

                // Right WebView
                WebViewContainer(handTracker: handTracker)
                    .frame(width: geometry.size.width * 0.7)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

enum SidebarTab: String, CaseIterable {
    case chat = "채팅"
    case favorites = "즐겨찾기"
    case settings = "설정"

    var icon: String {
        switch self {
        case .chat: return "message.fill"
        case .favorites: return "star.fill"
        case .settings: return "gear"
        }
    }
}
