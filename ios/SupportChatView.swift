//
//  SupportChatView.swift
//  Sykle
//

import SwiftUI

struct SupportMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp = Date()
}

struct SupportChatView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var userManager = UserManager.shared
    @State private var messages: [SupportMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false

    let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)
    let cardBlue = Color(red: 173/255, green: 210/255, blue: 235/255)

    let systemPrompt = """
    You are Sykle's friendly customer support assistant. Sykle is a cycling rewards app for London that converts verified cycling workouts from Apple Health into redeemable points (called "sykles") at independent local cafés and bakeries.

    Key facts about Sykle:
    - Points formula: 100 sykles per km + 10 sykles per minute cycled
    - CO₂ saved calculated at 150g per km vs driving
    - 22 partner businesses across London including coffee shops and bakeries
    - Vouchers are valid until the partner closes on the day of redemption
    - Sykles never expire
    - Only recognised email providers are accepted (Gmail, Outlook, iCloud etc.)
    - Passwords require 8+ characters, 1 uppercase, 1 number
    - HealthKit is required to verify cycling activity
    - Any cycling workout in Apple Health counts — Apple Watch, Strava, Komoot etc.
    - The merchant dashboard for QR verification is coming soon
    - Partners include: OA Coffee, Lannan, Cremerie, Dayz, Sede, Honu, Latte Club, Cado Cado, Browneria, Aleph, Petibon, Fufu, Varmuteo, Tio, Makeroom, Neulo, La Joconde, Been Bakery, Rosemund Bakery, Signorelli Pasticceria, Tamed Fox, Fifth Sip

    Be helpful, friendly and concise. If you don't know something specific, say so honestly. Keep responses short — this is a mobile chat interface. Never make up information about specific reward prices or partner details you're not sure about.
    """

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            // Welcome message
                            if messages.isEmpty {
                                WelcomeCard(sykleBlue: sykleBlue, cardBlue: cardBlue)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 16)
                            }

                            ForEach(messages) { message in
                                ChatBubble(message: message, sykleBlue: sykleBlue, cardBlue: cardBlue)
                                    .padding(.horizontal, 20)
                                    .id(message.id)
                            }

                            if isLoading {
                                TypingIndicator(cardBlue: cardBlue)
                                    .padding(.horizontal, 20)
                                    .id("typing")
                            }
                        }
                        .padding(.bottom, 16)
                    }
                    .onChange(of: messages.count) { _ in
                        if let last = messages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: isLoading) { loading in
                        if loading {
                            withAnimation {
                                proxy.scrollTo("typing", anchor: .bottom)
                            }
                        }
                    }
                }

                // Suggested questions
                if messages.isEmpty {
                    SuggestedQuestions(onTap: { question in
                        inputText = question
                        sendMessage()
                    })
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }

                Divider()

                // Input bar
                HStack(spacing: 12) {
                    TextField("Ask anything about Sykle...", text: $inputText, axis: .vertical)
                        .lineLimit(1...4)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(20)

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : sykleBlue)
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Customer support")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                        .fixedSize()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                    }
                }
            }
        }
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        inputText = ""
        messages.append(SupportMessage(content: text, isUser: true))
        isLoading = true

        Task {
            do {
                let reply = try await callClaudeAPI(userMessage: text)
                await MainActor.run {
                    messages.append(SupportMessage(content: reply, isUser: false))
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    messages.append(SupportMessage(content: "Sorry, I'm having trouble connecting right now. Please try again in a moment.", isUser: false))
                    isLoading = false
                }
            }
        }
    }

    private func callClaudeAPI(userMessage: String) async throws -> String {
        guard let url = URL(string: "\(Config.apiBaseURL)/support/chat") else {
            throw URLError(.badURL)
        }

        var apiMessages: [[String: String]] = []
        for message in messages {
            apiMessages.append([
                "role": message.isUser ? "user" : "assistant",
                "content": message.content
            ])
        }
        apiMessages.append(["role": "user", "content": userMessage])

        let body: [String: Any] = ["messages": apiMessages]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)

        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let reply = json["reply"] as? String {
            return reply
        }

        throw URLError(.cannotParseResponse)
    }
}

// MARK: - Welcome Card

struct WelcomeCard: View {
    let sykleBlue: Color
    let cardBlue: Color

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(cardBlue)
                    .frame(width: 60, height: 60)
                Image(systemName: "headphones")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            Text("Hi, I'm Sykle Support 👋")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.black)
            Text("Ask me anything about earning sykles, redeeming rewards, or how the app works.")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Suggested Questions

struct SuggestedQuestions: View {
    let onTap: (String) -> Void
    let sykleBlue = Color(red: 88/255, green: 134/255, blue: 185/255)

    let questions = [
        "How do I earn sykles?",
        "How do I redeem a reward?",
        "Why aren't my rides syncing?",
        "Do my sykles expire?"
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(questions, id: \.self) { question in
                    Button(action: { onTap(question) }) {
                        Text(question)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(sykleBlue)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(sykleBlue.opacity(0.1))
                            .cornerRadius(20)
                    }
                }
            }
        }
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: SupportMessage
    let sykleBlue: Color
    let cardBlue: Color

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser { Spacer(minLength: 60) }

            if !message.isUser {
                ZStack {
                    Circle()
                        .fill(cardBlue)
                        .frame(width: 28, height: 28)
                    Image(systemName: "headphones")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
            }

            Text(message.content)
                .font(.system(size: 15))
                .foregroundColor(message.isUser ? .white : .black)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(message.isUser ? sykleBlue : Color.white)
                .cornerRadius(18)
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)

            if !message.isUser { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    let cardBlue: Color
    @State private var animate = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle()
                    .fill(cardBlue)
                    .frame(width: 28, height: 28)
                Image(systemName: "headphones")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }

            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 7, height: 7)
                        .offset(y: animate ? -4 : 0)
                        .animation(
                            .easeInOut(duration: 0.4)
                            .repeatForever()
                            .delay(Double(index) * 0.15),
                            value: animate
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(18)

            Spacer(minLength: 60)
        }
        .onAppear { animate = true }
    }
}

#Preview {
    SupportChatView()
}
