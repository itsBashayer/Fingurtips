
//  ANAMIL
//
//  Created by BASHAER AZIZ on 29/10/1446 AH.
//

import SwiftUI

struct SplashScreen: View {
    @State private var rightImageOffset: CGFloat = UIScreen.main.bounds.width
    let targetOffset: CGFloat = 120 // where the right image stops

    @State private var isActive: Bool = false
    @State private var showTouchImage: Bool = false // control the visibility of the TouchImage

    let animationDuration = 2.0
    let touchImageSize = CGSize(width: 60, height: 60) // set the size of TouchImage

    var body: some View {
        ZStack {
            Image("splashBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            if isActive {
                ContentView()
            } else {
                
                ZStack {
                    
                    // البطاقة في الخلف
                    Image("leftImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 400.14, height: 500)
                        .offset(x: 0, y: -100)

                    // TouchImage في المنتصف
                    if showTouchImage {
                        Image("TouchImage")
                            .resizable()
                            .scaledToFit()
                            .frame(width: touchImageSize.width, height: touchImageSize.height)
                            .offset(x: targetOffset - 55, y: -190)
                            .transition(.opacity)
                            .animation(.easeIn, value: showTouchImage)
                    }

                    // اليد في الأعلى
                    Image("rightImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 500)
                        .offset(x: rightImageOffset, y: -50)
                }

                .onAppear {
                    // حركة rightImage
                    withAnimation(.easeOut(duration: animationDuration)) {
                        rightImageOffset = targetOffset
                    }

                    // بعد التأخير المحدد، تظهر TouchImage
                    DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
                        withAnimation {
                            showTouchImage = true
                        }
                    }

                    // بعد انتهاء السبلاتش، الانتقال إلى الصفحة التالية
                    DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + 2.0) {
                        withAnimation {
                            isActive = true
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreen()
}
