//
//  SignUpView.swift
//  Grruung
//
//  Created by NoelMacMini on 4/30/25.
//

import SwiftUI

struct SignUpView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService
    
    @State private var email = ""          // 이메일
    @State private var userName = ""        // 사용자이름
    @State private var password = ""       // 비밀번호
    @State private var passwordCheck = ""  // 비밀번호 확인
    
    // 로딩 및 에러 상태
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // 입력 유효성 검사 로직 추가
    private var isValidEmail: Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    private var isValidPassword: Bool {
        password.count >= 6  // 최소 6자 이상
    }
    
    private var isValidUserName: Bool {
        userName.count >= 2  // 최소 2자 이상
    }
    
    
    // 전체 입력 유효성 검사
    private var isValidInput: Bool {
        !email.isEmpty &&
        !userName.isEmpty &&
        !password.isEmpty &&
        isValidEmail &&
        isValidPassword &&
        isValidUserName &&
        password == passwordCheck
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 20) {
                    // 이메일 입력 필드
                    TextField("이메일", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .disabled(isLoading)
                    if !isValidEmail && !email.isEmpty {
                        Text("유효한 이메일 주소를 입력해주세요")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    // 유저네임 입력 필드
                    TextField("사용자 이름", text: $userName)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .disabled(isLoading)
                    if !isValidUserName && !userName.isEmpty {
                        Text("이름은 최소 2자 이상이어야 합니다")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    // 비밀번호 입력 필드
                    SecureField("비밀번호", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isLoading)
                    if !isValidPassword && !password.isEmpty {
                        Text("비밀번호는 최소 6자 이상이어야 합니다")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    // 비밀번호 확인 입력 필드
                    SecureField("비밀번호 확인", text: $passwordCheck)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isLoading)
                    if password != passwordCheck && !passwordCheck.isEmpty {
                        Text("비밀번호가 일치하지 않습니다")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                    
                    // 회원가입 버튼
                    Button(action: {
                        Task {
                            await signUp()
                        }
                    }) {
                        Text("회원가입")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isValidInput ? Color.blue : Color.gray)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(!isValidInput || isLoading)
                }
                .padding()
                
                // 로딩 오버레이
                if isLoading {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                }
            }
            .navigationTitle("회원가입")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
            }
            .alert("회원가입 오류", isPresented: $showError) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Methods
    private func signUp() async {
        isLoading = true
        do {
            try await authService.signUp(userEmail: email, userName: userName, password: password)
            print("회원가입 성공")
            dismiss() // 성공 시 이전 화면(로그인 화면)으로 돌아감
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
}

// MARK: - Preview
#Preview {
    SignUpView()
}
