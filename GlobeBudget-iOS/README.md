# GlobeBudget iOS App

A native iOS app for managing your study abroad budget, built with SwiftUI and SwiftData.

## Features

- **Dashboard**: Overview of your budget with different tracking modes (Total, Remaining, Tracking)
- **Trips**: Plan and track trips with prepaid and planned costs
- **Calendar**: Visual calendar with trip overlay and weekly budget planner
- **Wishlist**: Save dream destinations with estimated costs
- **Local Storage**: All data stored locally on device using SwiftData (no account needed!)

## Requirements

- **Xcode 15.0+** (required for SwiftData)
- **iOS 17.0+** (SwiftData requires iOS 17)
- **macOS Sonoma** or later (for Xcode 15)

## Setup Instructions

### Step 1: Create a New Xcode Project

1. Open **Xcode**
2. Select **File → New → Project** (or `⇧⌘N`)
3. Choose **iOS → App** and click **Next**
4. Configure the project:
   - **Product Name**: `GlobeBudget`
   - **Team**: Select your Apple Developer account (free account works)
   - **Organization Identifier**: `com.yourname` (use your own)
   - **Interface**: **SwiftUI** ✓
   - **Language**: **Swift** ✓
   - **Storage**: **SwiftData** ✓ (IMPORTANT!)
5. Click **Next** and save the project somewhere (e.g., Desktop)

### Step 2: Copy the Swift Files

1. In Finder, navigate to this `GlobeBudget-iOS/GlobeBudget/` folder
2. Select all the files and folders:
   - `GlobeBudgetApp.swift`
   - `ContentView.swift`
   - `Models/` folder
   - `Views/` folder
   - `Utilities/` folder (if present)
3. Drag them into your Xcode project (in the Project Navigator on the left)
4. When prompted:
   - ✓ **Copy items if needed**
   - ✓ **Create groups**
   - Select your target
5. **Delete** the default files Xcode created (`Item.swift` if it exists)
6. **Replace** the default `GlobeBudgetApp.swift` and `ContentView.swift` with ours

### Step 3: Fix Any Import Issues

If Xcode shows errors after copying:

1. **Clean the build folder**: `⇧⌘K`
2. **Build**: `⌘B`
3. If there are still errors, make sure "Storage: SwiftData" was selected when creating the project

### Step 4: Configure App Icon (Optional)

1. Find or create an app icon (1024x1024 PNG recommended)
2. In Xcode, select **Assets.xcassets** in the Project Navigator
3. Select **AppIcon**
4. Drag your icon image to the "All Sizes" box

### Step 5: Run the App

1. Select a simulator (e.g., iPhone 15 Pro) from the device dropdown
2. Click the **Run** button (▶) or press `⌘R`
3. The app should launch in the simulator!

## Project Structure

```
GlobeBudget/
├── GlobeBudgetApp.swift      # App entry point with SwiftData setup
├── ContentView.swift          # Main tab navigation
├── Models/
│   ├── Budget.swift           # Budget model with modes
│   ├── Trip.swift             # Trip model
│   ├── Expense.swift          # Expense model
│   ├── WishlistItem.swift     # Wishlist item model
│   └── WeeklyPlan.swift       # Weekly planning models
└── Views/
    ├── Dashboard/
    │   ├── DashboardView.swift
    │   ├── BudgetSetupView.swift
    │   └── AddExpenseView.swift
    ├── Trips/
    │   ├── TripsView.swift
    │   └── TripFormView.swift
    ├── Calendar/
    │   ├── CalendarTabView.swift
    │   └── AddWeeklyEventView.swift
    ├── Wishlist/
    │   ├── WishlistView.swift
    │   └── WishlistFormView.swift
    └── Settings/
        └── SettingsView.swift
```

## Key Differences from Web Version

| Feature | Web (React) | iOS (SwiftUI) |
|---------|-------------|---------------|
| Data Storage | Supabase (cloud) | SwiftData (local) |
| Authentication | Email/Password | None needed |
| Sync | Across devices | Single device only |
| Offline | Limited | Full offline support |

## Publishing to the App Store

### Requirements

1. **Apple Developer Account** ($99/year) - [developer.apple.com](https://developer.apple.com)
2. App Store Connect account
3. App icons, screenshots, and descriptions

### Steps

1. **Archive the app**: Product → Archive
2. **Validate** the archive
3. **Distribute** to App Store Connect
4. In App Store Connect:
   - Create a new app
   - Fill in all metadata (description, keywords, screenshots)
   - Submit for review

### App Store Tips

- Take screenshots on multiple device sizes
- Write a compelling description
- Choose relevant keywords
- Set appropriate age rating (4+ for this app)
- Privacy policy URL is required

## Future Enhancements

- [ ] iCloud sync for multi-device support
- [ ] Widgets for home screen
- [ ] Apple Watch companion app
- [ ] Currency conversion
- [ ] Push notification reminders
- [ ] Data import from web version

## Troubleshooting

### "Cannot find 'Budget' in scope"
Make sure SwiftData was selected when creating the project, or manually add `import SwiftData` to affected files.

### Build errors after copying files
Try: Product → Clean Build Folder (`⇧⌘K`), then Build (`⌘B`)

### Simulator won't launch
Reset the simulator: Device → Erase All Content and Settings

## License

This project is for personal use. Feel free to modify and use for your own study abroad adventures!

---

Made with ❤️ for study abroad students everywhere 🌍

