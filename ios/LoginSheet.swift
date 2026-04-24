//
//  LoginSheet.swift
//  Sykle
//

import SwiftUI

enum LoginStep: Equatable {
    case enterEmail
    case welcomeBack(userName: String)
    case newUser
}

struct LoginSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var userManager = UserManager.shared

    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var showPassword = false
    @State private var step: LoginStep = .enterEmail
    @State private var isLoading = false
    @State private var errorMessage: String?

    let sykleBlue = Color("SykleBlue")

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {

                VStack(spacing: 6) {
                    Text("sykle.")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(sykleBlue)
                    Text(stepSubtitle)
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut, value: stepSubtitle)
                }
                .padding(.top, 40)
                .padding(.bottom, 32)

                VStack(spacing: 16) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                        HStack {
                            TextField("your@email.com", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .disabled(isEmailLocked)
                            if isEmailLocked {
                                Button(action: resetToEmailStep) {
                                    Image(systemName: "pencil")
                                        .foregroundColor(sykleBlue)
                                }
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isEmailLocked ? sykleBlue.opacity(0.4) : Color.clear, lineWidth: 1.5)
                        )
                    }

                    // Password field — shown for welcomeBack and newUser
                    if step != .enterEmail {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            HStack {
                                if showPassword {
                                    TextField("Password", text: $password)
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()
                                } else {
                                    SecureField("Password", text: $password)
                                }
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(10)

                            if case .newUser = step {
                                if let err = passwordError {
                                    Text(err)
                                        .font(.system(size: 11))
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Name field — only for new users
                    if case .newUser = step {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                            TextField("What should we call you?", text: $name)
                                .padding()
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(10)
                                .autocorrectionDisabled()
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Welcome back badge
                    if case .welcomeBack(let userName) = step {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 20))
                            Text("Welcome back, \(userName)!")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.green.opacity(0.08))
                        .cornerRadius(10)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 24)
                .animation(.easeInOut(duration: 0.25), value: stepKey)

                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .transition(.opacity)
                }

                Spacer()

                Button(action: primaryAction) {
                    HStack(spacing: 8) {
                        if isLoading { ProgressView().tint(.white) }
                        Text(isLoading ? "Please wait..." : buttonLabel)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isButtonEnabled ? sykleBlue : Color.gray)
                    .cornerRadius(14)
                }
                .disabled(!isButtonEnabled || isLoading)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .animation(.easeInOut, value: isButtonEnabled)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Computed helpers

    private var stepSubtitle: String {
        switch step {
        case .enterEmail: return "Enter your email to continue"
        case .welcomeBack: return "Good to see you again"
        case .newUser: return "Let's get you set up"
        }
    }

    private var buttonLabel: String {
        switch step {
        case .enterEmail: return "Continue"
        case .welcomeBack: return "Sign In"
        case .newUser: return "Create Account"
        }
    }

    private var isEmailLocked: Bool {
        if case .enterEmail = step { return false }
        return true
    }

    private var passwordError: String? {
        if password.isEmpty { return nil }
        if password.count < 8 { return "Must be at least 8 characters" }
        if !password.contains(where: { $0.isUppercase }) { return "Must contain at least one uppercase letter" }
        if !password.contains(where: { $0.isNumber }) { return "Must contain at least one number" }
        return nil
    }

    private var isButtonEnabled: Bool {
        switch step {
        case .enterEmail: return isValidEmail
        case .welcomeBack: return !password.isEmpty
        case .newUser: return !name.trimmingCharacters(in: .whitespaces).isEmpty
                            && !password.isEmpty
                            && passwordError == nil
        }
    }

    private var stepKey: String {
        switch step {
        case .enterEmail: return "email"
        case .welcomeBack: return "welcome"
        case .newUser: return "new"
        }
    }

    private var isValidEmail: Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return email.range(of: regex, options: .regularExpression) != nil
    }

    // MARK: - Actions

    private func primaryAction() {
        errorMessage = nil
        switch step {
        case .enterEmail: checkEmail()
        case .welcomeBack: signIn()
        case .newUser: register()
        }
    }

    private func resetToEmailStep() {
        withAnimation { step = .enterEmail }
        password = ""
        name = ""
        errorMessage = nil
    }

    private func checkEmail() {
        isLoading = true
        let cleanEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
        Task {
            do {
                let exists = try await NetworkManager.shared.checkEmailExists(cleanEmail)
                await MainActor.run {
                    isLoading = false
                    withAnimation {
                        step = exists
                            ? .welcomeBack(userName: cleanEmail.components(separatedBy: "@").first?.capitalized ?? "there")
                            : .newUser
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Couldn't reach the server. Check your connection."
                }
            }
        }
    }

    private func signIn() {
        isLoading = true
        Task {
            await userManager.loginOrRegister(
                email: email.lowercased().trimmingCharacters(in: .whitespaces),
                name: nil,
                password: password
            )
            await MainActor.run {
                isLoading = false
                if userManager.isLoggedIn { dismiss() }
                else { errorMessage = userManager.errorMessage ?? "Sign in failed. Check your password." }
            }
        }
    }

    private func register() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter your name."
            return
        }
        isLoading = true
        Task {
            await userManager.loginOrRegister(
                email: email.lowercased().trimmingCharacters(in: .whitespaces),
                name: name.trimmingCharacters(in: .whitespaces),
                password: password
            )
            await MainActor.run {
                isLoading = false
                if userManager.isLoggedIn { dismiss() }
                else { errorMessage = userManager.errorMessage ?? "Couldn't create account." }
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
