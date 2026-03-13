# Tally iOS - Claude Guide

## Overview
iOS companion for [Tally](https://github.com/nulljosh/tally). BC benefits tracker with payment info and monthly reports.

## Stack
- SwiftUI, iOS 17+, @Observable
- BC Self-Serve API (shared backend with web)

## Design
- BC gov blue: #1a5a96 primary, #2472b2 mid, #4e9cd7 light
- Navy background: #0c1220
- No emojis

## Roadmap
- [x] Auth: BC Self-Serve login
- [x] Dashboard: full-height layout, payment amount, countdown, status
- [x] Monthly reports: view status, submit
- [x] DTC Navigator integration
- [x] Offline caching with instant launch
- [x] Apple Liquid Glass UI, SF Pro typography
- [ ] Push notifications for payment dates

## Build
```bash
open TallyApp.swift  # Opens in Xcode
```

## Quick Commands
- `./scripts/simplify.sh`
- `./scripts/monetize.sh . --write`
- `./scripts/audit.sh .`
- `./scripts/ship.sh .`
