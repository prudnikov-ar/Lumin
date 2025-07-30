//
//  TestApp.swift
//  Lumin
//
//  Created by Андрей Прудников on 29.06.2025.
//

import SwiftUI

struct TestApp: App {
    var body: some Scene {
        WindowGroup {
            TestView()
        }
    }
}

struct TestView: View {
    @State private var email = ""
    @State private var password = ""
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
                    
                    Text("Lumin Test")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Тестовое приложение")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Форма
                VStack(spacing: 20) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Пароль", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                
                // Кнопка тестирования
                Button(action: testFunctionality) {
                    Text("Тест функциональности")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .alert("Тест", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func testFunctionality() {
        // Простой тест без сетевых запросов
        alertMessage = "Приложение работает корректно!"
        showAlert = true
    }
}

#Preview {
    TestView()
} 