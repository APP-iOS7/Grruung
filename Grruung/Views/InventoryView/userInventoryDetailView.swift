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
    
    @State private var showingItemCountAlert: Bool = false
    
    @State private var showingUseAlert: Bool = false
    
    @State private var showingDeleteAlert: Bool = false
    
    @State private var showingReDeleteAlert: Bool = false
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
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
                Text("보유: \(item.userIteamQuantity)")
            }
        }
        .padding(16)
        .onAppear {
            remainItemCount = Double(item.userIteamQuantity)
        }
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
                showingReDeleteAlert = true
            }
        }
        .alert("버리면 되돌릴 수 없습니다. 계속하시겠습니까?", isPresented: $showingReDeleteAlert) {
            Button("취소", role: .cancel) {}
            Button("확인", role: .destructive) {
                // TODO: 갯수 동기화하기
            }
        }
        
        
        if let remainItemCount {
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
                    
                    Slider(value: $useItemCount, in: 0...remainItemCount, step: 1)
                        .tint(.green)
                    
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
        
        
        // 아이템 효과 설명
        Text("\(item.userItemName) 를 먹으면 몸에 좋아집니다")
        
        HStack {
            Button(action: {
                showingDeleteAlert = true
            }, label: {
                Text("버리기")
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(item.userItemType == .permanent ? Color.gray : Color.red)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 1)
                    )
                    .cornerRadius(10)
                    .padding(16)
            })
            .disabled(item.userItemType == .permanent)
            
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
