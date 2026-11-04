---
name: release-agvim
description: Publish a new version of AgVim - run the tests, commit, push, build the .dmg and create a GitHub release. Use when the user asks to release, publish or share a version. Only with their go-ahead, since a release is public.
---

# Release AgVim

Stop and ask if the user hasn't said to publish.

1. Commit and push `main`.
2. Have the user run `agvim release X.Y.Z`. It checks `main`, runs the tests, asks, and pushes the tag. `.github/workflows/release.yml` then builds `AgVim.dmg` and publishes the release.
3. Check that https://github.com/robertsolves/agvim/releases/latest lists the `.dmg`. Everyone's AgVim updates to it when it next opens (`lib/auto-update`), so a release reaches people quickly: don't publish anything half-finished.

The website deploys by itself when `docs/` changes on `main` (`.github/workflows/site.yml`).

The app is ad-hoc signed, so people click **Open Anyway** once. A Developer ID certificate in `AGVIM_SIGN_IDENTITY`, plus notarizing the `.dmg`, removes that step.
