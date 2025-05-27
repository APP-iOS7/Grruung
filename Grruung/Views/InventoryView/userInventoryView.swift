//
//  userInventoryView.swift
//  Grruung
//
//  Created by mwpark on 5/14/25.
//

import SwiftUI

struct userInventoryView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var userInventoryViewModel = UserInventoryViewModel()
    @State var realUserId = ""
    @State private var items: [GRUserInventory] = []
    @State private var selectedItem: GRUserInventory? = nil
    @State private var isEdited: Bool = false
    
    private let inventoryEmptyText: [String] = [
        "텅...",
        "가방이 조용하네요.",
        "아직 담긴 게 없어요. 조금만 더 기다려줘요.",
        "이곳은 아직 비어 있어요.",
        "아이템 하나쯤은… 곧 생기겠죠?",
        "장난감 하나만 넣어줘요!",
        "비어 있음은, 곧 채워질 준비가 된 상태예요.",
        "아무것도 없을 땐, 무한한 가능성이 있어요.",
        "빈 가방, 새로운 이야기를 기다리는 중…",
        "고요한 시작, 이곳에 추억이 담길 거예요.",
        "이럴수가! 아무것도 없어요!",
        "주인님… 가방 너무 가벼워요…",
    ]
    
    private let columns = [
        GridItem(.flexible())
    ]
    
    @State private var sortItemCategory: SortItemCategory = .all
    @State private var sortItemType: SortItemType = .all
    
    enum SortItemCategory: String, CaseIterable {
        case all = "전체"
        case drug = "약품"
        case toy = "장난감"
        case etc = "기타"
    }
    
    enum SortItemType: String {
        case all = "전체"
        case consumable = "소모품"
        case permanent = "영구"
    }
    
    var sortedItems: [GRUserInventory] {
        let itemsToSort = userInventoryViewModel.inventories
        
        switch sortItemCategory {
        case .all:
            return itemsToSort
        case .drug:
            return itemsToSort.filter { $0.userItemCategory == .drug }
        case .toy:
            return itemsToSort.filter { $0.userItemCategory == .toy }
        case .etc:
            return itemsToSort.filter { $0.userItemCategory == .etc}
        }
    }
    
    fileprivate func itemCellView(_ item: GRUserInventory) -> HStack<TupleView<(some View, VStack<TupleView<(HStack<TupleView<(Text, Spacer, Text)>>, some View, Text)>>)>> {
        return HStack {
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
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Picker("Choose a category", selection: $sortItemCategory) {
                    ForEach(SortItemCategory.allCases, id: \.self) { category in
                        Text(category.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .background(.yellow)
                .cornerRadius(15)
                .padding()
                
                if userInventoryViewModel.isLoading {
                    ProgressView("불러오는 중...")
                } else if userInventoryViewModel.inventories.isEmpty {
                    Text(inventoryEmptyText.randomElement() ?? "텅...")
                        .lineLimit(1)
                        .font(.title2)
                        .foregroundStyle(.gray)
                        .padding()
                } else {
                    LazyVGrid(columns: columns) {
                                ForEach(sortedItems, id: \.userItemNumber) { item in
                                    Button {
                                        selectedItem = item
                                    } label: {
                                        itemCellView(item)
                                            .foregroundStyle(.black)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(16)
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.black, lineWidth: 2)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.bottom, 16)
                                    }
                                }
                            }
                            .sheet(item: $selectedItem, onDismiss: {
                                // 수량 변경이 있는 경우에만 인벤토리 리로드
                                if isEdited {
                                    isEdited = false
                                    Task {
                                        do {
                                            try await userInventoryViewModel.fetchInventories(userId: realUserId)
                                            print("모달 닫힘 후 인벤토리 리로드 완료")
                                        } catch {
                                            print("모달 닫힘 후 인벤토리 로드 실패: \(error)")
                                        }
                                    }
                                }
                            }) { item in
                                userInventoryDetailView(item: item, realUserId: realUserId, isEdited: $isEdited)
                                        .presentationDetents([.medium])
                            }
                }
                
                // 에러 메시지 표시
                if let errorMessage = userInventoryViewModel.errorMessage {
                    Text("오류: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .onAppear {
                Task {
                    if authService.currentUserUID == "" {
                        realUserId = "23456"
                    } else {
                        realUserId = authService.currentUserUID
                    }
                    try await userInventoryViewModel.fetchInventories(userId: realUserId)
                }
            }
            .navigationTitle("가방")
        }
    }
}

#Preview {
    userInventoryView()
        .environmentObject(AuthService())
}
