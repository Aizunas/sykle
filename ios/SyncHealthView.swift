//
//  SyncHealthView.swift
//  Sykle
//

import SwiftUI
import HealthKit

struct SyncHealthView: View {
    let onComplete: () -> Void
    @EnvironmentObject var healthKitManager: HealthKitManager

    @State private var isLoading = false
    @State private var showNotifications = false

    let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onComplete) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.black)
            }
            .padding(.top, 16)

            Text("sykle.")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(sykleBlue)
                .padding(.top, 16)

            Image("HealthIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .padding(.top, 24)

            Text("Automatically sync your cycling activity using Apple Health.")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)
                .padding(.top, 24)

            Text("Sykle only requests access to verified cycling activity data, including:")
                .font(.system(size: 16))
                .foregroundColor(.black)
                .padding(.top, 12)

            HStack(spacing: 8) {
                RoundedTag(text: "ride distance")
                RoundedTag(text: "ride duration")
                RoundedTag(text: "activity timestamps")
            }
            .padding(.top, 16)

            Spacer()

            Button(action: syncHealthData) {
                HStack {
                    Spacer()
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sync Health Data")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.vertical, 16)
                .background(sykleBlue)
                .cornerRadius(30)
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
        .background(Color.white)
        .fullScreenCover(isPresented: $showNotifications) {
            NotificationsPermissionView(onComplete: onComplete)
        }
    }

    private func syncHealthData() {
        isLoading = true

        let healthStore = HKHealthStore()
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKObjectType.quantityType(forIdentifier: .distanceCycling)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                self.isLoading = false
                self.healthKitManager.isAuthorized = true
                self.healthKitManager.fetchCyclingWorkouts()
                self.showNotifications = true
            }
        }
    }
}

// MARK: - Rounded Tag

struct RoundedTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.black)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black, lineWidth: 1)
            )
    }
}
