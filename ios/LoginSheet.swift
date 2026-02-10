//
//  LoginSheet.swift
//  Sykle
//
//  Simple login/registration sheet
//

import SwiftUI

struct LoginSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var userManager = UserManager.shared
    
    @State private var email = ""
    @State private var name = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Logo
                VStack(spacing: 8) {
                    Text("sykle.")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(Color("SykleBlue"))
                    
                    Text("Sign in to save your progress")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
                
                // Form
                VStack(spacing: 16) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        
                        TextField("your@email.com", text: $email)
                            .textFieldStyle(RoundedTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    
                    // Name field (optional)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name (optional)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        
                        TextField("Your name", text: $name)
                            .textFieldStyle(RoundedTextFieldStyle())
                    }
                }
                .padding(.horizontal, 24)
                
                // Error message
                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                // Sign in button
                Button(action: signIn) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isLoading ? "Signing in..." : "Sign In")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isValidEmail ? Color("SykleBlue") : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(!isValidEmail || isLoading)
                .padding(.horizontal, 24)
                
                // Info text
                Text("We'll create an account if you don't have one")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    private func signIn() {
        isLoading = true
        errorMessage = nil
        
        Task {
            await userManager.loginOrRegister(
                email: email.lowercased().trimmingCharacters(in: .whitespaces),
                name: name.isEmpty ? nil : name
            )
            
            await MainActor.run {
                isLoading = false
                
                if userManager.isLoggedIn {
                    dismiss()
                } else if let error = userManager.errorMessage {
                    errorMessage = error
                }
            }
        }
    }
}

// MARK: - Custom Text Field Style

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(10)
    }
}

// MARK: - Preview

struct LoginSheet_Previews: PreviewProvider {
    static var previews: some View {
        LoginSheet()
    }
}
