//
//  SplashView.swift
//  Sykle
//
//  Animated splash screen shown when app launches
//

import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var showMainApp = false
    
    // Use the SAME key as ContentView
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)
    
    var body: some View {
        Group {
            if showMainApp {
                ContentView()
            } else {
                // Splash screen
                ZStack {
                    Color.white
                        .ignoresSafeArea()
                    
                    VStack {
                        Spacer()
                        
                        Image("SykleLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 150, height: 150)
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                            .animation(
                                .linear(duration: 2)
                                .repeatForever(autoreverses: false),
                                value: isAnimating
                            )
                        
                        Spacer()
                            .frame(height: 20)
                        
                        Text("sykle.")
                            .font(.system(size: 100, weight: .bold))
                            .foregroundColor(sykleBlue)
                        
                        Spacer()
                    }
                }
                .onAppear {
                    isAnimating = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showMainApp = true
                            // ContentView decides whether to show
                            // WelcomeView or MainTabView based on
                            // hasCompletedOnboarding
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
