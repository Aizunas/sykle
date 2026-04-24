//
//  NotificationsPermissionView.swift
//  Sykle
//
//  Notifications permission screen shown after HealthKit sync
//

import SwiftUI
import UserNotifications

struct NotificationsPermissionView: View {
    let onComplete: () -> Void

    @State private var isRequesting = false

    let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Top bar
            HStack {
                Button(action: onComplete) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                }
                Spacer()
                Button(action: onComplete) {
                    Text("Skip")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                }
            }
            .padding(.top, 16)

            // sykle. logo
            Text("sykle.")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(sykleBlue)
                .padding(.top, 16)

            Spacer()

            // Bell icon from Assets
            Image("BellIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 110, height: 110)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 32)

            // Headline
            Text("Stay in the loop")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)

            Text("can we send you notifications?")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)
                .padding(.top, 2)

            // Body copy
            Text("Sykle uses notifications to remind you to stay active, notify you when you earn rewards and share updates about new reward partners")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.black)
                .padding(.top, 16)

            Spacer()

            // Footer note
            Text("You can change this at any time in settings.")
                .font(.system(size: 14))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 16)

            // Continue button
            Button(action: requestNotifications) {
                HStack {
                    Spacer()
                    if isRequesting {
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
            .disabled(isRequesting)
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
        .background(Color.white)
        .ignoresSafeArea(edges: .bottom)
    }

    // Triggers Apple's native notification permission dialog.
    // Whatever the user chooses (Allow / Don't Allow), we move on.
    private func requestNotifications() {
        isRequesting = true
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { _, _ in
            DispatchQueue.main.async {
                isRequesting = false
                onComplete()
            }
        }
    }
}

#Preview {
    NotificationsPermissionView(onComplete: {})
}
