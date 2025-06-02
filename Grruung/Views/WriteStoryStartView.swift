//
//  StoryListView.swift
//  Grruung
//
//  Created by NO SEONGGYEONG on 5/27/25.
//

import SwiftUI

struct WriteStoryStartView: View {
    @StateObject private var charViewModel: CharacterDetailViewModel
    @StateObject private var viewModel = WriteStoryViewModel()
    @StateObject private var writingCountVM = WritingCountViewModel()
    @EnvironmentObject private var authService: AuthService
    @State private var currentViewMode: ViewMode = .create
    @State private var navigateToWriteView = false
    @State private var showNoCountAlert = false
    @State private var showStoryListModal = false // 모달 표시 상태 추가
    
    var characterUUID: String
    
    init(characterUUID: String) {
        self.characterUUID = characterUUID
        _charViewModel = StateObject(wrappedValue: CharacterDetailViewModel(characterUUID: characterUUID))
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGray6).ignoresSafeArea()
            
            VStack {
                VStack(spacing: 16) {
                    if !charViewModel.character.imageName.isEmpty {
                        AsyncImage(url: URL(string:charViewModel.character.imageName)) {
                            image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 300)
                                .padding(10)
                        } placeholder: {
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 300)
                                .padding(10)
                        }
                    }
                    Text("들려준 이야기 쓰기 시작하기")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.top, 8)
                    
                    Text("\(charViewModel.character.name)에게 \(charViewModel.user.userName)님의 이야기를 들려주세요.")
                        .multilineTextAlignment(.center)
                        .font(.footnote)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
                .padding()
            }
            
            // 하단 플로팅 버튼
            VStack {
                Spacer()
                
                HStack(spacing: 24) {
                    Button {
                        showStoryListModal = true // 모달 표시
                    } label: {
                        Image(systemName: "list.bullet")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                                
                    Button {
                        if let count = writingCountVM.userWritingCount?.totalAvailableCount, count > 0 {
                            navigateToWriteView = true
                        } else {
                            showNoCountAlert = true
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background((writingCountVM.userWritingCount?.totalAvailableCount ?? 0) > 0 ? Color.blue : Color.gray)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .navigationTitle("이야기 들려주기")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Text("남은 글쓰기 횟수: \(writingCountVM.userWritingCount?.totalAvailableCount ?? 0)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.top, 8)
            }
        }
        .onAppear {
            writingCountVM.initialize(with: authService)
        }
        .navigationDestination(isPresented: $navigateToWriteView) {
            WriteStoryView(currentMode: currentViewMode, characterUUID: characterUUID)
                .environmentObject(authService)
        }
        // 모달 시트 추가
        .sheet(isPresented: $showStoryListModal) {
            WriteStoryListView(characterUUID: characterUUID)
        }
        .alert("글쓰기 횟수 부족", isPresented: $showNoCountAlert) {
            Button("확인", role: .cancel) { }
            Button("충전하기") {
                // 여기에 충전 화면으로 이동하는 코드 추가
            }
        } message: {
            Text("오늘 사용 가능한 글쓰기 횟수를 모두 사용했습니다.\n추가 글쓰기를 원하시면 충전이 필요합니다.")
        }
    }
}

#Preview {
    NavigationStack {
        WriteStoryStartView(characterUUID: "CF6NXxcH5HgGjzVE0nVE")//, userId: "uCMGt4DjgiPPpyd2p9Di")
            .environmentObject(AuthService())
    }
}
