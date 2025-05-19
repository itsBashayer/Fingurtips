

import SwiftUI
import CloudKit
import LocalAuthentication
struct FeelingsView: View {
    let categoryID: CKRecord.ID
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @EnvironmentObject var voiceRecorderManager: VoiceRecorderManager
    @State private var authPassed = false
    @State private var userCards: [UserCard] = []
    @State private var showAddListSheet = false
    @State private var isEditing = false
    @State private var selectedStaticCard: StaticCard? = nil // ↩️

    enum CardIDs {
        static let happy = CKRecord.ID(recordName: "card-happy")
        static let angry = CKRecord.ID(recordName: "card-angry")
        static let scared = CKRecord.ID(recordName: "card-scared")
        static let surprised = CKRecord.ID(recordName: "card-surprised")
        static let crying = CKRecord.ID(recordName: "card-crying")
    }

    private let allStaticCards: [StaticCard] = [
        StaticCard(title: "أنا مبسوط", imageName: "Happy", frameColor: .purple1, strokeColor: .purple1, iconName: "Heart Icon", imageTopPadding: 10, recordID: CardIDs.happy, categoryID: CategoryIDs.feelings),
        StaticCard(title: "آنا زعلان", imageName: "Mad", frameColor: .purple1, strokeColor: .purple1, iconName: "Heart Icon", imageTopPadding: 10, recordID: CardIDs.angry, categoryID: CategoryIDs.feelings),
        StaticCard(title: "أنا خايف", imageName: "Scared", frameColor: .purple1, strokeColor: .purple1, iconName: "Heart Icon", imageTopPadding: 10, recordID: CardIDs.scared, categoryID: CategoryIDs.feelings),
        StaticCard(title: "أنا مستغرب", imageName: "Suprised", frameColor: .purple1, strokeColor: .purple1, iconName: "Heart Icon", imageTopPadding: 10, recordID: CardIDs.surprised, categoryID: CategoryIDs.feelings),
        StaticCard(title: "أنا ابكي", imageName: "Crying", frameColor: .purple1, strokeColor: .purple1, iconName: "Heart Icon", imageTopPadding: 10, recordID: CardIDs.crying, categoryID: CategoryIDs.feelings)
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
                let dynamicColor = Color(hex: savedColorHex)
                card.frameColor = dynamicColor
                card.strokeColor = dynamicColor
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
    
    // عدلت هذا كامل🩷
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let isPad = geo.size.width > 600
                let columns = [GridItem(.adaptive(minimum: isPad ? 220 : 160), spacing: 20)]
                let cardWidth = isPad ? 220.0 : 160.0
                let dynamicColor = UserDefaults.standard.string(forKey: "color-category-\(categoryID.recordName)").map(Color.init(hex:)) ?? .purple1

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .trailing, spacing: 16) {
                            HStack {
                                Spacer()
                                Button(action: {
                                    authenticateWithFaceID { success in
                                        if success {
                                            isEditing.toggle()
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

                            Text("مشاعري")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .trailing)

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
                            .hidden()

                            LazyVGrid(columns: columns, spacing: 28) {
                                ForEach(staticCards.indices, id: \.self) { index in
                                    FeelingCardView(
                                        card: .constant(staticCards[index]),
                                        isEditing: $isEditing,
                                        cardWidth: cardWidth,
                                        onEditTap: {
                                            selectedStaticCard = staticCards[index]
                                        }
                                    )
                                    .environmentObject(voiceRecorderManager)
                                }

                                ForEach(userCards) { card in
                                    if card.image != nil {
                                        FeelingUserCardView(card: card, isEditing: $isEditing, categoryColor: dynamicColor, cardWidth: cardWidth)
                                            .environmentObject(voiceRecorderManager)
                                            .environmentObject(cloudKitManager)
                                    }
                                }

                                Button(action: {
                                    authenticateWithFaceID { success in
                                        if success {
                                            authPassed = true
                                            showAddListSheet = true
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
                                    AddCardView(categoryColor: dynamicColor, categoryID: categoryID)
                                        .environmentObject(cloudKitManager)
                                }
                            }

                            Spacer(minLength: 100)
                        }
                        .padding()
                        .frame(minHeight: geo.size.height)
                    }
                    .background(
                        Image("Background")
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                    )
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

struct FeelingCardView: View {
    @Binding var card: StaticCard
    @Binding var isEditing: Bool
    var cardWidth: CGFloat = 160.0
    var onEditTap: () -> Void // ↩️
    @EnvironmentObject var voiceRecorderManager: VoiceRecorderManager

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topLeading) {
                card.frameColor.opacity(0.5) // New
                    .frame(width: cardWidth * 0.9, height: cardWidth * 0.9)// 🌸
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
                        .cornerRadius(21.79)
                }

                Image(card.iconName)
                    .resizable()
                    .renderingMode(.template) //New
                    .foregroundColor(card.frameColor) // new
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


struct FeelingUserCardView: View {
    let card: UserCard
    @Binding var isEditing: Bool
    var categoryColor: Color
    var cardWidth: CGFloat = 160.0

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
                    categoryColor.opacity(0.5) // new
                        .frame(width: cardWidth * 0.9, height: cardWidth * 0.9) // 🌸
                        .cornerRadius(21.79)

                    if let uiImage = card.image {
                        Image(uiImage: uiImage)
                            .resizable()
                            .frame(width: cardWidth * 0.9, height: cardWidth * 0.9) // 🌸
                            .cornerRadius(21.79)
                    }

//                    Image("Heart Icon")
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
