# Travel Planner

一款使用 SwiftUI 製作的旅行規劃 App。使用者可以設定目的地、旅行日期、預算、人數與個人偏好，並產生包含預算分析和個人化建議的旅行計畫。

## 功能

- 快速套用台北、東京與花蓮旅行範例
- 輸入旅客姓名與目的地
- 選擇慢活、美食、冒險或購物等旅行風格
- 設定出發日期、旅行天數與特別行程日期
- 調整總預算與同行人數
- 選擇住宿及交通需求
- 輸入旅行願望與備註
- 自訂結果卡片主題色
- 從照片圖庫選擇旅行封面
- 驗證必填資料並顯示確認 Alert
- 計算每人每天預算
- 根據旅行條件產生玩法、交通與住宿建議

## 使用技術

- Swift
- SwiftUI
- PhotosUI
- ImageIO
- SF Symbols
- Swift Concurrency

本專案未使用 UIKit。照片資料透過 ImageIO 解碼為 `CGImage`，再交由 SwiftUI 的 `Image` 顯示。

## 使用的 SwiftUI 元件

- `NavigationStack`
- `ScrollView`
- `TextField`
- `Picker`
- `DatePicker`
- `MultiDatePicker`
- `Stepper`
- `Slider`
- `Toggle`
- `TextEditor`
- `ColorPicker`
- `PhotosPicker`
- `Alert`
- `ContextMenu`

## 預算計算

App 會根據總預算、同行人數與旅行天數，計算每人每天可使用的預算：

```swift
var budgetPerPersonPerDay: Double {
    budget / Double(travelers * days)
}
```

預算會分成三個等級：

- 低於 NT$1,500：精打細算
- NT$1,500～NT$3,499：舒適旅行
- NT$3,500 以上：豪華享受

## 專案結構

```text
travel/
├── travel/
│   ├── Assets.xcassets
│   ├── ContentView.swift
│   └── MyApp.swift
└── README.md
```

- `MyApp.swift`：App 進入點
- `ContentView.swift`：旅行資料輸入、照片選擇、Alert、結果頁及相關元件
- `Assets.xcassets`：App 圖示與圖片資源

## 執行方式

1. 使用 Xcode 開啟專案。
2. 選擇 iPhone 模擬器或實體裝置。
3. 按下 Run，或使用 `Command + R` 執行。
4. 輸入旅行資料，或先套用快速範例。
5. 按下「產生旅行計畫」查看結果。

選擇旅行封面時，需要在支援照片圖庫的模擬器或實體裝置上操作。

## 操作流程

```text
輸入旅行條件
      ↓
選擇照片與主題色
      ↓
檢查必填資料
      ↓
確認產生計畫
      ↓
顯示預算分析與旅行建議
```

## 未來規劃

- 每日詳細行程
- 景點清單與地圖
- 天氣資訊
- 旅費分類與紀錄
- 儲存多筆旅行計畫
- 分享旅行計畫

## 開發環境

- Xcode
- Swift
- SwiftUI
- iOS

## License

此專案目前作為 SwiftUI 學習與作品展示用途。
