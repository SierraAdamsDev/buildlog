# BuildLog

Turn your GitHub activity into clean, shareable updates.

BuildLog helps developers turn real work into content for platforms like LinkedIn, X (Twitter), Reddit, and Discord — without relying on AI. It uses structured logic and real GitHub activity to generate consistent, usable post drafts.

---

## 🚀 Features

### V1
- GitHub username input for public activity
- GitHub login/connect flow for private activity (OAuth)
- GitHub API integration for real activity data
- Platform-ready post generation (LinkedIn, X, Reddit, Discord)
- Clean, responsive Flutter web UI
- Local persistence (username, mode, selected platform)
- Copy-to-clipboard post drafts

### V2
- Direct platform integrations:
  - Discord
  - X (Twitter)
  - Reddit
  - LinkedIn
- Browser extension for quick post generation
- Saved drafts
- Platform-specific formatting improvements

---

## 🧰 Tech Stack

- **Frontend:** Flutter (Web)
- **Backend:** Netlify Functions (Serverless)
- **APIs:** GitHub REST API
- **Auth:** GitHub OAuth

---

## ⚙️ How It Works

1. Enter a GitHub username (public mode) or connect your GitHub account (private mode)
2. BuildLog fetches recent activity (push events)
3. Commit messages are cleaned and structured
4. A platform-specific post is generated
5. Copy and share anywhere

---

## 🛠️ Getting Started

### Prerequisites
- Flutter installed
- GitHub account
- Netlify account (for OAuth functions)

### Run locally

```powershell
flutter pub get
flutter run -d chrome
```

---

## 🧭 Roadmap

### V1 (Current Focus)
- Public GitHub activity integration
- Private GitHub OAuth connection
- Clean UI and post generation
- Local persistence

### V2
- Direct posting integrations
- Browser extension
- Enhanced formatting + drafts

---

## 🔐 Security

BuildLog keeps things simple and secure:

- GitHub OAuth is used for authentication (no passwords stored)
- Client secrets are handled server-side (Netlify functions)
- No sensitive credentials are exposed in the frontend
- No unnecessary user data is stored

BuildLog only accesses the minimum GitHub data needed to generate activity summaries.

## ⚠️ Usage Notice

This project is publicly viewable for portfolio purposes only.  
Unauthorized use, reproduction, or distribution of this code is prohibited.

---

## 🌐 Deployment

This project is designed to be deployed on Netlify.

When deployed:
- Update GitHub OAuth callback URLs to match your domain
- Store OAuth credentials in Netlify environment variables

---

## 💡 About

BuildLog is part of **Grit & Flow Labs** — a creative studio focused on building practical, accessible tools that feel good to use.

We blend hustle and heart: grit for the build, flow for the experience.

---

## 📄 License

Copyright (c) 2026 Sierra Adams

All rights reserved.

This code may not be copied, modified, distributed, or used in any way without explicit permission from the author.