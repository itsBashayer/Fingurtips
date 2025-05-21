
//  ANAMIL
//
//  Created by BASHAER AZIZ on 29/10/1446 AH.
//


import SwiftUI

struct SplashScreen: View {
    @State private var rightImageOffset: CGFloat = UIScreen.main.bounds.width
    let targetOffset: CGFloat = 120

    @State private var isActive: Bool = false
    @State private var showTouchImage: Bool = false

    let animationDuration = 2.0
    let touchImageSize = CGSize(width: 60, height: 60)

    var body: some View {
        ZStack {
            Image("splashBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            ZStack {
                Image("leftImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 400.14, height: 500)
                    .offset(x: 0, y: 10)

                if showTouchImage {
                    Image("TouchImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: touchImageSize.width, height: touchImageSize.height)
                        .offset(x: targetOffset - 80, y: -90)
                        .transition(.opacity)
                        .animation(.easeIn, value: showTouchImage)
                }

                Image("rightImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 500)
                    .offset(x: rightImageOffset, y: 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: animationDuration)) {
                rightImageOffset = targetOffset
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                withAnimation {
                    showTouchImage = true
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + 2.0) {
                withAnimation {
                    isActive = true
                }
            }
        }
        .fullScreenCover(isPresented: $isActive) {
            ContentView()
        }
    }
}


#Preview {
    SplashScreen()
}
