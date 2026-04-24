//
//  OnboardingCarouselView.swift
//  Sykle
//
//  Carousel onboarding showing app features
//

import SwiftUI

struct OnboardingCarouselView: View {
    @State private var currentPage = 0
    @State private var showAuthSheet = false
    @State private var isAuthenticated = false
    @Binding var showOnboarding: Bool
    
    // Auto-scroll timer
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    // Brand colors
    let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)  // #5886B9
    let lightBlue = Color(red: 214/255, green: 232/255, blue: 248/255) // Light blue background
    let buttonBackground = Color(red: 245/255, green: 240/255, blue: 235/255) // Beige/cream
    
    let slides = [
        OnboardingSlide(
            imageName: "onboarding1",
            title: "Earn rewards for cycling"
        ),
        OnboardingSlide(
            imageName: "onboarding2",
            title: "Compete with friends for extra motivation"
        ),
        OnboardingSlide(
            imageName: "onboarding3",
            title: "Use your points to save on rewards"
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header - sykle. logo
            HStack {
                Text("sykle.")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(sykleBlue)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            Spacer()
            
            // Carousel
            TabView(selection: $currentPage) {
                ForEach(0..<slides.count, id: \.self) { index in
                    VStack {
                        Spacer()
                        Image(slides[index].imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(.horizontal, 24)
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<slides.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? sykleBlue : sykleBlue.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 20)
            
            Spacer()
            
            // Continue button
            Button(action: {
                if currentPage < slides.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    // Last page - show auth sheet
                    showAuthSheet = true
                }
            }) {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(sykleBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(buttonBackground)
                    .cornerRadius(30)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .background(Color.white)
        .sheet(isPresented: $showAuthSheet) {
            AuthSheet(isPresented: $showAuthSheet, isAuthenticated: $isAuthenticated)
                .presentationDetents([.height(350)])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: isAuthenticated) { authenticated in
            if authenticated {
                showOnboarding = false
            }
        }
        .onReceive(timer) { _ in
            withAnimation {
                currentPage = (currentPage + 1) % slides.count
            }
        }
    }
}

// MARK: - Slide Model

struct OnboardingSlide {
    let imageName: String
    let title: String
}

// MARK: - Preview

#Preview {
    OnboardingCarouselView(showOnboarding: .constant(true))
}
