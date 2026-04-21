<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=12,15,20&height=200&section=header&text=Positive%20🌟&fontSize=52&fontColor=fff&animation=twinkling&fontAlignY=36&desc=Your%20daily%20wellness%20companion%20for%20iOS&descAlignY=56&descSize=18" width="100%"/>

[![Swift](https://img.shields.io/badge/Swift-5.9-FA7343?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-Framework-0D96F6?style=for-the-badge&logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![Firebase](https://img.shields.io/badge/Firebase-Backend-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![iOS](https://img.shields.io/badge/iOS-16%2B-000000?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Xcode](https://img.shields.io/badge/Xcode-15-147EFB?style=for-the-badge&logo=xcode&logoColor=white)](https://developer.apple.com/xcode/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blueviolet?style=for-the-badge)](https://opensource.org/licenses/MIT)

> *Stay motivated. Build streaks. Grow together.*

[✨ Features](#-features) · [🛠 Tech Stack](#-tech-stack) · [⚙️ Setup](#%EF%B8%8F-setup) · [📁 Structure](#-project-structure) · [👤 Author](#-author)

</div>

---

## 📖 Overview

**Positive** is a full-featured iOS wellness app designed to help users build consistent positive habits, track their goals, and stay accountable — with friends.

Built entirely with **SwiftUI** for a smooth, native iOS experience and powered by **Firebase** for real-time data sync, authentication, and media storage. No third-party UI libraries — just clean, component-driven SwiftUI code.

---

## ✨ Features

<table>
<tr>
<td width="50%">

### 📅 Calendar View
Visualize your consistency over time with a **GitHub-style contribution heatmap**. See your strongest weeks at a glance and stay motivated by your progress streaks.

</td>
<td width="50%">

### 🏡 Home View
Your personal dashboard — current **streaks**, active **goal tracking**, daily highlights, and motivational nudges to keep you going.

</td>
</tr>
<tr>
<td width="50%">

### 🤝 Buddy System
Connect with friends as **accountability partners**. Share goals, track each other's progress, and celebrate milestones together — because growth is better with company.

</td>
<td width="50%">

### 📝 Feed
A community-style feed to **share problem-solving entries** and discoveries. Includes full-text **search and smart filters** to find relevant content fast.

</td>
</tr>
<tr>
<td width="50%">

### 🔐 Secure Authentication
**Firebase Auth** powered sign-in with support for email/password login. Credentials are never stored locally.

</td>
<td width="50%">

### ☁️ Cloud Sync
All data lives in **Firebase Firestore** — switch devices, reinstall the app, your data is always there. Media uploads handled by **Firebase Storage**.

</td>
</tr>
</table>

---

## 🛠 Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| **UI Framework** | SwiftUI | Declarative, native iOS interface |
| **State Management** | `@StateObject`, `@ObservableObject`, `@EnvironmentObject` | Reactive data flow |
| **Database** | Firebase Firestore | Real-time NoSQL cloud database |
| **Authentication** | Firebase Auth | Secure user sign-in & session management |
| **Media Storage** | Firebase Storage | Image and file uploads |
| **Architecture** | MVVM | Clean separation of View & business logic |
| **Min iOS** | iOS 16+ | Modern SwiftUI features |

---

## ⚙️ Setup

> ⚠️ The `GoogleService-Info.plist` is **not included** in this repo for security reasons. You must provide your own.

### Prerequisites
- macOS 13+ with **Xcode 15** or later
- An active **Firebase project** ([console.firebase.google.com](https://console.firebase.google.com))
- An Apple Developer account (for running on device)

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/Divyansh5070/Positive.git
cd Positive
```

2. Go to [Firebase Console](https://console.firebase.google.com) → Create a project → Add an **iOS app** with bundle ID matching the project
3. Download your `GoogleService-Info.plist` and place it at:
   ```
   Positive/Positive/GoogleService-Info.plist
   ```
4. Enable the following Firebase services in the console:
   - **Authentication** (Email/Password)
   - **Firestore Database**
   - **Storage**
5. Open `Positive.xcodeproj` in **Xcode**
6. Select your signing team under *Signing & Capabilities*
7. **Build & run** on your device or simulator (`⌘R`)

> 💡 A template file `GoogleService-Info.plist.example` is included as a reference for the required structure.

---

## 📁 Project Structure

```
Positive/
├── Positive.xcodeproj/         ← Xcode project file
├── Positive/
│   ├── App/
│   │   └── PositiveApp.swift   ← App entry point & Firebase init
│   ├── Views/
│   │   ├── HomeView.swift      ← Dashboard, streaks, goal tracking
│   │   ├── CalendarView.swift  ← Contribution heatmap
│   │   ├── FeedView.swift      ← Community feed with search
│   │   ├── BuddyView.swift     ← Accountability partner system
│   │   └── AuthView.swift      ← Login / sign-up screens
│   ├── ViewModels/             ← MVVM business logic layer
│   ├── Models/                 ← Data models (User, Goal, Entry…)
│   ├── Services/               ← Firebase service wrappers
│   └── GoogleService-Info.plist  ← ⚠️ Not included — add yours here
├── Info.plist
└── README.md
```

---

## 🗺 Roadmap

- [x] Firebase Auth (Email/Password)
- [x] Firestore real-time sync
- [x] Contribution calendar heatmap
- [x] Buddy / accountability system
- [x] Community feed with search & filters
- [ ] Push notifications (streak reminders)
- [ ] Widget support (iOS Home Screen)
- [ ] Apple Sign-In
- [ ] On-device ML for habit recommendations

---

## 👤 Author

<div align="center">

**Divyansh Sharma**  
BTech CSE · Chandigarh University

[![GitHub](https://img.shields.io/badge/GitHub-Divyansh5070-181717?style=for-the-badge&logo=github)](https://github.com/Divyansh5070)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Divyansh%20Sharma-0A66C2?style=for-the-badge&logo=linkedin)](https://www.linkedin.com/in/divyansh-sharma-12a52028a)

</div>

---

<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=gradient&customColorList=12,15,20&height=100&section=footer" width="100%"/>

*Built with ❤️ in SwiftUI · Powered by Firebase*

</div>
