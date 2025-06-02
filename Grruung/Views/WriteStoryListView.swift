//
//  WriteStoryListView.swift
//  Grruung
//
//  Created by SG on 6/2/25.
//

import SwiftUI

struct WriteStoryListView: View {
    @StateObject private var viewModel: CharacterDetailViewModel
    @Environment(\.dismiss) var dismiss
    @State private var searchDate: Date = Date()
    @State private var selectedPostForEdit: PostIdentifier?
    
    let characterUUID: String
    private let estimatedRowHeight: CGFloat = 88.0
    
    init(characterUUID: String) {
        self.characterUUID = characterUUID
        self._viewModel = StateObject(wrappedValue: CharacterDetailViewModel(characterUUID: characterUUID))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // 날짜 탐색 섹션
                dateNavigationSection
                
                // 이야기 리스트 섹션
                storyListSection
                
                Spacer()
            }
            .navigationTitle("들려준 이야기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadPost(characterUUID: characterUUID, searchDate: searchDate)
        }
        .navigationDestination(item: $selectedPostForEdit) { post in
            WriteStoryView(
                currentMode: .edit,
                characterUUID: post.characterUUID,
                postID: post.postID
            )
        }
    }
    
    // MARK: - 날짜 탐색 버튼
    private var dateNavigationSection: some View {
        HStack {
            Button("<") {
                searchDate = searchDate.addingTimeInterval(-30 * 24 * 60 * 60)
                viewModel.loadPost(characterUUID: characterUUID, searchDate: searchDate)
            }
            Text("\(searchDateString(date: searchDate))")
            Button(">") {
                searchDate = searchDate.addingTimeInterval(30 * 24 * 60 * 60)
                viewModel.loadPost(characterUUID: characterUUID, searchDate: searchDate)
            }
        }
        .padding(.bottom, 10)
    }
    
    // MARK: - 들려준 이야기 영역
    private var storyListSection: some View {
        VStack {
            if viewModel.posts.isEmpty {
                Text("이번 달에 기록된 이야기가 없습니다.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List {
                    ForEach(viewModel.posts.indices, id: \.self) { index in
                        NavigationLink(destination: WriteStoryView(currentMode: .read, characterUUID: characterUUID, postID: viewModel.posts[index].postID)) {
                            HStack {
                                if !viewModel.posts[index].postImage.isEmpty {
                                    AsyncImage(url: URL(string: viewModel.posts[index].postImage)) { image in
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 60, height: 60)
                                            .padding(10)
                                    } placeholder: {
                                        Image(systemName: "photo")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 60, height: 60)
                                            .padding(10)
                                    }
                                } else {
                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 60)
                                        .padding(10)
                                }
                                VStack(alignment: .leading) {
                                    Text(viewModel.posts[index].postTitle)
                                        .font(.headline)
                                        .lineLimit(1)
                                    Text(formatDate(viewModel.posts[index].createdAt))
                                        .font(.subheadline)
                                }
                                Spacer()
                            }
                        }
                        .listRowInsets(EdgeInsets())
                        .padding(.vertical, 4)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                viewModel.deletePost(postID: viewModel.posts[index].postID)
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                selectedPostForEdit = PostIdentifier(
                                    characterUUID: characterUUID,
                                    postID: viewModel.posts[index].postID
                                )
                            } label: {
                                Image(systemName: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                    .listRowBackground(Color.white)
                }
                .listStyle(PlainListStyle())
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 30)
    }
    
    func searchDateString(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월"
        return formatter.string(from: date)
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
}


#Preview {
    WriteStoryListView(characterUUID: "CF6NXxcH5HgGjzVE0nVE")
}
