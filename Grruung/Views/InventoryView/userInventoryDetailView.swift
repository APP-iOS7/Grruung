//
//  userInventoryDetailView.swift
//  Grruung
//
//  Created by mwpark on 5/14/25.
//

import SwiftUI

struct userInventoryDetailView: View {
    @State var item: GRUserInventory
    // 전체 아이템 갯수
    @State private var remainItemCount: Double?
    // 사용할 아이템 갯수
    @State private var useItemCount: Double = 0
    // 사용할 아이템 갯수를 입력받을 변수
    @State private var typeItemCount: String = ""
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
        // MARK: 아이템 설명 UI
        HStack {
            Image(systemName: item.userItemImage)
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
                // TODO: 사용 수량 만큼 파이어베이스에 저장하기
                
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
                // TODO: 갯수 동기화하기
                item.userItemQuantity -= Int(useItemCount)
                remainItemCount = Double(item.userItemQuantity)
                useItemCount = 0
                typeItemCount = Int(useItemCount).description
                // 이전 뷰로 돌아가기
                if item.userItemQuantity <= 0 {
                    dismiss()
                }
                
            }
        }
        .alert("영구 아이템은 버릴 수 없습니다.", isPresented: $showingNoDeleteAlert) {
            Button("확인", role: .cancel) {}
        }
        
        if let remainItemCount {
            // MARK: 아이템 수량 관련 UI
            VStack {
                HStack {
                    Text("수량: ")
                    TextField("입력", text: $typeItemCount)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 50)
                        .onSubmit {
                            if Double(typeItemCount) ?? useItemCount >= 0 && Double(typeItemCount) ?? useItemCount <= remainItemCount {
                                useItemCount = Double(typeItemCount) ?? useItemCount
                            } else {
                                showingItemCountAlert = true
                                typeItemCount = Int(useItemCount).description
                            }
                        }
                        .focused($isFocused)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("확인") {
                                    isFocused = false
                                    if Double(typeItemCount) ?? useItemCount >= 0 && Double(typeItemCount) ?? useItemCount <= remainItemCount {
                                        useItemCount = Double(typeItemCount) ?? useItemCount
                                    } else {
                                        showingItemCountAlert = true
                                        typeItemCount = Int(useItemCount).description
                                    }
                                }
                            }
                        }
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
        
        
        // MARK: 아이템 효과 설명 UI
        Text("\(item.userItemName) 를 먹으면 몸에 좋아집니다")
        
        // MARK: 아이템 버튼 UI
        HStack {
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

#Preview {
    userInventoryDetailView(item: GRUserInventory(
        userItemNumber: 1,
        userItemName: "비타민 젤리",
        userItemType: .consumable,
        userItemImage: "pill",
        userIteamQuantity: Int.random(in: 1...10),
        userItemDescription: "피로 회복에 좋은 비타민 젤리예요.",
        userItemCategory: .drug,
        purchasedAt: Date(timeIntervalSinceNow: -Double.random(in: 1...60) * 86400)
    ))
}
