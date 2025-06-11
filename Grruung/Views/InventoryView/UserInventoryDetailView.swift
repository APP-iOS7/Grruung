//
//  userInventoryDetailView.swift
//  Grruung
//
//  Created by mwpark on 5/14/25.
//

import SwiftUI

struct UserInventoryDetailView: View {
    @State var item: GRUserInventory
    // 전체 아이템 갯수
    @State private var remainItemCount: Double?
    // 사용할 아이템 갯수
    @State private var useItemCount: Double = 0
    // 사용할 아이템 갯수를 입력받을 변수
    @State private var typeItemCount: String = ""
    
    @State var realUserId: String
    
    @Binding var isEdited: Bool
    
    @EnvironmentObject var authService: AuthService
    
    @StateObject private var userInventoryViewModel = UserInventoryViewModel()
    
    // 수량 입력 시 범위 밖의 수를 입력했을 때 alert 변수
    @State private var showingItemCountAlert: Bool = false
    // 사용하기 버튼 클릭 시 alert 변수
    @State private var showingUseAlert: Bool = false
    // 버리기 버튼 클릭시 alert 변수
    @State private var showingDeleteAlert: Bool = false
    // 버리기 재확인 alert 변수
    @State private var showingReDeleteAlert: Bool = false
    // 영구 아이템 버리기 클릭 시 alert 변수
    @State private var showingNoDeleteAlert: Bool = false
    
    // 키보드 내리기 변수
    @FocusState private var isFocused: Bool
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                // MARK: 아이템 설명 UI
                HStack {
                    Image(item.userItemImage)
                        .resizable()
                        .frame(width: 60, height: 60)
                        .aspectRatio(contentMode: .fit)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(lineWidth: 1)
                                .background(Color.gray.opacity(0.3))
                        }
                        .padding(.trailing, 8)
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text(item.userItemName)
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            Text(item.userItemType.rawValue)
                                .foregroundStyle(item.userItemType == .consumable ? .red : .gray)
                        }
                        Text(item.userItemDescription)
                            .lineLimit(1)
                        Text("보유: \(item.userItemQuantity)")
                    }
                }
                .padding(16)
                // MARK: onAppear
                .onAppear {
                    // 아이템 수량 가져옴
                    remainItemCount = Double(item.userItemQuantity)
                }
                // MARK: 각종 alert들
                .alert("올바른 수를 입력해주세요", isPresented: $showingItemCountAlert) {
                    Button("확인", role: .cancel) {}
                }
                .alert("아이템을 사용합니다.", isPresented: $showingUseAlert) {
                    Button("취소", role: .cancel) {}
                    Button("확인", role: .destructive) {
                        isEdited = true
                        if useItemCount > 0 {
                            // 아이템 효과 적용
                            let result = ItemEffectApplier.shared.applyItemEffect(
                                item: item,
                                quantity: Int(useItemCount)
                            )
                            
                            // 상태 메시지 업데이트 (NotificationCenter를 통해 전달)
                            if result.success {
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("ItemEffectApplied"),
                                    object: nil,
                                    userInfo: ["message": result.message]
                                )
                            }
                            
                            // 아이템 수량 감소 처리
                            item.userItemQuantity -= Int(useItemCount)
                            if item.userItemQuantity <= 0 {
                                userInventoryViewModel.deleteItem(userId: realUserId, item: item)
                                // 이전 뷰로 돌아가기
                                dismiss()
                            } else {
                                remainItemCount = Double(item.userItemQuantity)
                                useItemCount = 0
                                typeItemCount = Int(useItemCount).description
                                userInventoryViewModel.updateItemQuantity(userId: realUserId, item: item, newQuantity: item.userItemQuantity)
                            }
                        }
                    }
                }
                .alert("아이템을 버립니다.", isPresented: $showingDeleteAlert) {
                    Button("취소", role: .cancel) {}
                    Button("확인", role: .destructive) {
                        if item.userItemType == .permanent {
                            showingNoDeleteAlert = true
                        } else {
                            showingReDeleteAlert = true
                        }
                    }
                }
                .alert("버리면 되돌릴 수 없습니다. 계속하시겠습니까?", isPresented: $showingReDeleteAlert) {
                    Button("취소", role: .cancel) {}
                    Button("확인", role: .destructive) {
                        isEdited = true
                        if useItemCount > 0 {
                            item.userItemQuantity -= Int(useItemCount)
                            if item.userItemQuantity <= 0 {
                                userInventoryViewModel.deleteItem(userId: realUserId, item: item)
                                // 이전 뷰로 돌아가기
                                dismiss()
                            } else {
                                remainItemCount = Double(item.userItemQuantity)
                                useItemCount = 0
                                typeItemCount = Int(useItemCount).description
                                userInventoryViewModel.updateItemQuantity(userId: realUserId, item: item, newQuantity: item.userItemQuantity)
                            }
                        }
                    }
                }
                .alert("영구 아이템은 버릴 수 없습니다.", isPresented: $showingNoDeleteAlert) {
                    Button("확인", role: .cancel) {}
                }
                
                if item.userItemType == .consumable {
                    if let remainItemCount {
                        // MARK: 아이템 수량 관련 UI
                        VStack {
                            HStack {
                                Text("수량: ")
                                TextField("입력", text: $typeItemCount)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 50)
                                    .focused($isFocused)
                            }
                            
                            HStack {
                                Button(action: {
                                    useItemCount = 0
                                    typeItemCount = "0"
                                }, label: {
                                    Text("최소")
                                        .foregroundStyle(.black)
                                })
                                Button(action: {
                                    if useItemCount > 0 {
                                        useItemCount -= 1
                                        typeItemCount = Int(useItemCount).description
                                    }
                                    
                                }, label: {
                                    Image(systemName: "minus.circle.fill")
                                        .resizable()
                                        .frame(width: 25, height: 25)
                                        .foregroundStyle(useItemCount <= 0 ? .gray : .black)
                                })
                                .disabled(useItemCount <= 0)
                                
                                if remainItemCount > 0 {
                                    Slider(value: $useItemCount, in: 0...remainItemCount, step: 1)
                                }
                                
                                Button(action: {
                                    if useItemCount < remainItemCount {
                                        useItemCount += 1
                                        typeItemCount = Int(useItemCount).description
                                    }
                                }, label: {
                                    Image(systemName: "plus.circle.fill")
                                        .resizable()
                                        .frame(width: 25, height: 25)
                                        .foregroundStyle(useItemCount >= remainItemCount ? .gray : .black)
                                })
                                .disabled(useItemCount >= remainItemCount)
                                Button(action: {
                                    useItemCount = remainItemCount
                                    typeItemCount = Int(remainItemCount).description
                                }, label: {
                                    Text("최대")
                                        .foregroundStyle(.black)
                                })
                            }
                            .padding(.horizontal, 16)
                            
                            Text("(\(Int(useItemCount)) / \(Int(remainItemCount)))")
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.3))
                        )
                        .padding(.horizontal)
                    }
                }
                
                // MARK: 아이템 효과 설명 UI
                Text(item.userItemEffectDescription)
                
                // MARK: 아이템 버튼 UI
                HStack {
                    if item.userItemType == .permanent {
                        Button(action: {
                            dismiss()
                        }, label: {
                            Text("확인")
                                .foregroundColor(.black)
                                .padding()
                                .frame(maxWidth: UIScreen.main.bounds.width / 3)
                                .background(.green)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.black, lineWidth: 1)
                                )
                                .cornerRadius(10)
                                .padding(16)
                        })
                    } else {
                        Button(action: {
                            showingDeleteAlert = true
                        }, label: {
                            Text("버리기")
                                .foregroundColor(.black)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(.red)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.black, lineWidth: 1)
                                )
                                .cornerRadius(10)
                                .padding(16)
                        })
                        
                        Button(action: {
                            showingUseAlert = true
                        }, label: {
                            Text("사용하기")
                                .foregroundColor(.black)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(useItemCount <= 0 ? Color.gray : Color.green)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.black, lineWidth: 1)
                                )
                                .cornerRadius(10)
                                .padding(16)
                        })
                        .disabled(useItemCount <= 0)
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("완료") {
                        isFocused = false
                        if let input = Double(typeItemCount),
                           let remain = remainItemCount,
                           input >= 0, input <= remain {
                            useItemCount = input
                        } else {
                            showingItemCountAlert = true
                            typeItemCount = Int(useItemCount).description
                        }
                    }
                }
            }
        }
    }
}
