---
name: release-agentnv
description: Publish a new version of AgentNV - run the tests, commit, push, build the .dmg and create a GitHub release. Use when the user asks to release, publish or share a version. Only with their go-ahead, since a release is public.
---

# Release AgentNV

Stop and ask if the user hasn't said to publish.

1. `tests/run.sh` must pass.
2. Commit and push `main`. The app's first launch and the curl install both take the code from there, so a release must never come before the push.
3. `macos/bundle.sh`, which writes `dist/AgentNV.dmg`.
4. `gh release create vX.Y.Z dist/AgentNV.dmg --title "AgentNV X.Y.Z" --notes "<what changed, for a user>"`.
5. If `gh api repos/robertsolves/agentnv/pages` says Not Found, turn the website on once: `gh api -X POST repos/robertsolves/agentnv/pages -f "source[branch]=main" -f "source[path]=/docs"`.
6. Check that `https://github.com/robertsolves/agentnv/releases/latest` lists the `.dmg` and that https://robertsolves.github.io/agentnv/ loads.

The app is ad-hoc signed, so people click **Open Anyway** once. A Developer ID certificate in `AGENTNV_SIGN_IDENTITY`, plus notarizing the `.dmg`, removes that step.
