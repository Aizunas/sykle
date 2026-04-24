//
//  EditDetailsView.swift
//  Sykle
//

import SwiftUI

struct EditDetailsView: View {
    @StateObject private var userManager = UserManager.shared
    @Environment(\.dismiss) var dismiss

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isSaving = false
    @State private var saved = false

    let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                Text("Update your name as it appears in the app.")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                FormSection(title: "Your name") {
                    FormField(label: "First name", placeholder: "e.g. Sarah", text: $firstName)
                    Divider().padding(.leading, 16)
                    FormField(label: "Last name", placeholder: "e.g. Jones", text: $lastName)
                }

                // Email — read only
                FormSection(title: "Account") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .padding(.top, 12)
                            .padding(.horizontal, 16)
                        Text(userManager.currentUser?.email ?? "")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                    }
                }

                if saved {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Details updated successfully")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 20)
                    .transition(.opacity)
                }

                Button(action: {
                    Task {
                        isSaving = true
                        await userManager.updateUser(
                            firstName: firstName.trimmingCharacters(in: .whitespaces),
                            lastName: lastName.trimmingCharacters(in: .whitespaces)
                        )
                        isSaving = false
                        withAnimation { saved = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { saved = false }
                        }
                    }
                }) {
                    HStack {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text("Save changes")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(firstName.isEmpty && lastName.isEmpty ? Color.gray : sykleBlue)
                    .cornerRadius(30)
                }
                .disabled(firstName.isEmpty && lastName.isEmpty)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Edit details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            firstName = userManager.currentUser?.firstName ?? ""
            lastName = userManager.currentUser?.lastName ?? ""
        }
    }
}
