//
//  ProfileView.swift
//  Sykle
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @StateObject private var userManager = UserManager.shared
    @State private var showingBasket = false
    @State private var showingImagePicker = false
    @State private var profileImage: UIImage? = ProfileView.loadSavedImage()
    @State private var showingLogoutConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var showAuthSheet = false
    
    

    let sykleBlue   = Color.sykleMid
    let sykleNavy   = Color.sykleNavy
    let sykleYellow = Color(hex: "FED903")
    let cardBlue    = Color.sykleLight

    var currentPoints: Int {
        userManager.isLoggedIn ? userManager.serverPoints : healthKitManager.totalPoints
    }

    var pointsToNextReward: Int {
        let partnerStore = PartnerStore.shared
        
        // Find the minimum reward cost across all partners
        let minRewardCost = partnerStore.partners.compactMap { partner in
            partnerStore.getRewards(for: partner.name).map { $0.syklesCost }.min()
        }.min() ?? 3000  // fallback to 3000 if no rewards loaded yet

        let needed = minRewardCost - currentPoints
        return max(0, needed)
    }
    
    var userName: String {
        userManager.currentUser?.displayName ?? "Cyclist"
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {

                    ProfileHeaderView(
                        userName: userName,
                        currentPoints: currentPoints,
                        profileImage: profileImage,
                        sykleBlue: sykleBlue,
                        sykleYellow: sykleYellow,
                        showingBasket: $showingBasket,
                        showingImagePicker: $showingImagePicker
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // MARK: Your stats
                    StatsSection(
                        currentPoints: currentPoints,
                        pointsToNextReward: pointsToNextReward,
                    )

                    // MARK: Account
                    ProfileSection(title: "Account") {
                        ProfileRow(title: "Edit details", destination: AnyView(EditDetailsView()))
                        Divider().padding(.leading, 16)
                        ProfileRow(title: "Past orders", destination: AnyView(PastOrdersView()))
                    }

                    // MARK: App settings
                    ProfileSection(title: "App settings") {
                        Button(action: {
                            if let url = URL(string: "app-settings:") {
                                if UIApplication.shared.canOpenURL(url) {
                                    UIApplication.shared.open(url)
                                } else if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }) {
                            HStack {
                                Text("Push notifications")
                                    .font(.system(size: 15))
                                    .foregroundColor(.black)
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                        Divider().padding(.leading, 16)
                        Button(action: {
                            if let url = URL(string: "x-apple-health://") {
                                if UIApplication.shared.canOpenURL(url) {
                                    UIApplication.shared.open(url)
                                } else if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }) {
                            HStack {
                                Text("Health integrations")
                                    .font(.system(size: 15))
                                    .foregroundColor(.black)
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                    }

                    // MARK: Join our mission
                    ProfileSection(title: "Join our mission") {
                        ShareLink(
                            item: "Join me on Sykle — earn rewards just for cycling! 🚴 Download the app here: https://sykle.app",
                            subject: Text("Try Sykle"),
                            message: Text("Earn sykles for every ride and redeem them at local cafés and bakeries.")
                        ) {
                            HStack {
                                Text("Refer a friend")
                                    .font(.system(size: 15))
                                    .foregroundColor(.black)
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                        Divider().padding(.leading, 16)
                        ProfileRow(title: "Suggest a partner", destination: AnyView(SuggestPartnerView()))
                        Divider().padding(.leading, 16)
                        ProfileRow(title: "Become a partner", destination: AnyView(BecomePartnerView()))
                    }

                    // MARK: Customer support
                    NavigationLink(destination: SupportChatView()) {
                        HStack(spacing: 16) {
                            Image(systemName: "headphones")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Customer support")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("chat with us")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            Spacer()
                            Image(systemName: "arrow.right")
                                .foregroundColor(.white)
                        }
                        .padding(20)
                        .background(sykleBlue)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                    }
                    .buttonStyle(PlainButtonStyle())

                    // MARK: About the app
                    ProfileSection(title: "About the app") {
                        ProfileRow(title: "Rate and review", destination: AnyView(RateAndReviewView()))
                        Divider().padding(.leading, 16)
                        ProfileRow(title: "FAQs", destination: AnyView(FAQsView()))
                        Divider().padding(.leading, 16)
                        ProfileRow(title: "Terms and conditions", destination: AnyView(TermsAndConditionsView()))
                        Divider().padding(.leading, 16)
                        ProfileRow(title: "Privacy policy", destination: AnyView(PrivacyPolicyView()))
                    }

                    // MARK: Log out / Delete
                    VStack(spacing: 0) {
                        Button(action: { showingLogoutConfirmation = true }) {
                            Text("Log out")
                                .font(.system(size: 15))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                        }
                        Divider().padding(.leading, 16)
                        Button(action: { showingDeleteConfirmation = true }) {
                            Text("Delete account")
                                .font(.system(size: 15))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)

                } // end main VStack
            } // end ScrollView
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("sykle.")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(sykleBlue)
                        .fixedSize()
                }
            }
            .sheet(isPresented: $showingBasket) {
                BasketView()
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $profileImage)
            }
            .alert("Log out?", isPresented: $showingLogoutConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Log out", role: .destructive) {
                    performLogout()
                    showAuthSheet = true
                }
            } message: {
                Text("You'll need to sign in again to access your sykles and rewards.")
            }
            
            .alert("Delete account?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await UserManager.shared.deleteAccount()
                        showAuthSheet = true
                    }
                }
            } message: {
                Text("This will permanently delete your account, all your sykles, and ride history. This cannot be undone.")
            }
            .fullScreenCover(isPresented: $showAuthSheet) {
                OnboardingCarouselView(showOnboarding: $showAuthSheet)
            }
            
            .onChange(of: profileImage) { _, newImage in
                if let newImage = newImage {
                    saveImage(newImage)
                }
            }
        } // end NavigationView
    }

    func formatCO2(_ grams: Double) -> String {
        if grams >= 1000 { return String(format: "%.1fkg", grams / 1000) }
        return String(format: "%.0fg", grams)
    }
    private static var profileImagePath: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("profile_image.jpg")
    }

    private static func loadSavedImage() -> UIImage? {
        guard let data = try? Data(contentsOf: profileImagePath) else { return nil }
        return UIImage(data: data)
    }

    private func saveImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        try? data.write(to: ProfileView.profileImagePath)
    }
    
    private func performLogout() {
        UserManager.shared.clearUser()
        //UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    }
}

struct ProfileHeaderView: View {
    let userName: String
    let currentPoints: Int
    let profileImage: UIImage?
    let sykleBlue: Color
    let sykleYellow: Color

    @Binding var showingBasket: Bool
    @Binding var showingImagePicker: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            VStack(alignment: .leading, spacing: 10) {

                HStack(spacing: 4) {
                    Text("hi,")
                    Text(userName).bold()
                }
                .font(.system(size: 24))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(sykleBlue)
                .cornerRadius(12)

                HStack(spacing: 6) {
                    Image("SykleLogo")
                        .resizable()
                        .frame(width: 16, height: 16)
                    Text("\(currentPoints) sykles")
                }
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.white)
                .cornerRadius(20)

                HStack(spacing: 14) {
                    NavigationLink(destination: FavouritesView()) {
                        Image(systemName: "star.fill")
                            .foregroundColor(sykleYellow)
                    }

                    Button { showingBasket = true } label: {
                        Image(systemName: "cart")
                    }
                }
                .font(.system(size: 20))
            }

            Spacer()

            Button { showingImagePicker = true } label: {
                ZStack(alignment: .bottomTrailing) {
                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 90, height: 90)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(sykleBlue.opacity(0.2))
                            .frame(width: 90, height: 90)
                    }

                    Circle()
                        .fill(sykleBlue)
                        .frame(width: 26, height: 26)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

// MARK: - Profile Section

struct ProfileSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 20)
            VStack(spacing: 0) { content }
                .background(Color.white)
                .cornerRadius(16)
                .padding(.horizontal, 20)
        }
    }
}

// MARK: - Push Notifications Settings

struct PushNotificationsSettingsView: View {
    @State private var authStatus: UNAuthorizationStatus = .notDetermined
    let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image("BellIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)

            VStack(spacing: 8) {
                Text(authStatus == .authorized ? "Notifications are on" : "Notifications are off")
                    .font(.system(size: 22, weight: .bold))
                Text(authStatus == .authorized
                    ? "You'll receive updates about rewards and new partners."
                    : "Enable notifications to get reward updates and cycling reminders.")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 18))
                    Text("Open Sykle Settings")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(sykleBlue)
                .cornerRadius(30)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .navigationTitle("Push notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    authStatus = settings.authorizationStatus
                }
            }
        }
    }
}
// MARK: - Health Integrations

struct HealthIntegrationsView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image("HealthIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)

            VStack(spacing: 8) {
                Text("Apple Health")
                    .font(.system(size: 22, weight: .bold))
                Text("Sykle reads your cycling workouts to calculate reward points. We only access ride distance, duration, and timestamps.")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "figure.outdoor.cycle")
                        .foregroundColor(sykleBlue)
                        .frame(width: 32)
                    Text("Cycling workouts")
                        .font(.system(size: 15))
                    Spacer()
                    Image(systemName: healthKitManager.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(healthKitManager.isAuthorized ? .green : .red)
                }
                .padding(16)

                Divider().padding(.leading, 48)

                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(sykleBlue)
                        .frame(width: 32)
                    Text("Ride distance")
                        .font(.system(size: 15))
                    Spacer()
                    Image(systemName: healthKitManager.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(healthKitManager.isAuthorized ? .green : .red)
                }
                .padding(16)

                Divider().padding(.leading, 48)

                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(sykleBlue)
                        .frame(width: 32)
                    Text("Active energy")
                        .font(.system(size: 15))
                    Spacer()
                    Image(systemName: healthKitManager.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(healthKitManager.isAuthorized ? .green : .red)
                }
                .padding(16)
            }
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal, 20)

            Spacer()

            VStack(spacing: 12) {
                Button(action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 18))
                        Text("Open Sykle Settings")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(sykleBlue)
                    .cornerRadius(30)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .navigationTitle("Health integrations")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Profile Row

struct ProfileRow: View {
    let title: String
    let destination: AnyView

    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.black)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.image = image }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Stats Section

struct StatsSection: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @StateObject private var userManager = UserManager.shared
    let currentPoints: Int
    let pointsToNextReward: Int
    
    let sykleBlue = Color.sykleMid
    let sykleNavy = Color.sykleNavy
    let cardBlue = Color.sykleLight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your stats")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 20)

            HStack(alignment: .top, spacing: 10) {
                // LEFT column
                leftColumn
                // RIGHT column
                rightColumn
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var leftColumn: some View {
        VStack(spacing: 10) {
            // CO₂ card
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardBlue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(formatCO2(userManager.serverCO2SavedG))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    HStack(spacing: 4) {
                        Text("CO₂ saved")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.9))
                        Image("leaf")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                    }
                }
                .padding(14)
            }
            .frame(height: 140)

            // Navy reward card
            VStack(alignment: .leading, spacing: 6) {
                if pointsToNextReward == 0 {
                    Text("you can")
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                    Text("redeem a\nreward now!")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("you're")
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                    HStack(spacing: 5) {
                        Image("SykleLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                        Text("\(pointsToNextReward) sykles")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
                    Text("away from\nyour next\nreward")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(sykleNavy)
            .cornerRadius(16)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var rightColumn: some View {
        VStack(spacing: 10) {
            // Last sync
            VStack(alignment: .leading, spacing: 4) {
                Text("Last sync")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                Text("+\(userManager.lastSyncPoints)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
                HStack(spacing: 4) {
                    Image("SykleLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                    Text("sykles")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(14)

            // Distance
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", userManager.serverDistanceKm))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
                Text("km")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(14)

            // Minutes
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(userManager.serverMinutes)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.black)
                Text("mins")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                Spacer()
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(14)

            // Sync now
            Button(action: {
                Task {
                    await MainActor.run { healthKitManager.refresh() }
                    // Poll until workouts are loaded
                    for _ in 0..<10 {
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        if !healthKitManager.allWorkouts.isEmpty {
                            break
                        }
                    }
                    print("🔄 Syncing \(healthKitManager.allWorkouts.count) workouts")
                    await UserManager.shared.syncRides(workouts: healthKitManager.allWorkouts)
                    await UserManager.shared.refreshUser()
                }
            }) {
                HStack {
                    Spacer()
                    if healthKitManager.isLoading || UserManager.shared.isSyncing {
                        ProgressView().tint(sykleBlue)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(sykleBlue)
                        Text("Sync now")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(sykleBlue)
                    }
                    Spacer()
                }
                .padding(.vertical, 10)
                .background(sykleBlue.opacity(0.1))
                .cornerRadius(14)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    func formatCO2(_ grams: Double) -> String {
        if grams >= 1000 { return String(format: "%.1fkg", grams / 1000) }
        return String(format: "%.0fg", grams)
    }
}

// MARK: - Become a Partner Form

struct BecomePartnerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var businessName = ""
    @State private var contactName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var location = ""
    @State private var category = "Coffee"
    @State private var message = ""
    @State private var submitted = false

    let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)
    let categories = ["Coffee", "Bakery", "Juice Bar", "Other"]

    var isValid: Bool {
        !businessName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !contactName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationView {
            ScrollView {
                if submitted {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.green)
                        Text("We'll be in touch!")
                            .font(.system(size: 22, weight: .bold))
                        Text("Thanks for your interest, \(contactName). Our team will reach out to \(email) within 3–5 business days.")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Join Sykle's network of independent partners and get discovered by local cyclists.")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        FormSection(title: "About your business") {
                            FormField(label: "Business name", placeholder: "e.g. Bean & Gone", text: $businessName)
                            Divider().padding(.leading, 16)
                            FormField(label: "Location", placeholder: "e.g. Hackney, London", text: $location)
                            Divider().padding(.leading, 16)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Category")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 12)
                                Picker("Category", selection: $category) {
                                    ForEach(categories, id: \.self) { Text($0) }
                                }
                                .pickerStyle(.segmented)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 12)
                            }
                        }

                        FormSection(title: "Contact details") {
                            FormField(label: "Your name", placeholder: "e.g. Jamie Smith", text: $contactName)
                            Divider().padding(.leading, 16)
                            FormField(label: "Email", placeholder: "your@email.com", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                            Divider().padding(.leading, 16)
                            FormField(label: "Phone (optional)", placeholder: "+44 7700 000000", text: $phone)
                                .keyboardType(.phonePad)
                        }

                        FormSection(title: "Anything else?") {
                            ZStack(alignment: .topLeading) {
                                if message.isEmpty {
                                    Text("Tell us a bit about your business and why you'd like to join Sykle...")
                                        .font(.system(size: 15))
                                        .foregroundColor(.gray.opacity(0.6))
                                        .padding(.horizontal, 16)
                                        .padding(.top, 14)
                                }
                                TextEditor(text: $message)
                                    .font(.system(size: 15))
                                    .frame(minHeight: 100)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .scrollContentBackground(.hidden)
                            }
                        }

                        Button(action: {
                            withAnimation { submitted = true }
                        }) {
                            Text("Submit application")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(isValid ? sykleBlue : Color.gray)
                                .cornerRadius(30)
                        }
                        .disabled(!isValid)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Become a partner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Reusable Form Components

struct FormSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.gray)
                .textCase(.uppercase)
                .padding(.horizontal, 20)
            VStack(spacing: 0) { content }
                .background(Color.white)
                .cornerRadius(16)
                .padding(.horizontal, 20)
        }
    }
}

struct FormField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .padding(.top, 12)
                .padding(.horizontal, 16)
            TextField(placeholder, text: $text)
                .font(.system(size: 15))
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }
    }
}

// MARK: - Suggest a Partner Form

struct SuggestPartnerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var businessName = ""
    @State private var location = ""
    @State private var category = "Coffee"
    @State private var yourName = ""
    @State private var message = ""
    @State private var submitted = false

    let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)
    let categories = ["Coffee", "Bakery", "Juice Bar", "Other"]

    var isValid: Bool {
        !businessName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !location.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationView {
            ScrollView {
                if submitted {
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.green)
                        Text("Thanks for the suggestion!")
                            .font(.system(size: 22, weight: .bold))
                        Text("We'll reach out to \(businessName) and see if they'd like to join Sykle's partner network.")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Know a great local business that should be on Sykle? Let us know and we'll reach out to them.")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        FormSection(title: "About the business") {
                            FormField(label: "Business name", placeholder: "e.g. Bean & Gone", text: $businessName)
                            Divider().padding(.leading, 16)
                            FormField(label: "Location", placeholder: "e.g. Hackney, London", text: $location)
                            Divider().padding(.leading, 16)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Category")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 12)
                                Picker("Category", selection: $category) {
                                    ForEach(categories, id: \.self) { Text($0) }
                                }
                                .pickerStyle(.segmented)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 12)
                            }
                        }

                        FormSection(title: "Your details (optional)") {
                            FormField(label: "Your name", placeholder: "e.g. Jamie Smith", text: $yourName)
                        }

                        FormSection(title: "Why do you recommend them?") {
                            ZStack(alignment: .topLeading) {
                                if message.isEmpty {
                                    Text("Tell us why you think they'd be a great partner...")
                                        .font(.system(size: 15))
                                        .foregroundColor(.gray.opacity(0.6))
                                        .padding(.horizontal, 16)
                                        .padding(.top, 14)
                                }
                                TextEditor(text: $message)
                                    .font(.system(size: 15))
                                    .frame(minHeight: 100)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .scrollContentBackground(.hidden)
                            }
                        }

                        Button(action: {
                            withAnimation { submitted = true }
                        }) {
                            Text("Submit suggestion")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(isValid ? sykleBlue : Color.gray)
                                .cornerRadius(30)
                        }
                        .disabled(!isValid)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Suggest a partner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Rate and Review

struct RateAndReviewView: View {
    let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "star.fill")
                .font(.system(size: 70))
                .foregroundColor(.yellow)
            VStack(spacing: 8) {
                Text("Enjoying Sykle?")
                    .font(.system(size: 22, weight: .bold))
                Text("Your review helps other cyclists discover the app and supports our mission to make cycling more rewarding.")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Spacer()
            Button(action: {
                // Replace with your actual App Store ID when published
                if let url = URL(string: "https://apps.apple.com/app/idYOUR_APP_ID") {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Rate on the App Store")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(sykleBlue)
                    .cornerRadius(30)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .navigationTitle("Rate and review")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - FAQs

struct FAQsView: View {
    let faqs: [(String, String)] = [
        ("How do I earn sykles?",
         "Sykles are earned automatically every time you complete a cycling workout. Sykle reads your rides from Apple Health and calculates points based on distance and duration — 100 sykles per km and 10 sykles per minute cycled."),
        ("How do I redeem a reward?",
         "Browse partner cafés and bakeries on the Map or Home screen, tap a partner to see their available rewards, add one to your basket, and swipe to generate a voucher. Show the QR code to staff at the counter."),
        ("How long is a voucher valid for?",
         "Vouchers are valid until the partner closes on the day you redeem them. You can only generate a voucher during a partner's opening hours, so make sure you're at the location before swiping."),
        ("Why aren't my rides syncing?",
         "Make sure Sykle has access to your Health data. Go to Profile → Health integrations to check. If permissions look correct, tap 'Sync now' on your profile page to manually trigger a sync."),
        ("Can I use sykles at any café?",
         "Sykles can only be redeemed at partner businesses listed in the app. We're growing our partner network — if you know a great local café or bakery, use 'Suggest a partner' to nominate them."),
        ("Do my sykles expire?",
         "No — your sykles never expire. They stay in your account until you choose to redeem them."),
        ("Is my health data shared with anyone?",
         "No. Sykle only reads your cycling workout data to calculate points. This data is never sold or shared with third parties. You can revoke access at any time via iPhone Settings → Health → Sykle."),
        ("Can I use Sykle without Apple Health?",
         "Currently Sykle relies on Apple Health to verify cycling activity. This ensures that points are based on real, recorded rides rather than self-reported data."),
        ("What counts as a cycling workout?",
         "Any workout recorded as 'Cycling' in Apple Health counts — whether logged manually, tracked by an Apple Watch, or recorded by a third-party app like Strava or Komoot."),
        ("How do I delete my account?",
         "You can delete your account from Profile → Delete account. This permanently removes your data from our servers. This action cannot be undone."),
    ]

    @State private var expanded: Set<Int> = []

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 1) {
                ForEach(Array(faqs.enumerated()), id: \.offset) { index, faq in
                    VStack(alignment: .leading, spacing: 0) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if expanded.contains(index) {
                                    expanded.remove(index)
                                } else {
                                    expanded.insert(index)
                                }
                            }
                        }) {
                            HStack {
                                Text(faq.0)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image(systemName: expanded.contains(index) ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }

                        if expanded.contains(index) {
                            Text(faq.1)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 14)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        if index < faqs.count - 1 {
                            Divider().padding(.leading, 16)
                        }
                    }
                    .background(Color.white)
                }
            }
            .cornerRadius(16)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("FAQs")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Terms and Conditions

struct TermsAndConditionsView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Last updated: April 2026")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)

                LegalSection(title: "1. Acceptance of Terms", content: "By downloading or using Sykle, you agree to be bound by these Terms and Conditions. If you do not agree, please do not use the app.")
                
                LegalSection(title: "2. Eligibility", content: "Sykle is intended for users aged 13 and over. By using the app, you confirm that you meet this requirement.")
                
                LegalSection(title: "3. Your Account", content: "You are responsible for maintaining the confidentiality of your account credentials. You agree to notify us immediately of any unauthorised use of your account. Sykle is not liable for any loss resulting from unauthorised access to your account.")
                
                LegalSection(title: "4. Earning Sykles", content: "Sykles are awarded based on verified cycling activity data retrieved from Apple Health. Points are calculated using our standard formula: 100 sykles per kilometre plus 10 sykles per minute. Sykle reserves the right to adjust the points formula at any time with reasonable notice.")
                
                LegalSection(title: "5. Redeeming Rewards", content: "Rewards can only be redeemed at participating partner businesses listed in the app. Vouchers are valid until the partner closes on the day of redemption and can only be generated during opening hours. Sykle is not responsible for a partner business refusing or being unable to honour a reward.")
                
                LegalSection(title: "6. Partner Businesses", content: "Partner businesses are independent third parties. Sykle does not guarantee the quality, availability, or continued participation of any partner. Partners may be added or removed from the platform at any time.")
                
                LegalSection(title: "7. Prohibited Use", content: "You must not attempt to manipulate or falsify cycling data, exploit bugs or vulnerabilities, use automated tools to earn points, or engage in any conduct that undermines the integrity of the platform.")
                
                LegalSection(title: "8. Termination", content: "Sykle reserves the right to suspend or terminate your account if you violate these terms. Upon termination, any unredeemed sykles will be forfeited.")
                
                LegalSection(title: "9. Limitation of Liability", content: "Sykle is provided on an 'as is' basis. We are not liable for any indirect or consequential loss arising from your use of the app, including loss of sykles or inability to redeem rewards.")
                
                LegalSection(title: "10. Changes to Terms", content: "We may update these terms from time to time. Continued use of the app after changes constitutes acceptance of the revised terms.")
                
                LegalSection(title: "11. Contact", content: "For questions about these terms, contact us at legal@sykle.app.")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 32)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Terms and conditions")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Privacy Policy

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("Last updated: April 2026")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)

                LegalSection(title: "1. Introduction", content: "Sykle ('we', 'our', 'us') is committed to protecting your privacy. This policy explains what data we collect, how we use it, and your rights in relation to it.")
                
                LegalSection(title: "2. Data We Collect", content: "We collect your email address when you register. We read cycling workout data from Apple Health, including ride distance, duration, and timestamps. We store your points balance and redemption history on our servers. We do not collect your name unless you choose to provide it.")
                
                LegalSection(title: "3. How We Use Your Data", content: "Your data is used to calculate and display your sykles balance, to process reward redemptions, to show your cycling stats and CO₂ savings, and to improve the app experience. We do not use your data for advertising or sell it to third parties.")
                
                LegalSection(title: "4. Apple Health Data", content: "Sykle accesses cycling workout data from Apple Health solely to calculate reward points. This data is transmitted securely to our backend and is never shared with partner businesses or third parties. You can revoke Health access at any time via iPhone Settings → Health → Data Access & Devices → Sykle.")
                
                LegalSection(title: "5. Data Storage", content: "Your data is stored on secure servers. We retain your account data for as long as your account is active. If you delete your account, all personal data is permanently removed within 30 days.")
                
                LegalSection(title: "6. Data Sharing", content: "We do not sell, trade, or rent your personal data. We may share anonymised, aggregated cycling statistics with partners for research purposes. No personally identifiable information is included in any shared data.")
                
                LegalSection(title: "7. Your Rights", content: "You have the right to access the data we hold about you, request correction of inaccurate data, request deletion of your account and data, and withdraw consent for Health data access at any time. To exercise these rights, contact us at privacy@sykle.app.")
                
                LegalSection(title: "8. Cookies", content: "The Sykle app does not use cookies. Our backend may use session tokens to maintain your login state securely.")
                
                LegalSection(title: "9. Children's Privacy", content: "Sykle is not directed at children under 13. We do not knowingly collect data from users under this age.")
                
                LegalSection(title: "10. Changes to This Policy", content: "We may update this privacy policy periodically. We will notify you of significant changes via the app. Continued use after changes constitutes acceptance.")
                
                LegalSection(title: "11. Contact", content: "For privacy-related queries, contact us at privacy@sykle.app.")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 32)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Privacy policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Legal Section Helper

struct LegalSection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.black)
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(HealthKitManager())
}
