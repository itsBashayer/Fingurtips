import SwiftUI
import CloudKit
//import LocalAuthentication

struct GamesView: View {
    let categoryID: CKRecord.ID
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @EnvironmentObject var voiceRecorderManager: VoiceRecorderManager
    @State private var authPassed = false
    @State private var userCards: [UserCard] = []
    @State private var showAddListSheet = false
    @State private var isEditing = false
    @State private var selectedStaticCard: StaticCard? = nil // ↩️

    private let allStaticCards: [StaticCard] = [
        StaticCard(title: NSLocalizedString("Games", comment: "Games category - general"),
                   imageName: "Games1", frameColor: .lavender, strokeColor: .lavender,
                   iconName: "Game Icon", imageTopPadding: 20,
                   recordID: CKRecord.ID(recordName: "card-games"), categoryID: CategoryIDs.games),

        StaticCard(title: NSLocalizedString("Doll", comment: "Games category - doll"),
                   imageName: "Dall", frameColor: .lavender, strokeColor: .lavender,
                   iconName: "Game Icon", imageTopPadding: 20,
                   recordID: CKRecord.ID(recordName: "card-doll"), categoryID: CategoryIDs.games),

        StaticCard(title: NSLocalizedString("Ball", comment: "Games category - ball"),
                   imageName: "Ball", frameColor: .lavender, strokeColor: .lavender,
                   iconName: "Game Icon", imageTopPadding: 20,
                   recordID: CKRecord.ID(recordName: "card-ball"), categoryID: CategoryIDs.games)
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

  
    
    // Modified this entire section 🩷
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let isPad = geo.size.width > 600
                let columns = [GridItem(.adaptive(minimum: isPad ? 220 : 160), spacing: 20)]
                let cardWidth = isPad ? 220.0 : 160.0
                let dynamicColor = UserDefaults.standard.string(forKey: "color-category-\(categoryID.recordName)").map(Color.init(hex:)) ?? .lavender

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) { // changed to .leading
                            HStack {
                                Spacer()
                                Button(action: {
                                                                   isEditing.toggle()
                                                               }) {
                                                                   Text(isEditing ? "Done" : "Edit")
                                                                       .frame(width: 63, height: 26.42)
                                                                       .font(.system(size: 14.85, weight: .bold))
                                                                       .foregroundColor(.darkBlue1)
                                                                       .background(Color.white)
                                                                       .cornerRadius(25.52)
                                                               }
                                                           }
                               // Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 40)

                            Text("My Games")
                                .font(.system(size: 24, weight: .bold))
                                //.foregroundColor(.black)
                                .foregroundColor(Color("PrimaryTextColor"))
                                .frame(maxWidth: .infinity, alignment: .leading) // changed to .leading

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
                                    GameCardView(
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
                                        GameUserCardView(card: card, isEditing: $isEditing, categoryColor: dynamicColor, cardWidth: cardWidth)
                                            .environmentObject(voiceRecorderManager)
                                            .environmentObject(cloudKitManager)
                                    }
                                }

                                Button(action: {
                                                        showAddListSheet = true
                                                    }) {
                                                        CardButtonView(
                                                            card: .constant(
                                                                StaticCard(
                                                                    title: NSLocalizedString("Add Card", comment: "Title for the button to add a new card"),
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
        
        .onAppear {
            cloudKitManager.fetchCards(for: categoryID) { cards in
                self.userCards = cards
            }
        }
    }

}


struct GameCardView: View {
    @Binding var card: StaticCard
    @Binding var isEditing: Bool
    var cardWidth: CGFloat = 160.0
    var onEditTap: () -> Void // ↩️
    @EnvironmentObject var voiceRecorderManager: VoiceRecorderManager

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topLeading) {
                card.frameColor.opacity(0.5) // New
                    .frame(width: cardWidth * 0.9, height: cardWidth * 0.9)
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
                        .padding(.leading, cardWidth - 54)
                    }
                }
            }

            Text(card.title)
                .font(.system(size: 20))
                .fontWeight(.medium)
                //.foregroundColor(.primary)
                .foregroundColor(Color("SecondaryTextColor"))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .frame(width: cardWidth, height: cardWidth * 1.5)
        //.background(Color.white.opacity(0.8))
        .background(Color("CardBGColor"))
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


struct GameUserCardView: View {
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

//                    Image("Game Icon")
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
                    .font(.system(size: 20))
                    .fontWeight(.medium)
                    //.foregroundColor(.primary)
                    .foregroundColor(Color("SecondaryTextColor"))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding()
            .frame(width: cardWidth, height: cardWidth * 1.5)
            //.background(Color.white.opacity(0.8))
            .background(Color("CardBGColor"))
            .cornerRadius(21.78)
            .overlay(
                RoundedRectangle(cornerRadius: 21.78)
                    .stroke(categoryColor, lineWidth: 3.27)
            )
        }
    }
}
