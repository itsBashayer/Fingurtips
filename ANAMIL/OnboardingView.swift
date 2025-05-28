import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @State private var navigateToContentView = false

    var body: some View {
        NavigationStack {
            ZStack {
                switch currentPage {
                case 0:
                    OnboardingPageView(
                        imageName: "onboarding 2",
                        showNext: true,
                        nextButtonText: NSLocalizedString("Get started with the steps!", comment: ""),
                        showSkip: true,
                        skipButtonText: NSLocalizedString("Skip", comment: ""),
                        currentPage: $currentPage
                    )
                case 1:
                    OnboardingPageView(
                        imageName: "onboarding3 ",
                        showNext: true,
                        nextButtonText: NSLocalizedString("Next Step", comment: ""),
                        showSkip: true,
                        skipButtonText: NSLocalizedString("Skip", comment: ""),
                        currentPage: $currentPage
                    )
                case 2:
                    OnboardingPageView(
                        imageName: "onboarding4",
                        showStart: true,
                        startButtonText: NSLocalizedString("Start Fingurtips!", comment: ""),
                        onStart: {
                            hasSeenOnboarding = true
                            navigateToContentView = true
                        },
                        currentPage: $currentPage
                    )
                default:
                    EmptyView()
                }

                NavigationLink(
                    destination: ContentView()
                        .navigationBarBackButtonHidden(true),
                    isActive: $navigateToContentView
                ) {
                    EmptyView()
                }
                .hidden()
            }
            .ignoresSafeArea()
        }
    }
}



struct OnboardingPageView: View {
    var imageName: String
    var showNext: Bool = false
    var nextButtonText: String = "Next"
    var showSkip: Bool = false
    var skipButtonText: String = "Skip"
    var showStart: Bool = false
    var startButtonText: String = "Start"
    var onStart: (() -> Void)? = nil
    @Binding var currentPage: Int

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()

                VStack {
                    Spacer()

                    VStack(spacing: 12) {
                        if showNext {
                            Button(nextButtonText) {
                                withAnimation {
                                    currentPage += 1
                                }
                            }
                            .frame(width: 314, height: 39.38)
                            .background(Color.blue22)
                            .font(.system(size: 20.74, weight: .bold))
                            .foregroundColor(.white)
                            .cornerRadius(39.12)
                        }

                        if showSkip {
                            Button(skipButtonText) {
                                withAnimation {
                                    currentPage = 2
                                }
                            }
                            .foregroundColor(.P_1)
                            .font(.system(size: 16, weight: .bold))
                        }

                        if showStart {
                            Button(startButtonText) {
                                onStart?()
                            }
                            .frame(width: 314, height: 39.38)
                            .background(Color.blue22)
                            .font(.system(size: 20.74, weight: .bold))
                            .foregroundColor(.white)
                            .cornerRadius(39.12)
                        }
                    }
                    .padding(.bottom, 30)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}



#Preview {
    OnboardingView()
}
