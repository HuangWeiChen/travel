import SwiftUI
import PhotosUI
import ImageIO

enum TravelStyle: String, CaseIterable, Identifiable {
    case relaxing = "慢活放鬆"
    case food = "美食探索"
    case adventure = "戶外冒險"
    case shopping = "購物血拚"

    var id: Self { self }

    var symbol: String {
        switch self {
        case .relaxing: "leaf.fill"
        case .food: "fork.knife"
        case .adventure: "figure.hiking"
        case .shopping: "bag.fill"
        }
    }

    var suggestion: String {
        switch self {
        case .relaxing: "安排咖啡店、公園與散步行程，每天保留一些自由時間。"
        case .food: "先收藏當地市場與特色餐廳，熱門店家記得提前訂位。"
        case .adventure: "準備好走的鞋、防曬用品，也要預留天候不佳的備案。"
        case .shopping: "把想買的商品列成清單，並預留行李空間與購物預算。"
        }
    }
}

struct TravelPlan {
    let travelerName: String
    let destination: String
    let style: TravelStyle
    let budget: Double
    let departureDate: Date
    let specialDates: Set<DateComponents>
    let days: Int
    let travelers: Int
    let needsHotel: Bool
    let usesPublicTransport: Bool
    let notes: String
    let themeColor: Color
    let photoData: Data?

    var budgetPerPersonPerDay: Double {
        budget / Double(travelers * days)
    }

    var budgetLevel: String {
        switch budgetPerPersonPerDay {
        case ..<1_500: "精打細算"
        case ..<3_500: "舒適旅行"
        default: "豪華享受"
        }
    }

    var transportSuggestion: String {
        usesPublicTransport
            ? "以捷運、公車或鐵路為主，出發前可先確認交通票券。"
            : "可安排租車或計程車，記得把停車費與油資算進預算。"
    }

    var hotelSuggestion: String {
        needsHotel
            ? "住宿建議抓總預算的 30%，並優先選擇交通方便的位置。"
            : "這次不需要住宿，可以把更多預算留給餐飲與體驗。"
    }
}

private enum PlannerAlert {
    case missingInformation
    case confirmation

    var title: LocalizedStringResource {
        switch self {
        case .missingInformation: "資料還沒填完整"
        case .confirmation: "準備好出發了嗎？"
        }
    }

    var message: LocalizedStringResource {
        switch self {
        case .missingInformation: "請先輸入你的名字和旅行目的地。"
        case .confirmation: "旅行計畫已經整理完成，是否前往查看結果？"
        }
    }
}

private enum TravelPreset: CaseIterable, Identifiable {
    case taipei
    case tokyo
    case hualien

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .taipei: "台北美食週末"
        case .tokyo: "東京購物之旅"
        case .hualien: "花蓮慢活假期"
        }
    }

    var subtitle: LocalizedStringResource {
        switch self {
        case .taipei: "美食探索・2 天・NT$8,000"
        case .tokyo: "購物血拚・5 天・NT$45,000"
        case .hualien: "慢活放鬆・3 天・NT$15,000"
        }
    }

    var symbol: String {
        switch self {
        case .taipei: "fork.knife"
        case .tokyo: "bag.fill"
        case .hualien: "leaf.fill"
        }
    }
}

struct ContentView: View {
    @State private var travelerName = ""
    @State private var destination = ""
    @State private var style: TravelStyle = .relaxing
    @State private var budget = 20_000.0
    @State private var departureDate = Date()
    @State private var specialDates: Set<DateComponents> = []
    @State private var days = 3
    @State private var travelers = 1
    @State private var needsHotel = true
    @State private var usesPublicTransport = true
    @State private var notes = ""
    @State private var themeColor = Color.indigo
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var alertKind: PlannerAlert = .missingInformation
    @State private var showsAlert = false
    @State private var preparedPlan: TravelPlan?
    @State private var showsResult = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    PlannerHeader()
                    PresetSection(onApply: applyPreset)
                    BasicInformationSection(
                        travelerName: $travelerName,
                        destination: $destination,
                        style: $style
                    )
                    ScheduleSection(
                        departureDate: $departureDate,
                        specialDates: $specialDates,
                        days: $days
                    )
                    BudgetSection(
                        budget: $budget,
                        travelers: $travelers,
                        needsHotel: $needsHotel,
                        usesPublicTransport: $usesPublicTransport
                    )
                    PersonalizationSection(
                        notes: $notes,
                        themeColor: $themeColor
                    )
                    PhotoSection(
                        selectedPhotoItem: $selectedPhotoItem,
                        photoData: photoData
                    )
                    CreatePlanButton(action: createPlan)
                }
                .padding()
            }
            .background(Color.secondary.opacity(0.08))
            .navigationTitle("旅行規劃")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    photoData = try? await newItem?.loadTransferable(type: Data.self)
                }
            }
            .alert(alertKind.title, isPresented: $showsAlert) {
                if alertKind == .confirmation {
                    Button("查看結果") {
                        showsResult = true
                    }
                    Button("繼續修改", role: .cancel) {}
                } else {
                    Button("知道了", role: .cancel) {}
                }
            } message: {
                Text(alertKind.message)
            }
            .navigationDestination(isPresented: $showsResult) {
                if let preparedPlan {
                    TravelResultView(plan: preparedPlan)
                }
            }
        }
    }

    private func createPlan() {
        let trimmedName = travelerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDestination = destination.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty, !trimmedDestination.isEmpty else {
            alertKind = .missingInformation
            showsAlert = true
            return
        }

        preparedPlan = TravelPlan(
            travelerName: trimmedName,
            destination: trimmedDestination,
            style: style,
            budget: budget,
            departureDate: departureDate,
            specialDates: specialDates,
            days: days,
            travelers: travelers,
            needsHotel: needsHotel,
            usesPublicTransport: usesPublicTransport,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            themeColor: themeColor,
            photoData: photoData
        )
        alertKind = .confirmation
        showsAlert = true
    }

    private func applyPreset(_ preset: TravelPreset) {
        switch preset {
        case .taipei:
            destination = "台北"
            style = .food
            days = 2
            budget = 8_000
            needsHotel = false
            usesPublicTransport = true
            notes = "想吃夜市小吃，也想找一間有特色的咖啡店。"
            themeColor = .orange
        case .tokyo:
            destination = "東京"
            style = .shopping
            days = 5
            budget = 45_000
            needsHotel = true
            usesPublicTransport = true
            notes = "想逛百貨、動漫商店，並安排一天自由活動。"
            themeColor = .pink
        case .hualien:
            destination = "花蓮"
            style = .relaxing
            days = 3
            budget = 15_000
            needsHotel = true
            usesPublicTransport = false
            notes = "想看海、散步，行程不要排得太滿。"
            themeColor = .teal
        }
    }
}

private struct PlannerHeader: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "airplane.departure")
                .font(.system(size: 42))
                .foregroundStyle(.indigo)

            Text("填入旅行條件")
                .font(.title2.bold())
        }
        .padding(.vertical, 8)
    }
}

private struct PresetSection: View {
    let onApply: (TravelPreset) -> Void

    var body: some View {
        SectionCard(title: "快速範例", symbol: "sparkles") {
            Text("點一下套用，或長按卡片開啟 context menu。")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(TravelPreset.allCases) { preset in
                Button {
                    onApply(preset)
                } label: {
                    HStack {
                        Image(systemName: preset.symbol)
                            .frame(width: 32)
                        VStack(alignment: .leading) {
                            Text(preset.title)
                                .font(.headline)
                            Text(preset.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.down.doc")
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button {
                        onApply(preset)
                    } label: {
                        Label("套用這組條件", systemImage: "wand.and.stars")
                    }
                }
            }
        }
    }
}

private struct BasicInformationSection: View {
    @Binding var travelerName: String
    @Binding var destination: String
    @Binding var style: TravelStyle

    var body: some View {
        SectionCard(title: "基本資料", symbol: "person.text.rectangle") {
            TextField("你的名字", text: $travelerName)
                .textFieldStyle(.roundedBorder)

            TextField("想去的城市或國家", text: $destination)
                .textFieldStyle(.roundedBorder)

            Picker("旅行風格", selection: $style) {
                ForEach(TravelStyle.allCases) { option in
                    Label(option.rawValue, systemImage: option.symbol)
                        .tag(option)
                }
            }
            .pickerStyle(.menu)
        }
    }
}

private struct ScheduleSection: View {
    @Binding var departureDate: Date
    @Binding var specialDates: Set<DateComponents>
    @Binding var days: Int

    var body: some View {
        SectionCard(title: "日期安排", symbol: "calendar") {
            DatePicker(
                "出發日期",
                selection: $departureDate,
                in: Date.now...,
                displayedComponents: .date
            )

            Stepper("旅行天數：\(days) 天", value: $days, in: 1...14)

            VStack(alignment: .leading, spacing: 8) {
                Text("特別行程日期")
                    .font(.subheadline.bold())
                Text("可以選擇想安排重點活動的日期。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                MultiDatePicker(
                    "特別行程日期",
                    selection: $specialDates,
                    in: Date.now...
                )
                .labelsHidden()
            }
        }
    }
}

private struct BudgetSection: View {
    @Binding var budget: Double
    @Binding var travelers: Int
    @Binding var needsHotel: Bool
    @Binding var usesPublicTransport: Bool

    var body: some View {
        SectionCard(title: "預算與需求", symbol: "dollarsign.circle") {
            VStack(alignment: .leading, spacing: 8) {
                Text("總預算")
                    .font(.subheadline.bold())
                Text(
                    budget,
                    format: .currency(code: "TWD").precision(.fractionLength(0))
                )
                .font(.title2.bold())
                .foregroundStyle(.indigo)

                Slider(value: $budget, in: 5_000...100_000, step: 1_000) {
                    Text("旅行總預算")
                } minimumValueLabel: {
                    Text("5千")
                        .font(.caption)
                } maximumValueLabel: {
                    Text("10萬")
                        .font(.caption)
                }
            }

            Stepper("同行人數：\(travelers) 人", value: $travelers, in: 1...10)
            Toggle("需要安排住宿", isOn: $needsHotel)
            Toggle("偏好大眾運輸", isOn: $usesPublicTransport)
        }
    }
}

private struct PersonalizationSection: View {
    @Binding var notes: String
    @Binding var themeColor: Color

    var body: some View {
        SectionCard(title: "個人化設定", symbol: "paintpalette") {
            VStack(alignment: .leading, spacing: 8) {
                Text("旅行願望與備註")
                    .font(.subheadline.bold())
                TextEditor(text: $notes)
                    .frame(minHeight: 110)
                    .padding(6)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        if notes.isEmpty {
                            Text("例如：想看夜景、吃在地美食……")
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .allowsHitTesting(false)
                        }
                    }
            }

            ColorPicker("結果卡片顏色", selection: $themeColor, supportsOpacity: false)
        }
    }
}

private struct PhotoSection: View {
    @Binding var selectedPhotoItem: PhotosPickerItem?
    let photoData: Data?

    var body: some View {
        SectionCard(title: "旅行封面", symbol: "photo") {
            TravelPhotoPreview(photoData: photoData)

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Label(
                    photoData == nil ? "選擇封面照片" : "更換封面照片",
                    systemImage: "photo.on.rectangle"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            if photoData != nil {
                Button("移除照片", role: .destructive) {
                    selectedPhotoItem = nil
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct TravelPhotoPreview: View {
    let photoData: Data?

    var body: some View {
        if let photoData, let image = decodedImage(from: photoData) {
            image
                .resizable()
                .scaledToFill()
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .clipped()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.indigo.opacity(0.12))
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.indigo)
            }
            .frame(height: 140)
        }
    }
}

private struct CreatePlanButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("產生旅行計畫", systemImage: "wand.and.stars")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .tint(.indigo)
        .controlSize(.large)
    }
}

private struct SectionCard<Content: View>: View {
    let title: LocalizedStringResource
    let symbol: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: symbol)
                .font(.headline)
                .foregroundStyle(.indigo)
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
    }
}

private struct TravelResultView: View {
    let plan: TravelPlan

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ResultHeroSection(
                    destination: plan.destination,
                    travelerName: plan.travelerName,
                    themeColor: plan.themeColor,
                    photoData: plan.photoData
                )
                BudgetResultSection(
                    budget: plan.budget,
                    perPersonPerDay: plan.budgetPerPersonPerDay,
                    budgetLevel: plan.budgetLevel,
                    travelers: plan.travelers,
                    days: plan.days
                )
                TripSummarySection(
                    style: plan.style,
                    departureDate: plan.departureDate,
                    specialDateCount: plan.specialDates.count,
                    notes: plan.notes
                )
                RecommendationSection(
                    styleSuggestion: plan.style.suggestion,
                    transportSuggestion: plan.transportSuggestion,
                    hotelSuggestion: plan.hotelSuggestion,
                    themeColor: plan.themeColor
                )
            }
            .padding()
        }
        .background(Color.secondary.opacity(0.08))
        .navigationTitle("旅行計畫")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ResultHeroSection: View {
    let destination: String
    let travelerName: String
    let themeColor: Color
    let photoData: Data?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let photoData, let image = decodedImage(from: photoData) {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [themeColor, themeColor.opacity(0.55)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay {
                    Image(systemName: "airplane")
                        .font(.system(size: 74))
                        .foregroundStyle(.white.opacity(0.25))
                }
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(destination)
                    .font(.largeTitle.bold())
                Text("\(travelerName) 的旅程")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .padding()
        }
        .frame(height: 240)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .clipped()
    }
}

private func decodedImage(from data: Data) -> Image? {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
          let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        return nil
    }

    return Image(decorative: cgImage, scale: 1, orientation: .up)
}

private struct BudgetResultSection: View {
    let budget: Double
    let perPersonPerDay: Double
    let budgetLevel: String
    let travelers: Int
    let days: Int

    var body: some View {
        SectionCard(title: "預算分析", symbol: "chart.pie.fill") {
            HStack {
                ResultMetric(
                    title: "總預算",
                    value: budget.formatted(
                        .currency(code: "TWD").precision(.fractionLength(0))
                    )
                )
                ResultMetric(
                    title: "每人每天",
                    value: perPersonPerDay.formatted(
                        .currency(code: "TWD").precision(.fractionLength(0))
                    )
                )
            }

            Divider()
            Label(budgetLevel, systemImage: "star.circle.fill")
                .font(.title3.bold())
            Text("\(travelers) 人旅行 \(days) 天")
                .foregroundStyle(.secondary)
        }
    }
}

private struct ResultMetric: View {
    let title: LocalizedStringResource
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TripSummarySection: View {
    let style: TravelStyle
    let departureDate: Date
    let specialDateCount: Int
    let notes: String

    var body: some View {
        SectionCard(title: "行程摘要", symbol: "list.clipboard.fill") {
            LabeledContent("旅行風格") {
                Label(style.rawValue, systemImage: style.symbol)
            }
            LabeledContent("出發日期") {
                Text(departureDate, format: .dateTime.year().month().day())
            }
            LabeledContent("特別行程") {
                Text(specialDateCount == 0 ? "尚未安排" : "已選 \(specialDateCount) 天")
            }

            if !notes.isEmpty {
                Divider()
                Text("旅行願望")
                    .font(.subheadline.bold())
                Text(notes)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct RecommendationSection: View {
    let styleSuggestion: String
    let transportSuggestion: String
    let hotelSuggestion: String
    let themeColor: Color

    var body: some View {
        SectionCard(title: "專屬建議", symbol: "lightbulb.fill") {
            RecommendationRow(
                symbol: "sparkles",
                title: "玩法",
                text: styleSuggestion,
                color: themeColor
            )
            RecommendationRow(
                symbol: "tram.fill",
                title: "交通",
                text: transportSuggestion,
                color: themeColor
            )
            RecommendationRow(
                symbol: "bed.double.fill",
                title: "住宿",
                text: hotelSuggestion,
                color: themeColor
            )
        }
    }
}

private struct RecommendationRow: View {
    let symbol: String
    let title: LocalizedStringResource
    let text: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.bold())
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
}
