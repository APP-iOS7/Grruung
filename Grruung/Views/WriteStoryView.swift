//
//  WriteStoryView.swift
//  Grruung
//
//  Created by NO SEONGGYEONG on 5/2/25.
//

import SwiftUI
import PhotosUI

enum ViewMode {
    case create
    case read
    case edit
}

struct WriteStoryView: View {
    
    @StateObject private var viewModel = WriteStoryViewModel()
    @Environment(\.dismiss) var dismiss
    
    var currentMode: ViewMode
    var characterUUID: String
    var postID: String?
    
    
    @State private var currentPost: GRPost? = nil
    
    @State private var postBody: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil // 새로 선택/변경한 이미지 데이터
    @State private var displayedImage: UIImage? = nil // 화면에 표시될 최종 이미지
    
    private var isPlaceholderVisible: Bool {
        postBody.isEmpty
    }
    
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일"
        return formatter.string(from: Date())
    }
    
    private var navigationTitle: String {
        switch currentMode {
        case .create:
            return "이야기 들려주기"
        case .read:
            return "이야기 보기"
        case .edit:
            return "이야기 다시 들려주기"
        }
    }
    
    private var buttonTitle: String {
        switch currentMode {
        case .read:
            return "닫기"
        case .edit, .create:
            return "저장"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                if currentMode == .read {
                    if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(.leading)
                        
                    } else if let displayedImage = displayedImage {
                        Image(uiImage: displayedImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(.leading)
                    }
                } else {
                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ){
                        Group {
                            if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .padding(.leading)
                                
                            } else {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .rotationEffect(.degrees(-15))
                                    .foregroundColor(.gray)
                                    .padding(.leading)
                            }
                        }
                    }
                    .onChange(of: selectedPhotoItem) { _,newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                selectedImageData = data
                            } else {
                                print("이미지 로딩 중 오류 발생")
                                selectedImageData = nil
                            }
                        }
                    }
                    .padding(.leading, 20)
                    
                }
                Spacer()
                
                Text(currentDateString)
                    .font(.title2)
                    .fontWeight(.medium)
                    .padding(.trailing)
                
                Spacer()
            }
            .padding(.top)
            
            
            if currentMode == .read {
                Text(currentPost?.postBody ?? "")
                    .padding(.horizontal)
                    .padding(.bottom, 10)
            }
            else {
                
                ZStack(alignment: .topLeading) {
                    
                    TextEditor(text: $postBody)
                        .frame(minHeight: 150)
                        .border(Color.clear)
                    
                    if isPlaceholderVisible {
                        Text("오늘 하루 \"쿼카\"에게 들려주고 싶은 이야기가 있나요?")
                            .foregroundColor(Color(UIColor.placeholderText))
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            trailing:
                Button("\(buttonTitle)") {
                    Task {
                        do {
                            print("우측 상단 button tapped!")
                            
                            if currentMode == .create {
                                let _ =  try await viewModel.createPost(
                                    characterUUID: characterUUID,
                                    postBody: postBody,
                                    imageData: selectedImageData
                                )
                            } else if currentMode == .edit {
                                try await viewModel.editPost(
                                    postID: currentPost?.postID ?? "",
                                    postBody: postBody,
                                    newImageData: selectedImageData,
                                    existingImageUrl: currentPost?.postImage ?? ""
                                )
                            }
                            dismiss()
                        } catch {
                            print("Error saving post: \(error)")
                        }
                    }
                    
                    if let imageData = selectedImageData {
                        print("Image data size: \(imageData.count) bytes")
                    } else {
                        print("No image selected.")
                    }
                }
                .disabled(currentMode != .read && postBody.isEmpty)
                .opacity(postBody.isEmpty ? 0.5 : 1)
        )
        .background(Color(UIColor.systemGray6).ignoresSafeArea())
        .onAppear {
            setupViewforCurrentMode()
        }
    }
    
    
    private func setupViewforCurrentMode() {
        if currentMode == .create {
            postBody = ""
            selectedPhotoItem = nil
            selectedImageData = nil
            displayedImage = nil
            currentPost = nil
            
        } else if let postIdToLoad = postID, (currentMode == .read || currentMode == .edit) {
            Task {
                do {
                    let fetchedPost = try await viewModel.findPost(postID: postIdToLoad)
                    self.currentPost = fetchedPost
                    if let post = fetchedPost {
                        self.postBody = post.postBody
                        if !post.postImage.isEmpty {
                            loadImageFrom(urlString: post.postImage)
                        } else {
                            self.displayedImage = nil
                            self.selectedImageData = nil
                        }
                    } else {
                        print("Post not found.")
                    }
                } catch {
                    print("Error in setupViewforCurrentMode: \(error)")
                }
            }
        }
    }
    
    private func loadImageFrom(urlString: String) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL string: \(urlString)")
            self.displayedImage = nil
            return
        }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                self.displayedImage = UIImage(data: data)
            } catch {
                print("Error loading image: \(error)")
                self.displayedImage = nil
            }
        }
        
    }
    
    private func handleSaveOrUpdate() {
        let characterUUID = currentPost?.characterUUID ?? ""
        
        Task {
            do {
                if currentMode == .create {
                    let newPostId = try await viewModel.createPost(
                        characterUUID: characterUUID,
                        postBody: postBody,
                        imageData: selectedImageData // 새로 선택된 이미지 데이터 전달
                    )
                    print("새 게시물 ID: \(newPostId)")
                } else if currentMode == .edit, let postToEdit = currentPost {
                    try await viewModel.editPost(
                        postID: postToEdit.postID,
                        postBody: postBody,
                        newImageData: selectedImageData, // 새로 선택된 이미지 데이터 전달
                        existingImageUrl: postToEdit.postImage // 기존 이미지 URL 전달
                    )
                    
                    
                    print("게시물 수정 완료, ID: \(postToEdit.postID)")
                }
                dismiss()
            } catch {
                print("저장/수정 중 오류 발생: \(error)")
            }
        }
    }
    
    
    
} // end of WriteStoryView



//
#Preview {
    NavigationStack {
        WriteStoryView(currentMode: .create , characterUUID: "CF6NXxcH5HgGjzVE0nVE")
    }
}


#Preview {
    NavigationStack {
        WriteStoryView(currentMode: .edit, characterUUID: "CF6NXxcH5HgGjzVE0nVE", postID: "Qs8eRdfB8DkPkMRALlds")
    }
}

#Preview {
    NavigationStack {
        WriteStoryView(currentMode: .read, characterUUID: "CF6NXxcH5HgGjzVE0nVE", postID: "Qs8eRdfB8DkPkMRALlds")
    }
}
