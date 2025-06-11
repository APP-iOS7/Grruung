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
    @StateObject private var writingCountVM = WritingCountViewModel()
    @EnvironmentObject private var authService: AuthService
    
    @Environment(\.dismiss) var dismiss
    
    var currentMode: ViewMode
    var characterUUID: String
    var postID: String?
    
    @State private var currentPost: GRPost? = nil
    @State private var postBody: String = ""
    @State private var postTitle: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil // 새로 선택/변경한 이미지 데이터
    @State private var displayedImage: UIImage? = nil // 화면에 표시될 최종 이미지
    @State private var showCooldownAlert = false // 쿨타임 알림 표시 여부

    private var isPlaceholderVisible: Bool {
        postBody.isEmpty
    }
    
    private var isTitlePlaceholderVisible: Bool {
        postTitle.isEmpty
    }
    
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일"
        if currentMode == .edit || currentMode == .read {
            return formatter.string(from: currentPost?.createdAt ?? Date())
        }
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
    
    init(currentMode: ViewMode, characterUUID: String, postID: String? = nil) {
        self.currentMode = currentMode
        self.characterUUID = characterUUID
        self.postID = postID
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
                                // 사용자가 새로 선택한 이미지가 있으면 표시
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .padding(.leading)
                                
                            } else if let existingImage = displayedImage {
                                // 새로 선택한 이미지는 없지만, 기존에 로드된 이미지가 있으면 표시
                                Image(uiImage: existingImage)
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .padding(.leading)
                            }
                            
                            else {
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
                // 읽기 모드에서는 제목과 내용을 표시만 함
                Text(currentPost?.postTitle ?? "")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                Text(currentPost?.postBody ?? "")
                    .padding(.horizontal)
                    .padding(.bottom, 10)
            }
            else {
                // 제목 입력 필드
                ZStack(alignment: .topLeading) {
                    TextField("", text: $postTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(8)
                    
                    if isTitlePlaceholderVisible {
                        Text("제목을 입력해주세요")
                            .foregroundColor(Color(UIColor.placeholderText))
                            .font(.title2)
                            .padding()
                            .allowsHitTesting(false)
                    }
                }
                .padding(.horizontal)
                
                // 내용 입력 필드
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $postBody)
                        .frame(minHeight: 150)
                        .border(Color.clear)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(8)
                    
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
                                // 글쓰기 및 보상 체크
                                let (success, expReward) = writingCountVM.tryToWrite()
                                
                                // 글 저장 (항상 성공)
                                let newPostId = try await viewModel.createPost(
                                    characterUUID: characterUUID,
                                    postTitle: postTitle,
                                    postBody: postBody,
                                    imageData: selectedImageData
                                )
                                
                                // 보상 획득 가능하면 보상 추가
                                if expReward {
                                    await addRewardForWriting(characterUUID: characterUUID)
                                }
                                
                                dismiss()
                            } else if currentMode == .edit {
                                // 기존 로직 유지
                                try await viewModel.editPost(
                                    postID: currentPost?.postID ?? "",
                                    postTitle: postTitle,
                                    postBody: postBody,
                                    newImageData: selectedImageData,
                                    existingImageUrl: currentPost?.postImage ?? ""
                                )
                                dismiss()
                            } else {
                                dismiss() // 읽기 모드면 그냥 닫기
                            }
                        } catch {
                            print("Error saving post: \(error)")
                        }
                    }
                }
                .disabled(currentMode != .read && (postBody.isEmpty || postTitle.isEmpty))
                .opacity(postBody.isEmpty ? 0.5 : 1)
        )
        .background(Color(UIColor.systemGray6).ignoresSafeArea())
        .onAppear {
            setupViewforCurrentMode()
            writingCountVM.initialize(with: authService)
        }
        .alert("쿨타임 안내", isPresented: $showCooldownAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("이야기를 작성했지만 쿨타임 중이어서 경험치와 골드를 획득하지 못했습니다.\n다음 보상은 쿨타임 종료 후 이용 가능합니다.")
        }
    }
    
    // 경험치 및 골드 추가 함수
    private func addRewardForWriting(characterUUID: String) async {
        do {
            // 고정된 보상 값
            let exp = 50
            let gold = 100
            
            // 경험치와 골드 추가 함수 호출
            try await FirebaseService.shared.addExpAndGold(
                characterID: characterUUID,
                exp: exp,
                gold: gold
            )
        } catch {
            print("⚠️ 보상 추가 실패: \(error.localizedDescription)")
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
                        self.postTitle = post.postTitle
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
                        postTitle: postTitle,
                        postBody: postBody,
                        imageData: selectedImageData // 새로 선택된 이미지 데이터 전달
                    )
                    print("새 게시물 ID: \(newPostId)")
                } else if currentMode == .edit, let postToEdit = currentPost {
                    try await viewModel.editPost(
                        postID: postToEdit.postID,
                        postTitle: postTitle,
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


//#Preview {
//    NavigationStack {
//        WriteStoryView(currentMode: .create , characterUUID: "CF6NXxcH5HgGjzVE0nVE")
//    }
//}
//
//
//#Preview {
//    NavigationStack {
//        WriteStoryView(currentMode: .edit, characterUUID: "CF6NXxcH5HgGjzVE0nVE", postID: "2Ba1NrZq6GDuKmFcCs0E")
//    }
//}

#Preview {
    NavigationStack {
        WriteStoryView(currentMode: .read, characterUUID: "CF6NXxcH5HgGjzVE0nVE", postID: "2Ba1NrZq6GDuKmFcCs0E")//, userID: "uCMGt4DjgiPPpyd2p9Di")
            .environmentObject(AuthService())
    }
}
