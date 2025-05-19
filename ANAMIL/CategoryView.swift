import SwiftUI
import CloudKit
import LocalAuthentication

struct CategoryView: View {
    @State private var showAddListSheet = false
    @State private var userCards: [UserCard] = []
    @StateObject private var cloudKitManager = CloudKitManager()
    @State private var isEditing = false
    @State private var authPassed = false
    @EnvironmentObject var voiceRecorderManager: VoiceRecorderManager

    let categoryID: CKRecord.ID
    var categoryColor: Color
    let categoryTitle: String

    //start Face ID authentication logic
        private func authenticateWithFaceID(completion: @escaping (Bool) -> Void) {
            let context = LAContext()
            var error: NSError?

            
            // ✅ This line allows Face ID with passcode fallback
            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                let reason = "الرجاء التحقق باستخدام Face ID أو كلمة المرور لإضافة قائمة جديدة"

                context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
                    DispatchQueue.main.async {
                        completion(success)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }//end
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let isPad = geo.size.width > 600
                let columns = [GridItem(.adaptive(minimum: isPad ? 220 : 160), spacing: 20)]
                let cardWidth = isPad ? 220.0 : 160.0

                ZStack {
                    Image("Background")
                        .resizable()
                        .scaledToFill()
                        .edgesIgnoringSafeArea(.all)

                    ScrollView {
                        VStack(alignment: .trailing, spacing: 16) {
                            HStack {
                                Spacer()
                                Button(action: {
                                    authenticateWithFaceID { success in
                                        if success {
                                            isEditing.toggle()
                                        } else {
                                            print("Authentication failed or canceled")
                                        }
                                    }
                                }) {
                                    Text(isEditing ? "تم" : "تعديل")
                                        .frame(width: 63, height: 26.42)
                                        .font(.system(size: 14.85, weight: .bold))
                                        .foregroundColor(.darkBlue1)
                                        .background(Color.white)
                                        .cornerRadius(25.52)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 40)

                            VStack(alignment: .trailing, spacing: 8) {
                                Text(categoryTitle)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.black)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)

                            LazyVGrid(columns: columns, spacing: 28) {
                                if userCards.isEmpty {
                                    addCardButton(cardWidth: cardWidth)
                                }

                                ForEach(userCards) { card in
                                    if let image = card.image {
                                        Button(action: {
                                            if let url = card.audioURL {
                                                voiceRecorderManager.playExternalRecording(from: url)
                                            }
                                        }) {
                                            VStack(alignment: .leading, spacing: 8) {
                                                ZStack(alignment: .topTrailing) {
                                                    categoryColor
                                                        .frame(width: cardWidth * 0.9, height: cardWidth * 0.9)
                                                        .cornerRadius(21.79)

                                                    Image(uiImage: image)
                                                        .resizable()
                                                        .frame(width: cardWidth * 0.9, height: cardWidth * 0.9)
                                                        .cornerRadius(21.79)

                                                    if isEditing {
                                                        NavigationLink(destination:
                                                            EditCardView(
                                                                categoryColor: categoryColor,
                                                                initialName: card.title,
                                                                initialImage: card.image,
                                                                recordID: card.id
                                                            ).environmentObject(cloudKitManager)) {
                                                            ZStack {
                                                                Circle()
                                                                    .fill(Color.blue.opacity(0.2))
                                                                    .frame(width: 36, height: 36)

                                                                Image(systemName: "pencil")
                                                                    .resizable()
                                                                    .scaledToFit()
                                                                    .frame(width: 16, height: 16)
                                                                    .foregroundColor(.blue)
                                                                    .padding(10)
                                                            }
                                                            .padding(.trailing, -5)
                                                        }
                                                    }
                                                }

                                                Text(card.title)
                                                    .font(.system(size: 21.78))
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.primary)
                                                    .multilineTextAlignment(.center)
                                                    .frame(maxWidth: .infinity, alignment: .center)
                                            }
                                            .padding()
                                            .frame(width: cardWidth, height: cardWidth * 1.5)
                                            .background(Color.white.opacity(0.8))
                                            .cornerRadius(21.78)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 21.78)
                                                    .stroke(categoryColor, lineWidth: 3.27)
                                            )
                                        }
                                    }
                                }

                                if !userCards.isEmpty {
                                    addCardButton(cardWidth: cardWidth)
                                }
                            }

                            Spacer(minLength: 100) //🩷
                        }
                        .padding()
                        .frame(minHeight: geo.size.height) //🩷
                    }

                }
            }
        }
        .onAppear {
            cloudKitManager.fetchCards(for: categoryID) { cards in
                self.userCards = cards
            }
        }
        //new
        .onChange(of: isEditing) { newValue in
                    if newValue == false {
                        print("🔄 رجعنا من التعديل، جاري تحديث الكروت...")
                        cloudKitManager.fetchCards(for: categoryID) { cards in
                            self.userCards = cards
                        }
                    }
                }
    }

    private func addCardButton(cardWidth: CGFloat) -> some View {
        Button(action: {
            authenticateWithFaceID { success in
                if success {
                    authPassed = true
                    showAddListSheet=true
                } else {
                    // Optional: Add error handling or alert
                    print("Authentication failed or canceled")
                }
            }
        }) {
            CardButtonView(
                card: .constant(
                    StaticCard(
                        title: "إضافة كرت",
                        imageName: "Plus Sign",
                        frameColor: .blue1,
                        strokeColor: .blue1,
                        iconName: "Adding Icon",
                        imageTopPadding: 10,
                        recordID: CKRecord.ID(recordName: "new"),
                        categoryID: categoryID
                    )
                ),
                isEditing: .constant(false),
                cardWidth: cardWidth
            )
        }
        .fullScreenCover(isPresented: $showAddListSheet) {
            AddCardView(categoryColor: categoryColor, categoryID: categoryID)
                .environmentObject(cloudKitManager)
        }
    }
}





#Preview {
    CategoryView(
        categoryID: CKRecord.ID(recordName: "MockCategoryID"),
        categoryColor: .blue,
        categoryTitle: "الملابس"
    )
    .environmentObject(CloudKitManager())
    .environmentObject(VoiceRecorderManager())
}
