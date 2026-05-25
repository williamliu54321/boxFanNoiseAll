import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var page = 0

    private let pages: [OnboardingPage] = [
        .init(
            icon: "fanblades.fill",
            title: "Sleep deeper with\nbox fan sounds",
            subtitle: "Pure white noise to mask distractions\nand drift off in minutes."
        ),
        .init(
            icon: "moon.zzz.fill",
            title: "Set it and\ndrift off",
            subtitle: "Pick a sound, set a sleep timer,\nand let your phone do the rest."
        ),
        .init(
            icon: "chart.line.uptrend.xyaxis",
            title: "Build your\nbedtime streak",
            subtitle: "Track your nightly listening and\nturn good sleep into a habit."
        )
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.08, blue: 0.16),
                         Color(red: 0.10, green: 0.12, blue: 0.22)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, p in
                        OnboardingPageView(page: p).tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageIndicators
                    .padding(.bottom, 24)

                Button {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        UserDefaults.standard.set(true, forKey: OnboardingView.seenKey)
                        onFinish()
                    }
                } label: {
                    Text(page == pages.count - 1 ? "Get Started" : "Continue")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Capsule().fill(Color.white))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                Button {
                    UserDefaults.standard.set(true, forKey: OnboardingView.seenKey)
                    onFinish()
                } label: {
                    Text("Skip")
                        .font(.system(.footnote, design: .rounded, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.bottom, 32)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var pageIndicators: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Color.white : Color.white.opacity(0.25))
                    .frame(width: i == page ? 28 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: page)
            }
        }
    }

    static let seenKey = "hasSeenOnboarding"
    static var hasSeen: Bool { UserDefaults.standard.bool(forKey: seenKey) }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.white.opacity(0.12), Color.white.opacity(0.04)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 200, height: 200)
                Image(systemName: page.icon)
                    .font(.system(size: 88, weight: .light))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 14) {
                Text(page.title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.system(size: 17, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
        .padding(.top, 40)
    }
}

#Preview {
    OnboardingView { }
}
