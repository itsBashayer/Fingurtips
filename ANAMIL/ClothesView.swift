

import SwiftUI
import CloudKit
import LocalAuthentication
struct ClothesView: View {
    let categoryID: CKRecord.ID
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @EnvironmentObject var voiceRecorderManager: VoiceRecorderManager
    @State private var userCards: [UserCard] = []
    @State private var showAddListSheet = false
    @State private var authPassed = false
    @State private var isEditing = false
    @State private var selectedStaticCard: StaticCard? = nil // ↩️

    private let allStaticCards: [StaticCard] = [
        StaticCard(title: "بلوزة", imageName: "Cloth", frameColor: .green1, strokeColor: .green1, iconName: "Cloth Icon", imageTopPadding: 10, recordID: CKRecord.ID(recordName: "shirt"), categoryID: CategoryIDs.clothes),
        StaticCard(title: "بنطلون", imageName: "Pants", frameColor: .green1, strokeColor: .green1, iconName: "Cloth Icon", imageTopPadding: 10, recordID: CKRecord.ID(recordName: "pants"), categoryID: CategoryIDs.clothes),
        StaticCard(title: "جزمة", imageName: "Shoes", frameColor: .green1, strokeColor: .green1, iconName: "Cloth Icon", imageTopPadding: 10, recordID: CKRecord.ID(recordName: "shoes"), categoryID: CategoryIDs.clothes),
        StaticCard(title: "جاكيت", imageName: "Jacket", frameColor: .green1, strokeColor: .green1, iconName: "Cloth Icon", imageTopPadding: 20, recordID: CKRecord.ID(recordName: "jacket"), categoryID: CategoryIDs.clothes)
    ]

    var staticCards: [StaticCard] {
        allStaticCards.filter { $0.categoryID == categoryID }.map { originalCard in
            var card = originalCard
            let key = card.recordID.recordName

            if let savedTitle = UserDefaults.standard.string(forKey: "title-\(key)") {
                card.title = savedTitle
            }

            if let imagePath = UserDefaults.standard.string(forKey: "imagePath-\(key)"),
               let data = try? Data(contentsOf: URL(fileURLWithPath: imagePath)),
               let uiImage = UIImage(data: data) {
                card.customImage = uiImage
            }

            if let audioPath = UserDefaults.standard.string(forKey: "audioPath-\(key)") {
                card.audioURL = URL(fileURLWithPath: audioPath)
            }

            if let savedColorHex = UserDefaults.standard.string(forKey: "color-category-\(categoryID.recordName)") {
                let userColor = Color(hex: savedColorHex)
                card.frameColor = userColor
                card.strokeColor = userColor
            }

            return card
        }
    }
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
                                }
                                
                                ) {
                                    Text(isEditing ? "تم" : "تعديل")
                                        .frame(width: 63, height: 26.42)
                                        .font(.system(size: 14.85, weight: .bold))
                                        .foregroundColor(.darkBlue1)
                                        .background(Color.white)
                                        .cornerRadius(25.52)
                                }                            }
                            
                            .padding(.horizontal)
                            .padding(.top, geo.size.height > 800 ? 400 : 20)


                            VStack(alignment: .trailing, spacing: 8) {
                                Text("ملابسي")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.black)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)

                            // ↩️ التنقل الآمن إلى شاشة التعديل
                            NavigationLink(
                                destination: Group {
                                    if let card = selectedStaticCard {
                                        EditCardView(card: .constant(card))
                                    } else {
                                        EmptyView()
                                    }
                                },
                                isActive: Binding(
                                    get: { selectedStaticCard != nil },
                                    set: { if !$0 { selectedStaticCard = nil } }
                                )
                            ) {
                                EmptyView()
                            }
                            .hidden() // ↩️

                            LazyVGrid(columns: columns, spacing: 28) {
                                ForEach(staticCards.indices, id: \.self) { index in
                                    ClothesCardView(
                                        card: .constant(staticCards[index]),
                                        isEditing: $isEditing,
                                        cardWidth: cardWidth,
                                        onEditTap: {
                                            selectedStaticCard = staticCards[index] // ↩️
                                        }
                                    )
                                    .environmentObject(voiceRecorderManager)
                                }

                                let dynamicColor = UserDefaults.standard.string(forKey: "color-category-\(categoryID.recordName)").map(Color.init(hex:)) ?? .green1

                                ForEach(userCards) { card in
                                    if card.image != nil {
                                        ClothesUserCardView(card: card, isEditing: $isEditing, categoryColor: dynamicColor, cardWidth: cardWidth)
                                            .environmentObject(voiceRecorderManager)
                                            .environmentObject(cloudKitManager)
                                    }
                                }

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
                                }){
                                    CardButtonView(
                                        card: .constant(
                                            StaticCard(title: "إضافة كرت",
                                                       imageName: "Plus Sign",
                                                       frameColor: .blue1,
                                                       strokeColor: .blue1,
                                                       iconName: "Adding Icon",
                                                       imageTopPadding: 10,
                                                       recordID: CKRecord.ID(recordName: "new"),
                                                       categoryID: categoryID)
                                        ),
                                        isEditing: .constant(false),
                                        cardWidth: cardWidth
                                    )
                                }
                                .fullScreenCover(isPresented: $showAddListSheet) {
                                    AddCardView(categoryColor: dynamicColor, categoryID: categoryID)
                                        .environmentObject(cloudKitManager)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            cloudKitManager.fetchCards(for: categoryID) { cards in
                self.userCards = cards
            }
        }
    }
}


struct ClothesCardView: View {
    @Binding var card: StaticCard
    @Binding var isEditing: Bool
    var cardWidth: CGFloat
    var onEditTap: () -> Void // ↩️
    @EnvironmentObject var voiceRecorderManager: VoiceRecorderManager

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topLeading) {
                card.frameColor
                    .frame(width: cardWidth * 0.9, height: cardWidth * 0.9) // 🌸
                    .cornerRadius(21.79)

                if let customImage = card.customImage {
                    Image(uiImage: customImage)
                        .resizable()
                        .frame(width: cardWidth * 0.9, height: cardWidth * 0.9)// 🌸
                        .cornerRadius(21.79)
                } else {
                    Image(card.imageName)
                        .resizable()
                        .frame(width: cardWidth * 0.9, height: cardWidth * 0.9)// 🌸
                }

                Image(card.iconName)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .padding(14)

                if isEditing && card.title != "إضافة كرت" {
                    Button(action: onEditTap) { // ↩️
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 36, height: 36)

                            Image(systemName: "pencil")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                                .foregroundColor(.blue)
                        }
                        .padding(.leading, cardWidth - 54) // 🌸
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
                .stroke(card.strokeColor, lineWidth: 3.27)
        )
        .onTapGesture {
            if let url = card.audioURL {
                voiceRecorderManager.playExternalRecording(from: url)
            }
        }
    }
}




struct ClothesUserCardView: View {
    let card: UserCard
    @Binding var isEditing: Bool
    var categoryColor: Color
    var cardWidth: CGFloat

    @EnvironmentObject var voiceRecorderManager: VoiceRecorderManager
    @EnvironmentObject var cloudKitManager: CloudKitManager

    var body: some View {
        Button(action: {
            if let url = card.audioURL {
                voiceRecorderManager.playExternalRecording(from: url)
            }
        }) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) { // 🌸
                    categoryColor
                        .frame(width: cardWidth * 0.9, height: cardWidth * 0.9) // 🌸
                        .cornerRadius(21.79)

                    if let uiImage = card.image {
                        Image(uiImage: uiImage)
                            .resizable()
                            .frame(width: cardWidth * 0.9, height: cardWidth * 0.9) // 🌸
                            .cornerRadius(21.79)
                    }

//                    Image("Cloth Icon")
//                        .resizable()
//                        .frame(width: 20, height: 20)
//                        .padding(14)

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
                            .padding(.trailing, -5) // 🌸
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
