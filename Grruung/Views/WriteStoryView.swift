//
//  WriteStoryView.swift
//  Grruung
//
//  Created by NO SEONGGYEONG on 5/2/25.
//

import SwiftUI
import PhotosUI

struct WriteStoryView: View {
    
    @State private var diaryText: String = ""
    // PhotosPicker에서 선택된 항목을 저장할 상태 변수 (단일 이미지 선택)
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    // 선택된 이미지 데이터를 저장할 상태 변수
    @State private var selectedImageData: Data? = nil
    
    private var isPlaceholderVisible: Bool {
        diaryText.isEmpty
    }
    
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일"
        return formatter.string(from: Date())
    }
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 20) {
            HStack {
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
//                                .rotationEffect(.degrees(-15))
                                .padding(.leading)
                            
                        } else {
                            // 선택된 이미지가 없을 때 플레이스 홀더 이미지 표시
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
                Spacer()
                
                Text(currentDateString)
                    .font(.title2)
                    .fontWeight(.medium)
                    .padding(.trailing)
                
                Spacer() // Push date towards the center/right
            }
            .padding(.top) // Add padding above the HStack
            
            // TextEditor for multi-line input
            ZStack(alignment: .topLeading) {
                // TextEditor itself
                TextEditor(text: $diaryText)
                    .frame(minHeight: 150) // Give it some minimum height
                    .border(Color.clear) // Hide default border if any
                
                // Placeholder Text - shown only if diaryText is empty
                if isPlaceholderVisible {
                    Text("오늘 하루 \"쿼카\"에게 들려주고 싶은 이야기가 있나요?")
                        .foregroundColor(Color(UIColor.placeholderText))
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false) // Make placeholder non-interactive
                }
            }
            .padding(.horizontal) // Add horizontal padding to the text editor area
            
            Spacer() // Pushes content to the top
        }
        .navigationTitle("이야기 들려주기") // Hide the default large navigation title area
        .navigationBarTitleDisplayMode(.inline) // Use inline style for title if needed
        .navigationBarItems(trailing:
                                Button("저장") {
            // Action for the save button
            print("Save button tapped!")
            print("Diary Text: \(diaryText)")
            
            if let imageData = selectedImageData {
                print("Image data size: \(imageData.count) bytes")
            } else {
                print("No image selected.")
            }
            
        }
        )
        .background(Color(UIColor.systemGray6).ignoresSafeArea())
    }
    
}



#Preview {
    NavigationStack {
        WriteStoryView()
    }
}
