//
//  AuthSheet.swift
//  Sykle
//
//  Login/Signup sheet with multiple auth options
//

import SwiftUI

struct AuthSheet: View {
    @Binding var isPresented: Bool
    @Binding var isAuthenticated: Bool
    
    @State private var showEmailLogin = false
    
    let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)
    let buttonBackground = Color(red: 245/255, green: 240/255, blue: 235/255)
    let coral = Color(red: 230/255, green: 100/255, blue: 100/255)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header with close button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sign up")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(coral)
                    Text("Log in")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(sykleBlue)
                }
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(10)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.top, 40)
            
            Spacer()
                .frame(height: 20)
            
            // Auth buttons
            VStack(spacing: 16) {
                Button(action: { showEmailLogin = true }) {
                    HStack {
                        Spacer()
                        Text("Continue with email address")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                
                Button(action: {}) {
                    HStack {
                        Spacer()
                        Image(systemName: "apple.logo")
                            .font(.system(size: 18))
                            .foregroundColor(.black)
                        Text("Continue with Apple")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                
                Button(action: {}) {
                    HStack {
                        Spacer()
                        Image(systemName: "g.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.black)
                        Text("Continue with Google")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .background(Color.white)
        .sheet(isPresented: $showEmailLogin) {
            EmailLoginSheet(isAuthenticated: $isAuthenticated, parentSheet: $isPresented)
        }
    }
}

// MARK: - Email Login Sheet

struct EmailLoginSheet: View {
    @Binding var isAuthenticated: Bool
    @Binding var parentSheet: Bool
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var userManager = UserManager.shared
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showWelcome = false
    
    let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)

    var firstNameError: String? {
        let name = firstName.trimmingCharacters(in: .whitespaces)
        if name.isEmpty { return nil }
        if name.count < 2 { return "Must be at least 2 characters" }
        if name.count > 25 { return "Must be 25 characters or less" }
        let allowed = CharacterSet.letters.union(.init(charactersIn: " -'"))
        if name.unicodeScalars.contains(where: { !allowed.contains($0) }) {
            return "No numbers or special characters"
        }
        return nil
    }

    var lastNameError: String? {
        let name = lastName.trimmingCharacters(in: .whitespaces)
        if name.isEmpty { return nil }
        if name.count < 2 { return "Must be at least 2 characters" }
        if name.count > 25 { return "Must be 25 characters or less" }
        let allowed = CharacterSet.letters.union(.init(charactersIn: " -'"))
        if name.unicodeScalars.contains(where: { !allowed.contains($0) }) {
            return "No numbers or special characters"
        }
        return nil
    }

    var emailError: String? {
        let e = email.trimmingCharacters(in: .whitespaces).lowercased()
        if e.isEmpty { return nil }
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        guard e.range(of: emailRegex, options: .regularExpression) != nil else {
            return "Enter a valid email address"
        }
        let allowedDomains = [
            "gmail.com", "googlemail.com",
            "outlook.com", "hotmail.com", "hotmail.co.uk", "live.com", "msn.com",
            "yahoo.com", "yahoo.co.uk", "yahoo.fr",
            "icloud.com", "me.com", "mac.com",
            "protonmail.com", "proton.me",
            "aol.com",
            "mail.com",
            "gmx.com", "gmx.net",
            "goldsmiths.ac.uk", "ac.uk", "edu"
        ]
        let domain = e.components(separatedBy: "@").last ?? ""
        let isAllowed = allowedDomains.contains(where: { domain == $0 || domain.hasSuffix(".\($0)") || $0.hasPrefix(".") && domain.hasSuffix($0) })
        if !isAllowed { return "Please use a recognised email provider" }
        return nil
    }

    var passwordError: String? {
        if password.isEmpty { return nil }
        if password.count < 8 { return "Must be at least 8 characters" }
        if password.count > 64 { return "Must be 64 characters or less" }
        let hasUpper = password.contains(where: { $0.isUppercase })
        let hasNumber = password.contains(where: { $0.isNumber })
        if !hasUpper { return "Must contain at least one uppercase letter" }
        if !hasNumber { return "Must contain at least one number" }
        return nil
    }

    var isFormValid: Bool {
        !firstName.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        firstNameError == nil &&
        lastNameError == nil &&
        emailError == nil &&
        passwordError == nil
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                // sykle. logo
                Text("sykle.")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(sykleBlue)
                    .padding(.top, 16)
                
                // Title
                Text("Enter your\ndetails.")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                
                // Form fields
                VStack(spacing: 20) {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("First name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.black)
                            TextField("", text: $firstName)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(firstNameError != nil ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            if let err = firstNameError {
                                Text(err).font(.system(size: 11)).foregroundColor(.red)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Last name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.black)
                            TextField("", text: $lastName)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(lastNameError != nil ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            if let err = lastNameError {
                                Text(err).font(.system(size: 11)).foregroundColor(.red)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)
                        TextField("", text: $email)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(emailError != nil ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        if let err = emailError {
                            Text(err).font(.system(size: 11)).foregroundColor(.red)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)
                        HStack {
                            if showPassword {
                                TextField("Min 8 chars, 1 uppercase, 1 number", text: $password)
                            } else {
                                SecureField("Min 8 chars, 1 uppercase, 1 number", text: $password)
                            }
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(passwordError != nil ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        if let err = passwordError {
                            Text(err).font(.system(size: 11)).foregroundColor(.red)
                        }
                    }
                }
                .padding(.top, 24)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.top, 12)
                }
                
                Spacer()
                
                // Continue button
                Button(action: signIn) {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Continue")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .background(sykleBlue)
                    .cornerRadius(30)
                }
                .disabled(!isFormValid || isLoading)
                .opacity(!isFormValid ? 0.6 : 1)
                
                // Privacy text
                HStack {
                    Spacer()
                    VStack(spacing: 2) {
                        HStack(spacing: 4) {
                            Text("By proceeding, you consent to Sykle")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            Text("Data Consent Form")
                                .font(.system(size: 12))
                                .foregroundColor(sykleBlue)
                        }
                        HStack(spacing: 4) {
                            Text("and")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            Text("Privacy Policy")
                                .font(.system(size: 12))
                                .foregroundColor(sykleBlue)
                        }
                    }
                    Spacer()
                }
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .background(Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                    }
                }
            }
            // When sign in succeeds, show the welcome/onboarding flow
            .fullScreenCover(isPresented: $showWelcome) {
                WelcomeView(onComplete: {
                    showWelcome = false
                    isAuthenticated = true
                    dismiss()
                    parentSheet = false
                })
            }
        }
    }
    
    private func signIn() {
        isLoading = true
        errorMessage = nil
        
        let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        
        Task {
            await userManager.loginOrRegister(
                email: email,
                name: fullName.isEmpty ? nil : fullName,
                password: password
            )
            
            await MainActor.run {
                isLoading = false
                if userManager.isLoggedIn {
                    // Check if this is a returning user — skip welcome flow
                    let isReturning = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
                    if isReturning {
                        // Go straight to app
                        isAuthenticated = true
                        dismiss()
                        parentSheet = false
                    } else {
                        // New user — show welcome/health/notifications
                        showWelcome = true
                    }
                } else if let error = userManager.errorMessage {
                    errorMessage = error
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AuthSheet(isPresented: .constant(true), isAuthenticated: .constant(false))
}
