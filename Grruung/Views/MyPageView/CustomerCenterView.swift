//
//  CustomerCenterView.swift
//  Grruung
//
<<<<<<< Updated upstream
//  Created by subin on 6/10/25.
=======
//  Created by subin on 6/9/25.
>>>>>>> Stashed changes
//

import SwiftUI

<<<<<<< Updated upstream
// MARK: - FAQ 뷰

struct CustomerCenterView: View {
    @State private var expandedFAQs: Set<UUID> = []
=======
// MARK: - FAQ 모델
struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

// MARK: - FAQ 데이터 서비스
class FAQDataService {
    static let shared = FAQDataService()
    
    private init() {}
    
    let faqItems: [FAQItem] = [
        FAQItem(question: "앱 알림이 오지 않아요", answer: "설정 > 알림에서 알림 허용 여부를 확인해주세요. iOS 설정에서도 해당 앱의 알림 권한이 활성화되어 있는지 확인해보세요."),
        FAQItem(question: "캐릭터가 사라졌어요", answer: "앱을 다시 실행하거나 로그인을 확인해주세요. 문제가 지속되면 앱을 완전히 종료한 후 재실행해보세요."),
        FAQItem(question: "구매 내역은 어디서 확인하나요?", answer: "마이페이지 > 결제내역에서 확인하실 수 있어요. 구매 후 영수증은 이메일로도 발송됩니다."),
        FAQItem(question: "데이터는 안전하게 보관되나요?", answer: "모든 정보는 최신 암호화 기술로 보호되며, 개인정보 보호 정책에 따라 안전하게 관리됩니다."),
        FAQItem(question: "앱을 탈퇴하고 싶어요", answer: "설정 > 계정 > 회원 탈퇴에서 진행하실 수 있습니다. 탈퇴 시 모든 데이터가 삭제되니 신중히 결정해주세요.")
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
                
                // 텍스트 입력 필드
                TextEditor(text: $inquiryText)
                    .frame(minHeight: 200)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .overlay(
                        // 플레이스홀더 텍스트
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
                                .allowsHitTesting(false)
                            }
                        }
                    )
                
                Spacer()
                
                // 전송 버튼
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
                    .cornerRadius(10)
                }
                .disabled(inquiryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .animation(.easeInOut(duration: 0.2), value: inquiryText.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .navigationTitle("문의하기")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
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
    // 샘플 문의내역 데이터
    let inquiryHistory = [
        ("앱 알림 문제", "2024-06-08", "답변 완료"),
        ("결제 관련 문의", "2024-06-05", "처리 중"),
        ("기능 개선 제안", "2024-06-01", "검토 중")
    ]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(inquiryHistory.enumerated()), id: \.offset) { index, inquiry in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(inquiry.0)
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text(inquiry.2)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    inquiry.2 == "답변 완료" ? Color.green.opacity(0.2) :
                                    inquiry.2 == "처리 중" ? Color.orange.opacity(0.2) :
                                    Color.blue.opacity(0.2)
                                )
                                .foregroundColor(
                                    inquiry.2 == "답변 완료" ? .green :
                                    inquiry.2 == "처리 중" ? .orange :
                                    .blue
                                )
                                .cornerRadius(8)
                        }
                        
                        Text(inquiry.1)
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
    @State private var expandedFAQ: UUID?
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
                    // 헤더
=======
                    // 헤더 섹션
>>>>>>> Stashed changes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("자주 묻는 질문")
                            .font(.title2)
                            .fontWeight(.bold)
<<<<<<< Updated upstream
                        
                        Text("궁금한 내용을 빠르게 찾아보세요")
                            .font(.subheadline)
                            .foregroundColor(.gray)
=======
                            .foregroundColor(.primary)
                        
                        Text("궁금한 내용을 빠르게 찾아보세요")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
>>>>>>> Stashed changes
                    }
                    .padding(.bottom, 8)
                    
                    // 검색 바
                    HStack {
                        Image(systemName: "magnifyingglass")
<<<<<<< Updated upstream
                            .foregroundColor(.black)
                        
                        TextField("질문을 입력해주세요.", text: $searchText)
=======
                            .foregroundColor(.secondary)
                        
                        TextField("궁금한 것을 검색해보세요.", text: $searchText)
>>>>>>> Stashed changes
                            .textFieldStyle(PlainTextFieldStyle())
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
<<<<<<< Updated upstream
                                    .foregroundColor(.black)
=======
                                    .foregroundColor(.secondary)
>>>>>>> Stashed changes
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
<<<<<<< Updated upstream
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange, lineWidth: 2)
                    )
                    .cornerRadius(12)
                    
                    // FAQ 목록 또는 검색 결과 없음
=======
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // FAQ 리스트
>>>>>>> Stashed changes
                    if filteredFAQs.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
<<<<<<< Updated upstream
                                .foregroundColor(.gray)
                            
                            Text("검색 결과가 없습니다")
                                .font(.headline)
                            
                            Text("다른 키워드로 검색해보세요")
                                .font(.subheadline)
                                .foregroundColor(.gray)
=======
                                .foregroundColor(.secondary)
                            
                            Text("검색 결과가 없습니다")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("다른 키워드로 검색해보세요")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
>>>>>>> Stashed changes
                        }
                        .padding(.vertical, 40)
                        .frame(maxWidth: .infinity)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredFAQs) { faq in
                                FAQItemView(
                                    faq: faq,
<<<<<<< Updated upstream
                                    isExpanded: expandedFAQs.contains(faq.id),
                                    onTap: {
                                        withAnimation(
                                            .easeInOut(duration: 0.3)
                                        ) {
                                            if expandedFAQs.contains(faq.id) {
                                                expandedFAQs.remove(faq.id)
                                            } else {
                                                expandedFAQs.insert(faq.id)
                                            }
=======
                                    isExpanded: expandedFAQ == faq.id,
                                    onTap: {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            expandedFAQ = (expandedFAQ == faq.id) ? nil : faq.id
>>>>>>> Stashed changes
                                        }
                                    }
                                )
                            }
                        }
                    }
                    
<<<<<<< Updated upstream
                    // 도움 섹션
                    VStack(alignment: .leading, spacing: 16) {
                        Text("도움이 필요하신가요?")
                            .font(.headline)
                        
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
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
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
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
=======
                    // 도움 요청 섹션
                    VStack(alignment: .leading, spacing: 16) {
                        Divider()
                            .padding(.vertical, 8)
                        
                        Text("도움이 필요하신가요?")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            // 문의하기 버튼
                            NavigationLink(destination: InquiryView()) {
                                HStack {
                                    Image(systemName: "square.and.pencil")
                                        .foregroundColor(.blue)
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("문의하기")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 12))
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 16)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                            
                            // 문의내역 보기 버튼
                            NavigationLink(destination: InquiryHistoryView()) {
                                HStack {
                                    Image(systemName: "doc.text")
                                        .foregroundColor(.green)
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("문의내역 보기")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 12))
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 16)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
>>>>>>> Stashed changes
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

<<<<<<< Updated upstream
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
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(
                        systemName: isExpanded ? "chevron.up" : "chevron.down"
                    )
                    .foregroundColor(.gray)
                    .font(.system(size: 14, weight: .medium))
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
            }
            
            if isExpanded {
                Text(faq.answer)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
        }
    }
}

// MARK: - 문의하기 뷰

struct InquiryView: View {
    @State private var inquiryTitle = ""
    @State private var inquiryText = ""
    @State private var showingAlert = false
    @ObservedObject private var inquiryManager = InquiryManager.shared
    @Environment(\.dismiss) private var dismiss
    
    private var isFormValid: Bool {
        !inquiryTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !inquiryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                // 헤더
                VStack(alignment: .leading, spacing: 8) {
                    Text("문의사항을 작성해주세요")
                        .font(.headline)
                    
                    Text("궁금한 점이나 문제가 있으시면 아래에 자세히 적어주세요.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // 제목 입력
                VStack(alignment: .leading, spacing: 8) {
                    Text("제목")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("문의 제목을 입력해주세요", text: $inquiryTitle)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                // 내용 입력
                VStack(alignment: .leading, spacing: 8) {
                    Text("내용")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $inquiryText)
                            .frame(minHeight: 150)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        Color.gray.opacity(0.3),
                                        lineWidth: 1
                                    )
                            )
                        
                        if inquiryText.isEmpty {
                            Text(
                                "문의내용을 입력해주세요.\n\n예시:\n- 앱 사용 중 발생한 문제\n- 기능 관련 질문\n- 개선사항 제안"
                            )
                            .foregroundColor(.gray)
                            .font(.subheadline)
                            .padding(16)
                            .allowsHitTesting(false)
                        }
                    }
                }
                
                Spacer()
                
                // 제출 버튼
                Button(action: {
                    inquiryManager.addInquiry(
                        title: inquiryTitle
                            .trimmingCharacters(in: .whitespacesAndNewlines),
                        content: inquiryText
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                    
                    showingAlert = true
                    inquiryTitle = ""
                    inquiryText = ""
                }) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("문의하기")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isFormValid ? Color.orange : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(!isFormValid)
                .animation(.easeInOut(duration: 0.2), value: isFormValid)
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
    @ObservedObject private var inquiryManager = InquiryManager.shared
    @State private var expandedInquiries: Set<UUID> = []
    
    var body: some View {
        NavigationStack {
            if inquiryManager.inquiries.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("문의 내역이 없습니다")
                        .font(.headline)
                    
                    Text("궁금한 점이 있으시면 문의하기를 이용해주세요")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(inquiryManager.inquiries) { inquiry in
                            InquiryItemView(
                                inquiry: inquiry,
                                isExpanded: expandedInquiries
                                    .contains(inquiry.id),
                                onTap: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        if expandedInquiries
                                            .contains(inquiry.id) {
                                            expandedInquiries.remove(inquiry.id)
                                        } else {
                                            expandedInquiries.insert(inquiry.id)
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
        .navigationTitle("문의내역")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 문의내역 상세 뷰

struct InquiryItemView: View {
    let inquiry: Inquiry
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(inquiry.title)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                            .multilineTextAlignment(.leading)
                            .lineLimit(isExpanded ? nil : 1)
                        
                        if isExpanded {
                            Text(inquiry.content)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineSpacing(4)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
                            
                            Text(inquiry.date)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Text(inquiry.status)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                inquiry.status == "답변 완료" ? Color.orange
                                    .opacity(0.2) : Color.gray
                                    .opacity(0.2)
                            )
                            .foregroundColor(
                                inquiry.status == "답변 완료" ? .orange : .gray
                            )
                            .cornerRadius(6)
                        
                        Image(
                            systemName: isExpanded ? "chevron.up" : "chevron.down"
                        )
                        .foregroundColor(.gray)
                        .font(.system(size: 14, weight: .medium))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
            }
            .accessibilityLabel(
                "\(inquiry.title). 접수일: \(inquiry.date). 상태: \(inquiry.status)"
            )
            .accessibilityHint(isExpanded ? "내용 숨기기" : "내용 보기")
        }
    }
}

// MARK: - 프리뷰
=======
>>>>>>> Stashed changes
#Preview {
    CustomerCenterView()
}
