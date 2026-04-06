# BuildLog

Turn GitHub activity into clean, shareable developer updates.

BuildLog helps developers turn real work into usable content for platforms like LinkedIn, X, Reddit, and Discord without exposing private repos or relying on generic post templates. It uses structured logic, activity scoring, and GitHub data to turn messy commit history into clearer public-facing updates.

---

## 🚀 What It Does

BuildLog helps with the annoying part of building in public:

- turning GitHub activity into something worth posting
- reducing commit noise
- highlighting recent work first
- keeping older history available when needed
- generating platform-ready drafts without exposing private work

Instead of dumping raw commits into a post, BuildLog pulls activity, cleans it up, prioritizes meaningful signals, and generates a more usable summary.

---

## ✨ Current Features

- Public GitHub activity lookup by username
- Private GitHub activity via OAuth
- Recent activity prioritized by recency
- Expandable older activity history
- Progressive loading for larger activity lists
- Commit cleanup and deduplication
- Theme grouping for work types like UI, auth, fixes, generation logic, and more
- Lightweight signal scoring to prioritize more meaningful work
- Platform-ready draft generation for:
  - LinkedIn
  - X
  - Reddit
  - Discord
- Responsive Flutter web interface
- Local persistence for username, mode, selected platform, and token
- Copy-to-clipboard post output

---

## 🧠 How the Logic Works

BuildLog does more than reformat commit messages.

### Activity processing
- pulls recent GitHub activity
- filters noisy or less useful commit data
- cleans and deduplicates commit messages
- sorts activity with recent work first

### Summary generation
- classifies commit messages into work themes
- scores stronger signals higher than low-value updates
- prioritizes the most meaningful work
- generates a cleaner summary instead of a raw commit dump

This keeps the output more useful for developers who want to share progress without sounding robotic or exposing internal details.

---

## 🧰 Tech Stack

- **Frontend:** Flutter Web
- **Backend:** Netlify Functions
- **API:** GitHub REST API
- **Auth:** GitHub OAuth
- **State/Persistence:** Shared Preferences
- **Logic Layer:** structured summarization + lightweight scoring system

---

## ⚙️ How It Works

1. Enter a GitHub username in public mode or connect GitHub in private mode  
2. BuildLog fetches recent activity  
3. Commit messages are cleaned, deduplicated, and grouped  
4. Signals are scored to prioritize stronger updates  
5. A platform-specific draft is generated  
6. Copy and share anywhere  

---

## 🌐 Deployment

BuildLog is set up for deployment on Netlify.

- Update GitHub OAuth callback URLs to match your deployed domain  
- Store OAuth credentials in Netlify environment variables  
- Rebuild and redeploy after updates  

---

## 🧭 Roadmap

### Current
- Public GitHub activity integration  
- Private GitHub OAuth connection  
- Responsive UI  
- Recency-first activity feed  
- Expandable older history  
- Smarter post generation with signal scoring  

### Next
- Stronger theme detection and scoring improvements  
- Better platform-specific formatting  
- Saved drafts  
- Browser extension  
- Direct posting integrations  
- More advanced ML-assisted summarization  

---

## 🔐 Security

BuildLog keeps things simple and secure:

- GitHub OAuth is used for authentication  
- Passwords are never stored  
- Client secrets stay server-side in Netlify functions  
- Private repos are not exposed in generated output  
- No unnecessary user data is stored  

BuildLog only uses the GitHub data needed to generate activity summaries.

---

## ⚠️ Usage Notice

This project is publicly viewable for portfolio purposes only.  
Unauthorized use, reproduction, or distribution of this code is prohibited.

---

## 💡 About

BuildLog is part of **Grit & Flow Labs**, a creative studio focused on building practical, accessible tools that feel good to use.

Built with grit. Designed for flow.

---

## 📄 License

Copyright (c) 2026 Sierra Adams

All rights reserved.

This code may not be copied, modified, distributed, or used in any way without explicit permission from the author.