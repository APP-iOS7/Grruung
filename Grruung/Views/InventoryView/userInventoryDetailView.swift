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
                                typeItemCount = ""
                            }
                        }
                }

                HStack {
                    Button(action: {
                        if useItemCount > 0 {
                            useItemCount -= 1
                        }
                        
                    }, label: {
                        Image(systemName: "minus.circle.fill")
                            .resizable()
                            .frame(width: 25, height: 25)
                            .foregroundStyle(.black)
                    })
                    
                    Slider(value: $useItemCount, in: 0...remainItemCount, step: 1)
                        .tint(.green)
                    
                    Button(action: {
                        if useItemCount < remainItemCount {
                            useItemCount += 1
                        }
                    }, label: {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 25, height: 25)
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
        
        Button(action: {
            
        }, label: {
            Text("사용")
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
