import SwiftUI

struct SidebarView: View {
    @Binding var selectedTab: SidebarTab

    var body: some View {
        VStack(spacing: 0) {
            // Tab Selection
            HStack(spacing: 0) {
                ForEach(SidebarTab.allCases, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20))
                            Text(tab.rawValue)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedTab == tab ? Color.blue.opacity(0.2) : Color.clear)
                    }
                    .foregroundColor(selectedTab == tab ? .blue : .gray)
                }
            }
            .background(Color(.systemGray6))

            Divider()

            // Tab Content
            TabContent(selectedTab: selectedTab)
        }
    }
}

struct TabContent: View {
    let selectedTab: SidebarTab

    var body: some View {
        switch selectedTab {
        case .chat:
            ChatView()
        case .favorites:
            FavoritesView()
        case .settings:
            SettingsView()
        }
    }
}

struct ChatView: View {
    @State private var messages: [String] = ["안녕하세요!", "무엇을 도와드릴까요?"]
    @State private var inputText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(messages, id: \.self) { message in
                        Text(message)
                            .padding(10)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding()
            }

            Divider()

            HStack {
                TextField("메시지 입력...", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
    }

    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        messages.append(inputText)
        inputText = ""
    }
}

struct FavoritesView: View {
    @State private var favorites: [String] = [
        "https://www.apple.com",
        "https://www.google.com",
        "https://www.github.com"
    ]

    var body: some View {
        List {
            ForEach(favorites, id: \.self) { url in
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(url)
                        .font(.system(size: 14))
                }
            }
        }
    }
}

struct SettingsView: View {
    @State private var enableHandTracking = true
    @State private var cursorSensitivity: Double = 1.0

    var body: some View {
        Form {
            Section(header: Text("손 추적 설정")) {
                Toggle("손 추적 활성화", isOn: $enableHandTracking)

                VStack(alignment: .leading) {
                    Text("커서 민감도")
                    Slider(value: $cursorSensitivity, in: 0.5...2.0)
                    Text(String(format: "%.1f", cursorSensitivity))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Section(header: Text("제스처 설정")) {
                HStack {
                    Text("클릭 제스처")
                    Spacer()
                    Text("검지-엄지 핀치")
                        .foregroundColor(.gray)
                }
            }
        }
    }
}
