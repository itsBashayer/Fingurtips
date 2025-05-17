

import SwiftUI
import CloudKit
import LocalAuthentication

struct PainView: View {
    let categoryID: CKRecord.ID
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @EnvironmentObject var voiceRecorderManager: VoiceRecorderManager
    @State private var authPassed = false //
    @State private var userCards: [UserCard] = []
    @State private var showAddListSheet = false
    @State private var isEditing = false
    @State private var selectedStaticCard: StaticCard? = nil // ↩️

    private let allStaticCards: [StaticCard] = [
        StaticCard(title: "بطني يعورني", imageName: "Pain", frameColor: .red1, strokeColor: .red1, iconName: "Pain Icon", imageTopPadding: 10, recordID: CKRecord.ID(recordName: "pain-belly"), categoryID: CategoryIDs.pain),
        StaticCard(title: "راسي يعورني", imageName: "Head", frameColor: .red1, strokeColor: .red1, iconName: "Pain Icon", imageTopPadding: 10, recordID: CKRecord.ID(recordName: "pain-head"), categoryID: CategoryIDs.pain),
        StaticCard(title: "أسناني تعورني", imageName: "Teeth", frameColor: .red1, strokeColor: .red1, iconName: "Pain Icon", imageTopPadding: 10, recordID: CKRecord.ID(recordName: "pain-teeth"), categoryID: CategoryIDs.pain),
        StaticCard(title: "رجلي تعورني", imageName: "Leg", frameColor: .red1, strokeColor: .red1, iconName: "Pain Icon", imageTopPadding: 10, recordID: CKRecord.ID(recordName: "pain-leg"), categoryID: CategoryIDs.pain),
        StaticCard(title: "يدي تعورني", imageName: "Hand", frameColor: .red1, strokeColor: .red1, iconName: "Pain Icon", imageTopPadding: 10, recordID: CKRecord.ID(recordName: "pain-hand"), categoryID: CategoryIDs.pain)
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
                let dynamicColor = UserDefaults.standard.string(forKey: "color-category-\(categoryID.recordName)").map(Color.init(hex:)) ?? .red1

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

                            Text("آلامي")
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
                                    PainCardView(
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
                                        PainUserCardView(card: card, isEditing: $isEditing, categoryColor: dynamicColor, cardWidth: cardWidth)
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

struct PainCardView: View {
    @Binding var card: StaticCard
    @Binding var isEditing: Bool
    var cardWidth: CGFloat = 160.0
    var onEditTap: () -> Void // ↩️
    @EnvironmentObject var voiceRecorderManager: VoiceRecorderManager

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topLeading) {
                card.frameColor
                    .frame(width: cardWidth * 0.9, height: cardWidth * 0.9)// 🌸
                    .cornerRadius(21.79)
                
                if let customImage = card.customImage {
                    Image(uiImage: customImage)
                        .resizable()
                        .frame(width: cardWidth * 0.9, height: cardWidth * 0.9)
                        .cornerRadius(21.79)

                } else {
                    Image(card.imageName)
                        .resizable()
                        .frame(width: cardWidth * 0.9, height: cardWidth * 0.9)
                        .cornerRadius(21.79)
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




struct PainUserCardView: View {
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
                    categoryColor
                        .frame(width: cardWidth * 0.9, height: cardWidth * 0.9) // 🌸
                        .cornerRadius(21.79)

                    if let uiImage = card.image {
                        Image(uiImage: uiImage)
                            .resizable()
                            .frame(width: cardWidth * 0.9, height: cardWidth * 0.9) // 🌸
                            .cornerRadius(21.79)
                    }

//                    Image("Pain Icon")
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

#Preview {
    PainView(categoryID: CategoryIDs.pain)
        .environmentObject(CloudKitManager())
        .environmentObject(VoiceRecorderManager())
}
