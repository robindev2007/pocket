# Pocket (`pocket-expense-tracking-app`)

<p align="center">
  <img src="app/assets/icon/pocket_app_icon.jpg" width="120" height="120" alt="Pocket App Icon" style="border-radius: 28px;" />
</p>

<p align="center">
  <strong>Pocket</strong> is a full-stack, personal expense, cash-flow, and debt tracking ecosystem.
</p>

<p align="center">
  <a href="#-repository-structure">Structure</a> •
  <a href="#-app-flutter-client">Mobile App</a> •
  <a href="#-server-bun--express-backend">Backend Server</a> •
  <a href="#-architecture--sync-protocol">Architecture</a> •
  <a href="#-roadmap">Roadmap</a>
</p>

---

## 📁 Repository Structure

This repository is organized as a clean, unified **Monorepo**:

```
pocket-expense-tracking-app/
├── app/                 # Flutter Mobile & Web Client (Offline-First, GetX)
├── server/              # Bun + Express 5 + TypeScript + Prisma 7 Backend
├── SYSTEM_DESIGN.md     # System Architecture, Database Design & Delta Sync Protocol
├── TODO.md              # Feature Roadmap & Implementation Checklist
└── README.md            # Root Documentation
```

---

## 📱 App (Flutter Client)

- **Location:** [`app/`](./app/)
- **Tech Stack:** Flutter, Dart, GetX, Shared Preferences (`window.localStorage` on Web), Google Fonts (Plus Jakarta Sans).
- **Core Features:**
  - ⚡ **Local-First & 100% Offline Capable:** Runs smoothly without internet; syncs seamlessly when online.
  - 💰 **Total Cash & Real Adjusted Balance:** Raw cash-in-hand alongside net balance factoring in loans.
  - 🤝 **Two-Way Debt Management:** Track who owes you money vs. who you owe, with partial/full repayment tracking.
  - 📊 **Period Spending Visualizer:** Clean donut chart for Week, Month, Year, and All-time periods.
  - 🎨 **Minimal Borderless Design:** Flat surfaces, custom `#3D83F5` theme, and light/dark modes.

---

## ⚙️ Server (Bun / Express Backend)

- **Location:** [`server/`](./server/)
- **Tech Stack:** Bun runtime, Express 5, TypeScript, Prisma 7 with PostgreSQL adapter (`pg`), SWC + Jest.
- **Core Features:**
  - 🔐 **Google OAuth & JWT:** Cryptographically verified Google tokens and secure 7-day app JWTs.
  - 🔄 **Delta Sync Protocol:** Monotonic version-tracked sync (`syncVersion`) avoiding payload bloat.
  - 🔢 **Strict Financial Precision:** Uses PostgreSQL `Decimal(14, 2)` to eliminate floating-point rounding errors.
  - 🛡️ **Defensive Architecture:** Vertical slice / feature-first design with Zod request validation and centralized `AppError` handling.

---

## 📖 Architecture & Sync Protocol

For the complete architectural design, database schemas, and the client-server Delta Sync Protocol, see:
👉 **[`SYSTEM_DESIGN.md`](./SYSTEM_DESIGN.md)**

For current development progress and the feature checklist:
👉 **[`TODO.md`](./TODO.md)**

---

## 🚀 Quick Start

### 1. Run the Flutter App
```bash
cd app
flutter pub get
flutter run
```

### 2. Run the Backend Server
```bash
cd server
bun install
bun run dev
```

---

## 📄 License
This project is open-source and available under the MIT License.

