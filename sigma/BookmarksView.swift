//
//  BookmarksView.swift
//  sigma
//
//  Created by ashcircle on 10/9/25.
//

import SwiftUI
import Combine

struct Bookmark: Identifiable, Codable {
    let id: UUID
    var title: String
    var url: String
    var createdAt: Date
    
    init(title: String, url: String) {
        self.id = UUID()
        self.title = title
        self.url = url
        self.createdAt = Date()
    }
}

class BookmarksManager: ObservableObject {
    @Published var bookmarks: [Bookmark] = []
    @Published var showingAddBookmark = false
    @Published var newBookmarkTitle = ""
    @Published var newBookmarkURL = ""
    
    private let userDefaults = UserDefaults.standard
    private let bookmarksKey = "SavedBookmarks"
    
    init() {
        loadBookmarks()
        addDefaultBookmarks()
    }
    
    private func loadBookmarks() {
        if let data = userDefaults.data(forKey: bookmarksKey),
           let savedBookmarks = try? JSONDecoder().decode([Bookmark].self, from: data) {
            bookmarks = savedBookmarks
        }
    }
    
    private func saveBookmarks() {
        if let encoded = try? JSONEncoder().encode(bookmarks) {
            userDefaults.set(encoded, forKey: bookmarksKey)
        }
    }
    
    private func addDefaultBookmarks() {
        if bookmarks.isEmpty {
            let defaultBookmarks = [
                Bookmark(title: "Apple", url: "https://www.apple.com"),
                Bookmark(title: "Google", url: "https://www.google.com"),
                Bookmark(title: "GitHub", url: "https://github.com"),
                Bookmark(title: "Stack Overflow", url: "https://stackoverflow.com"),
                Bookmark(title: "Swift.org", url: "https://swift.org")
            ]
            bookmarks = defaultBookmarks
            saveBookmarks()
        }
    }
    
    func addBookmark() {
        guard !newBookmarkTitle.isEmpty && !newBookmarkURL.isEmpty else { return }
        
        var urlString = newBookmarkURL
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            urlString = "https://" + urlString
        }
        
        let bookmark = Bookmark(title: newBookmarkTitle, url: urlString)
        bookmarks.append(bookmark)
        saveBookmarks()
        
        newBookmarkTitle = ""
        newBookmarkURL = ""
        showingAddBookmark = false
    }
    
    func deleteBookmark(_ bookmark: Bookmark) {
        bookmarks.removeAll { $0.id == bookmark.id }
        saveBookmarks()
    }
    
    func moveBookmark(from source: IndexSet, to destination: Int) {
        bookmarks.move(fromOffsets: source, toOffset: destination)
        saveBookmarks()
    }
}

struct BookmarksView: View {
    @StateObject private var bookmarksManager = BookmarksManager()
    @Binding var selectedURL: URL?
    @ObservedObject var gestureManager: GestureRecognitionManager
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Image(systemName: "star.circle.fill")
                    .foregroundColor(.yellow)
                Text("즐겨찾기")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: {
                    bookmarksManager.showingAddBookmark = true
                }) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            
            Divider()
            
            // 즐겨찾기 목록
            List {
                ForEach(bookmarksManager.bookmarks) { bookmark in
                    BookmarkRow(bookmark: bookmark) {
                        if let url = URL(string: bookmark.url) {
                            selectedURL = url
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        bookmarksManager.deleteBookmark(bookmarksManager.bookmarks[index])
                    }
                }
                .onMove(perform: bookmarksManager.moveBookmark)
            }
            .listStyle(PlainListStyle())
            
            Spacer()
        }
        .sheet(isPresented: $bookmarksManager.showingAddBookmark) {
            AddBookmarkSheet(bookmarksManager: bookmarksManager)
        }
    }
}

struct BookmarkRow: View {
    let bookmark: Bookmark
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                AsyncImage(url: URL(string: "https://www.google.com/s2/favicons?domain=\(bookmark.url)&sz=32")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Image(systemName: "globe")
                        .foregroundColor(.gray)
                }
                .frame(width: 24, height: 24)
                
                VStack(alignment: .leading) {
                    Text(bookmark.title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(bookmark.url)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AddBookmarkSheet: View {
    @ObservedObject var bookmarksManager: BookmarksManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("제목")
                        .font(.headline)
                    TextField("웹사이트 제목", text: $bookmarksManager.newBookmarkTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading) {
                    Text("URL")
                        .font(.headline)
                    TextField("https://example.com", text: $bookmarksManager.newBookmarkURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("새 즐겨찾기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        bookmarksManager.addBookmark()
                        dismiss()
                    }
                    .disabled(bookmarksManager.newBookmarkTitle.isEmpty || bookmarksManager.newBookmarkURL.isEmpty)
                }
            }
        }
    }
}