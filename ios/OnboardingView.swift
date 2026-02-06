//
//  OnboardingView.swift
//  Sykle
//
//  Created by Sanuzia Jorge on 18/01/2026.
//

//
//  OnboardingView.swift
//  Sykle
//
//  Onboarding screen that requests HealthKit permission
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Logo and title
            VStack(spacing: 8) {
                Text("sykle.")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(Color("SykleBlue"))
                
                Text("rewarding every ride")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 60)
            
            // Health sync card
            VStack(spacing: 20) {
                // Heart icon
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.red)
                }
                
                Text("Sync with Apple Health")
                    .font(.system(size: 24, weight: .semibold))
                
                Text("Sykle needs access to your cycling workouts to calculate your points and rewards.")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                // What we access
                VStack(alignment: .leading, spacing: 12) {
                    PermissionRow(icon: "bicycle", text: "Cycling workouts")
                    PermissionRow(icon: "figure.walk", text: "Distance traveled")
                    PermissionRow(icon: "flame.fill", text: "Calories burned")
                }
                .padding(.vertical, 20)
                
                // Status message
                if !healthKitManager.authorizationStatus.isEmpty {
                    Text(healthKitManager.authorizationStatus)
                        .font(.system(size: 14))
                        .foregroundColor(healthKitManager.isAuthorized ? .green : .orange)
                }
                
                // Error message
                if let error = healthKitManager.errorMessage {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(30)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Connect button
            Button(action: {
                healthKitManager.requestAuthorization()
            }) {
                HStack {
                    Image(systemName: "heart.fill")
                    Text("Connect Apple Health")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color("SykleBlue"))
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}

// MARK: - Permission Row Component
struct PermissionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color("SykleBlue"))
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
    }
}

// MARK: - Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(HealthKitManager())
    }
}
