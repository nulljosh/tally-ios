<div align="center">

# Tally iOS

<img src="icon.svg" alt="Tally iOS" width="120" />

iOS companion for [Tally](https://github.com/nulljosh/tally), the BC benefits tracker.

</div>

## Architecture

![Architecture](architecture.svg)

## Features

- [x] Auth: BC Self-Serve login with 2-hour session management
- [x] Dashboard: full-height layout, payment amount, countdown to 25th, status, benefit type
- [x] Messages: inbox from BC Self-Serve
- [x] Reports: view report table data, submit monthly report
- [x] Settings: refresh data (triggers Puppeteer scrape), clear cache, sign out
- [x] Offline caching of last-known data
- [x] Apple Liquid Glass UI with SF Pro typography
- [ ] Push notifications for payment dates

## Stack

- SwiftUI, iOS 17+
- Swift 6, @Observable state management
- URLSession with cookie jar (session cookie auth)
- Backend: `https://tally.heyitsmejosh.com` (Vercel + Puppeteer)

## Architecture

```
SwiftUI Views -> AppState (@Observable) -> TallyAPI (URLSession) -> Vercel Backend -> BC Self-Serve
```

Session cookies are managed automatically by `HTTPCookieStorage.shared`. On 401, AppState sets `showLogin = true` to prompt re-auth.

## Build

```bash
xcodegen generate
open Tally.xcodeproj
```

Requires Xcode 16+ (Swift 6).

## License

MIT 2026, Joshua Trommel

## Quick Commands
- `./scripts/simplify.sh` - normalize project structure
- `./scripts/monetize.sh . --write` - generate monetization plan (if available)
- `./scripts/audit.sh .` - run fast project audit (if available)
- `./scripts/ship.sh .` - run checks and ship (if available)
