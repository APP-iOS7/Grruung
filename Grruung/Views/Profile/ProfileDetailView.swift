//
//  ProfileDetailView.swift
//  Grruung
//
//  Created by subin on 5/29/25.
//

import SwiftUI
import PhotosUI

// MARK: - 모델 정의

struct SettingItem: Identifiable {
    let id = UUID()
    let title: String
    let iconName: String
}

struct SettingSection: Identifiable {
    let id = UUID()
    let items: [SettingItem]
}

// MARK: - 메인 뷰

struct ProfileDetailView: View {
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    @State private var profileImage: Image? = nil
    
    @State private var isEditingName = false
    @State private var username = "Quaqqa"
    @State private var tempName = ""

    // 설정 항목 데이터
    let settingSections: [SettingSection] = [
        SettingSection(items: [
            .init(title: "청구서", iconName: "doc.text"),
            .init(title: "기프트 카드 또는 코드", iconName: "gift")
        ]),
        SettingSection(items: [
            .init(title: "연결된 계정을 변경하기", iconName: "link"),
            .init(title: "기기 데이터 마이그레이션", iconName: "arrow.triangle.2.circlepath")
        ]),
        SettingSection(items: [
            .init(title: "로그아웃", iconName: "rectangle.portrait.and.arrow.right")
        ])
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // MARK: - 프로필 섹션
                VStack(spacing: 20) {
                    ZStack(alignment: .bottomTrailing) {
                        PhotosPicker(selection: $selectedItem,
                                     matching: .images,
                                     photoLibrary: .shared()) {
                            Group {
                                if let profileImage {
                                    profileImage
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                } else {
                                    Image("CatLion")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                }
                            }
                            .overlay(Circle().stroke(Color.white, lineWidth: 4))
                            .background(Circle().fill(Color(.systemBackground)))
                        }
                        .onChange(of: selectedItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    selectedImageData = data
                                    if let uiImage = UIImage(data: data) {
                                        profileImage = Image(uiImage: uiImage)
                                    }
                                }
                            }
                        }

                        // 카메라 아이콘
                        Image(systemName: "camera.fill")
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Circle().fill(Color.green))
                            .offset(x: 5, y: 5)
                    }
                    .padding(.top, 20)

                    HStack(spacing: 6) {
                        if isEditingName {
                            TextField("닉네임", text: $tempName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 160)
                            Button("완료") {
                                username = tempName
                                isEditingName = false
                            }
                        } else {
                            Text(username)
                                .font(.system(size: 22, weight: .semibold))

                            Button {
                                tempName = username
                                isEditingName = true
                            } label: {
                                Image(systemName: "pencil.fill")
                                    .resizable()
                                    .frame(width: 14, height: 14)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .frame(width: 260)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .padding(.horizontal)

                // MARK: - 설정 섹션
                VStack(spacing: 30) {
                    ForEach(settingSections) { section in
                        VStack(spacing: 0) {
                            ForEach(section.items.indices, id: \.self) { index in
                                let item = section.items[index]
                                SettingRow(icon: item.iconName, text: item.title)
                                if index < section.items.count - 1 {
                                    Divider()
                                }
                            }
                        }
                        .background(RoundedRectangle(cornerRadius: 15).fill(Color(.systemBackground)))
                    }

                    // 계정 삭제 버튼
                    Button {
                        print("계정 삭제")
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("계정 삭제")
                        }
                        .foregroundColor(.red)
                        .padding(.top)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 50)
        }
        .background(Color(.systemGroupedBackground)
            .ignoresSafeArea())
    }
}

// MARK: - 설정 뷰

struct SettingRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(.primary)
                .frame(maxHeight: .infinity, alignment: .center)

            Text(text)
                .foregroundColor(.primary)
                .frame(maxHeight: .infinity, alignment: .center)

            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 15)
    }
}

// MARK: - Preview
#Preview {
    ProfileDetailView()
}
