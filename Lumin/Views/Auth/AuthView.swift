//
//  AuthView.swift
//  Lumin
//
//  Created by Андрей Прудников on 29.06.2025.
//

import SwiftUI

struct AuthView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var isSignUp = false
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Логотип
                VStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 60))
                        .foregroundColor(.purple)
                    
                    Text("Lumin")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Делитесь своими образами")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Форма
                VStack(spacing: 20) {
                    if isSignUp {
                        TextField("Имя пользователя", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                    }
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Пароль", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if isSignUp {
                        SecureField("Подтвердите пароль", text: $confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding(.horizontal)
                
                // Кнопка входа/регистрации
                Button(action: performAuth) {
                    HStack {
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        
                        Text(isSignUp ? "Зарегистрироваться" : "Войти")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(authManager.isLoading || !isFormValid)
                .padding(.horizontal)
                
                // Переключение между входом и регистрацией
                Button(action: { isSignUp.toggle() }) {
                    Text(isSignUp ? "Уже есть аккаунт? Войти" : "Нет аккаунта? Зарегистрироваться")
                        .foregroundColor(.purple)
                }
                
                Spacer()
            }
            .padding()
            .alert("Ошибка", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        if isSignUp {
            return !email.isEmpty && !username.isEmpty && !password.isEmpty && 
                   password == confirmPassword && password.count >= 6
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
    
    private func performAuth() {
        Task {
            do {
                if isSignUp {
                    try await authManager.signUp(email: email, username: username, password: password)
                } else {
                    try await authManager.signIn(email: email, password: password)
                }
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
}

#Preview {
    AuthView()
} 