# BrewScan ☕

**Point. Scan. Brew.**

A native iOS app that scans Nespresso pods with your camera, identifies them using AI vision (GPT-4o), and shows you taste notes, brew tips, and drink recipes. Also features a full browseable catalog of 40+ pods and 15 curated recipes.

---

## What BrewScan Does

- 📷 **Scan any Nespresso pod** — point your camera, tap capture
- 🤖 **AI identification** — GPT-4o vision identifies the exact pod and line
- ☕ **Taste profiles** — tasting notes, intensity meter, origin, roast level
- 🍹 **Recipes** — 15 handcrafted recipes matched to compatible pods
- 📚 **Full catalog** — browse all Original and Vertuo line pods with rich detail
- 🎨 **Premium dark UI** — deep espresso aesthetic, feels right next to Nespresso's own app

---

## Setup

### 1. Clone the repo
```bash
git clone <your-repo-url>
cd brewscan
```

### 2. Open in Xcode
```bash
open BrewScan.xcodeproj
```
Or double-click `BrewScan.xcodeproj` in Finder.

### 3. Add your OpenAI API key
Open `BrewScan/Config.swift` and replace the placeholder:

```swift
struct Config {
    static let openAIKey = "YOUR_OPENAI_API_KEY_HERE"  // ← Replace this
}
```

Get your key at: https://platform.openai.com/api-keys

> **Cost note:** Each scan uses GPT-4o vision. A few cents per scan at standard pricing. Set a spending limit in your OpenAI account if needed.

---

## Running in Simulator

The catalog and recipes work fully in the simulator. The camera (scanner) requires a physical device.

1. Select any iPhone simulator in Xcode
2. Press ▶ to build and run
3. Use the **Catalog** tab to browse pods
4. Use the **Recipes** tab to explore drinks
5. The **Scan** tab will show a camera permission prompt — this won't function in sim

---

## Running on Device

1. Plug in your iPhone via USB
2. Select your device in Xcode's device picker
3. Set your Apple Developer Team:
   - Click the `BrewScan` project in the navigator
   - Select the `BrewScan` target → **Signing & Capabilities**
   - Set **Team** to your Apple Developer account
4. Press ▶ to build and deploy
5. On device: trust the developer certificate in **Settings → General → VPN & Device Management**
6. Open BrewScan, grant camera access, and scan!

---

## TestFlight Setup

### Prerequisites
- Active Apple Developer Program membership ($99/year)
- App Store Connect access

### Steps

1. **Archive the app**
   - In Xcode: Product → Archive
   - Wait for archive to complete

2. **Upload to App Store Connect**
   - In Organizer: click Distribute App
   - Select **App Store Connect** → Upload
   - Follow prompts, enable all bitcode/symbols options

3. **Configure in App Store Connect**
   - Go to https://appstoreconnect.apple.com
   - Create new app: **BrewScan**
   - Bundle ID: `com.brewscan.app`
   - Fill in name, description, screenshots

4. **Add TestFlight testers**
   - TestFlight tab → Internal Testing → Add testers (up to 100)
   - External Testing → Create group → Submit for review (24-48h)

5. **Testers install via TestFlight app**
   - They receive an email invite
   - Install TestFlight → tap invite link → install BrewScan

---

## Architecture Overview

```
BrewScan/
├── App/
│   ├── BrewScanApp.swift       # @main entry, global appearance config
│   └── ContentView.swift       # TabView (Catalog | Scan | Recipes)
│
├── Features/
│   ├── Scanner/
│   │   ├── ScannerView.swift   # Camera UI, capture button, viewfinder overlay
│   │   ├── CameraView.swift    # UIViewRepresentable wrapping AVCaptureSession
│   │   └── ScanResultView.swift # AI result display with pod detail or "not found"
│   │
│   ├── Catalog/
│   │   ├── CatalogView.swift   # Searchable grid of all pods
│   │   └── PodDetailView.swift # Full pod profile
│   │
│   └── Recipes/
│       ├── RecipesView.swift    # Recipe list
│       └── RecipeDetailView.swift # Step-by-step with interactive checklist
│
├── Models/
│   ├── Pod.swift               # Codable struct, intensityLabel computed var
│   └── Recipe.swift            # Codable struct
│
├── Services/
│   ├── PodDatabase.swift       # Singleton, loads JSON, query methods
│   └── OpenAIService.swift     # GPT-4o vision API, PodIdentificationResult
│
├── Extensions/
│   └── ColorExtension.swift    # Color(hex:) init + FlowLayout
│
└── Config.swift                # API key (replace before building)

Resources/
├── pods.json                   # 40+ pods with full data
└── recipes.json                # 15 recipes with steps, ingredients, compatible pods
```

### Data Flow

```
User taps Capture
    → CameraView captures JPEG via AVCapturePhoto
    → ScannerView sends imageData to OpenAIService
    → GPT-4o returns JSON: { podName, line, confidence, ... }
    → PodDatabase.shared matches name to local pod record
    → ScanResultView displays full pod detail + recipes
```

### Design System

| Token | Value | Use |
|---|---|---|
| Background | `#1A0F0A` | All screens |
| Primary accent | `#C8860A` | Buttons, highlights |
| Secondary | `#8B4513` | Roasted brown accents |
| Card BG | `#2D1F15` | Cards, rows |
| Text secondary | `#B0A090` | Labels, subtitles |
| Intensity gradient | `#C8A96E → #3D1A08` | Intensity meters |
| Original line | `#8B1A1A` | Burgundy badge |
| Vertuo line | `#1A4D2E` | Dark green badge |

---

## Pod Database

40 pods across Original and Vertuo lines including:

**Original:** Ristretto, Arpeggio, Roma, Livanto, Capriccio, Volluto, Cosi, Dharkan, Kazaar, Decaffeinato Intenso, Vanilio, Caramelito, Ciocattino, Hazelino, Barista Chiaro, Barista Corto, Ispirazione Firenze/Venezia/Napoli/Palermo, Master Origin Ethiopia/Colombia/Indonesia/Nicaragua/India, Vienna Roast

**Vertuo:** Alto, Altissio, Odacio, Melozio, Stormio, Elvazio, Fortado, Diavolitto, Il Caffè, Bianco Doppio/Leggero/Forte, Voltesso, Giornio, Solelio

---

## Contributing

PRs welcome! Key areas to improve:
- Add more pods (Nespresso releases new ones regularly)
- Offline pod image recognition fallback
- Favorites / brew history
- Apple Watch companion
- Brew timer with countdown

---

*Built with Swift, SwiftUI, AVFoundation, and GPT-4o Vision*
