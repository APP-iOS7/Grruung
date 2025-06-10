//
//  CustomerCenterView.swift
//  Grruung
//
//  Created by subin on 6/10/25.
//

import SwiftUI

// MARK: - FAQ 모델

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

// MARK: - 문의내역 모델

struct Inquiry: Identifiable {
    let id = UUID()
    let title: String
    let date: String
    let status: String
}

// MARK: - FAQ 데이터 서비스

class FAQDataService {
    static let shared = FAQDataService()
    
    let faqItems: [FAQItem] = [
        .init(question: "앱 알림이 오지 않아요", answer: "설정 > 알림에서 알림 허용 여부를 확인해주세요. iOS 설정에서도 해당 앱의 알림 권한이 활성화되어 있는지 확인해보세요."),
        .init(question: "캐릭터가 사라졌어요", answer: "앱을 다시 실행하거나 로그인을 확인해주세요. 문제가 지속되면 앱을 완전히 종료한 후 재실행해보세요."),
        .init(question: "구매 내역은 어디서 확인하나요?", answer: "마이페이지 > 결제내역에서 확인하실 수 있어요. 구매 후 영수증은 이메일로도 발송됩니다."),
        .init(question: "환불은 어떻게 하나요?", answer: "환불관련된 문의는 문의하기에 남겨주시기 바랍니다."),
        .init(question: "앱을 탈퇴하고 싶어요", answer: "설정 > 계정 > 회원 탈퇴에서 진행하실 수 있습니다. 탈퇴 시 모든 데이터가 삭제되니 신중히 결정해주세요.")
    ]
}

// MARK: - 문의하기 뷰

struct InquiryView: View {
    @State private var inquiryText = ""
    @State private var showingAlert = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("문의사항을 작성해주세요")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("궁금한 점이나 문제가 있으시면 아래에 자세히 적어주세요.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                TextEditor(text: $inquiryText)
                    .frame(minHeight: 200)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        Group {
                            if inquiryText.isEmpty {
                                VStack {
                                    HStack {
                                        Text("문의내용을 입력해주세요...\n\n예시:\n- 앱 사용 중 발생한 문제\n- 기능 관련 질문\n- 개선사항 제안")
                                            .foregroundColor(.secondary)
                                            .font(.subheadline)
                                        Spacer()
                                    }
                                    Spacer()
                                }
                                .padding(16)
                            }
                        }
                    )
                
                Spacer()
                
                Button(action: {
                    if !inquiryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        showingAlert = true
                        inquiryText = ""
                    }
                }) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("문의하기")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        inquiryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                        Color.gray : Color.blue
                    )
                    .cornerRadius(12)
                }
                .disabled(inquiryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .animation(.easeInOut(duration: 0.2), value: inquiryText.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .navigationTitle("문의하기")
            .navigationBarTitleDisplayMode(.inline)
            .alert("문의 접수 완료", isPresented: $showingAlert) {
                Button("확인", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("문의사항이 접수되었습니다.\n빠른 시일 내에 답변 드리겠습니다.")
            }
        }
    }
}

// MARK: - 문의내역 뷰

struct InquiryHistoryView: View {
    let inquiryHistory: [Inquiry] = [
        Inquiry(title: "앱 알림 문제", date: "2024-06-08", status: "답변 완료"),
        Inquiry(title: "결제 관련 문의", date: "2024-06-05", status: "처리 중"),
        Inquiry(title: "기능 개선 제안", date: "2024-06-01", status: "검토 중")
    ]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(inquiryHistory) { inquiry in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(inquiry.title)
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text(inquiry.status)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    inquiry.status == "답변 완료" ? Color.green.opacity(0.2) :
                                        inquiry.status == "처리 중" ? Color.orange.opacity(0.2) :
                                        Color.blue.opacity(0.2)
                                )
                                .foregroundColor(
                                    inquiry.status == "답변 완료" ? .green :
                                        inquiry.status == "처리 중" ? .orange :
                                            .blue
                                )
                                .cornerRadius(8)
                        }
                        Text(inquiry.date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("문의내역")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - FAQ 개별 항목 뷰

struct FAQItemView: View {
    let faq: FAQItem
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack {
                    Text(faq.question)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14, weight: .medium))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
            }
            .accessibilityLabel(faq.question)
            .accessibilityHint(isExpanded ? "답변 숨기기" : "답변 보기")
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                        Divider()
                            .padding(.horizontal, 16)
                        
                        
                        Text(faq.answer)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    }
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .move(edge: .top))
                        ))
                }
            }
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }

// MARK: - 고객센터 뷰

struct CustomerCenterView: View {
    @State private var expandedFAQs: Set<UUID> = []
    @State private var searchText = ""
    
    private var filteredFAQs: [FAQItem] {
        if searchText.isEmpty {
            return FAQDataService.shared.faqItems
        } else {
            return FAQDataService.shared.faqItems.filter {
                $0.question.localizedCaseInsensitiveContains(searchText) ||
                $0.answer.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("자주 묻는 질문")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("궁금한 내용을 빠르게 찾아보세요")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    .padding(.bottom, 8)
                    
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.primary)
                        
                        TextField("질문을 입력해주세요.", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "#FFB778"), Color(hex: "#FFA04D")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    
                    if filteredFAQs.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text("검색 결과가 없습니다")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("다른 키워드로 검색해보세요")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 40)
                        .frame(maxWidth: .infinity)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredFAQs) { faq in
                                FAQItemView(
                                    faq: faq,
                                    isExpanded: expandedFAQs.contains(faq.id),
                                    onTap: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            if expandedFAQs.contains(faq.id) {
                                                expandedFAQs.remove(faq.id)
                                            } else {
                                                expandedFAQs.insert(faq.id)
                                            }
                                        }
                                    }
                                )
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Divider()
                            .padding(.vertical, 8)
                        
                        Text("도움이 필요하신가요?")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        // 가로 배치로 변경
                        HStack(spacing: 12) {
                            NavigationLink(destination: InquiryView()) {
                                HStack(spacing: 12) {
                                    Image(systemName: "square.and.pencil")
                                        .foregroundColor(.orange)
                                        .font(.title2)
                                    
                                    Text("문의하기")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 16)
                                .background()
                                .cornerRadius(12)
                            }
                            
                            NavigationLink(destination: InquiryHistoryView()) {
                                HStack(spacing: 12) {
                                    Image(systemName: "doc.text")
                                        .foregroundColor(.orange)
                                        .font(.title2)
                                    
                                    Text("문의내역")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 16)
                                .background()
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("고객센터")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - 프리뷰
#Preview {
    CustomerCenterView()
}
