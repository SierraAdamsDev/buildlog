# BuildLog

BuildLog is a lightweight Flutter web app that turns GitHub activity into clean, platform-ready updates for LinkedIn, X, Reddit, Discord, and more — without exposing private repositories.

## Why I Built This
A lot of developer work happens in private repositories. BuildLog solves the problem of showing meaningful activity without making code public.

Instead of auto-posting everything, BuildLog helps developers **choose what’s worth sharing**.

## Core Idea
GitHub activity → clean summary → platform-ready post

## Features

### V1
- GitHub username input for public activity
- GitHub login/connect flow for private activity
- GitHub API integration for public + private activity
- Homepage with structured UI
- Platform-ready post preview
- Local persistence for username, mode, and selected platform
- Clean, responsive Flutter web interface

### V2
- Direct platform integrations:
  - Discord
  - X (Twitter)
  - Reddit
  - LinkedIn
- Browser extension for quick post generation
- Saved drafts
- More export options and platform-specific formatting improvements

## Tech Stack
- Flutter (Web)
- Dart
- GitHub API

## Status
🚧 In progress — actively building in public

## Future Direction
BuildLog is being built as a developer tool that helps turn real work into meaningful, shareable updates without noise or oversharing.

## Example Output

**Input (commits):**
- added homepage structure  
- cleaned up layout  
- started summary flow  

**Output (LinkedIn):**
> Built the first version of BuildLog today. Cleaned up the app structure, added a homepage, and started shaping how GitHub activity turns into readable updates.

## Goals
- Keep it simple
- Keep it useful
- Avoid unnecessary complexity
- Build features that actually solve real workflow problems

Built by Sierra Adams under Grit & Flow Labs