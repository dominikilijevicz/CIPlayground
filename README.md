# CIPlayground

A deliberately tiny SwiftUI app whose real purpose is the pipeline around it.
It exists to practise iOS CI/CD end to end, at zero cost.

## Why it's free

| Piece | Cost | Why |
|---|---|---|
| GitHub Actions macOS runners | **$0** | Unlimited minutes for **public** repositories. Private repos bill macOS at a 10× multiplier, which burns the free tier in ~200 minutes/month. |
| SwiftLint / XcodeGen / xcbeautify / fastlane | $0 | Open source |
| Apple Developer Program | $99/yr | Only needed for the TestFlight half. CI (lint/build/test) needs nothing. |

The app code lives in a public repo. Signing certificates live in a **separate
private** repo managed by fastlane match — never in this one.

## Layout

```
project.yml              XcodeGen manifest — the source of truth for the project
Sources/                 App code (Counter.swift holds the testable logic)
Tests/                   Unit tests, Swift Testing
UITests/                 UI tests, XCUITest
fastlane/Fastfile        lint / test / beta lanes
.github/workflows/ci.yml       lint + build + test on every PR
.github/workflows/release.yml  verify, then sign and ship to TestFlight on a tag
```

`CIPlayground.xcodeproj` is **generated and gitignored**. Two people editing a
checked-in `.pbxproj` produce merge conflicts no human can resolve; a 60-line
`project.yml` produces a readable diff. Regenerate with `xcodegen generate`.

## Running it locally

Everything CI does, you can do on your own machine first — always cheaper than
debugging through a web log viewer.

```bash
brew install xcodegen xcbeautify swiftlint
bundle install
xcodegen generate
```

Lint:

```bash
swiftlint lint --strict
```

Build and test:

```bash
xcodebuild test -project CIPlayground.xcodeproj -scheme CIPlayground -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' CODE_SIGNING_ALLOWED=NO | xcbeautify
```

Or through fastlane:

```bash
bundle exec fastlane test
```

## The pipeline

**`ci.yml`** — on every push to `main` and every pull request:

1. `lint` job — SwiftLint in `--strict` mode, so warnings fail the build.
2. `test` job — generate project, build for testing, run unit + UI tests on a
   simulator, write a result summary, upload the `.xcresult` **only on failure**.

Both jobs run in parallel. `concurrency` cancels superseded runs on the same
branch so a stream of pushes doesn't queue up runners.

**`release.yml`** — on a `v*` tag, or manually:

1. `verify` job — re-runs the tests. A tag that was never tested must not ship.
2. `testflight` job — needs `verify`, runs in the `testflight` GitHub
   Environment (manual approval + scoped secrets), then:
   `match` fetches signing assets → build number is read from App Store Connect
   and incremented → `gym` archives and exports → `pilot` uploads.

Ship a build:

```bash
git tag v1.0.1 && git push origin v1.0.1
```

## Things that will bite you

- **Simulator destinations rot.** This pipeline's very first run failed with
  `exit code 70` because `iPhone 16` didn't exist on the runner image — it
  ships 16e, 17, 17 Pro, 17e and Air, but no plain 16. Both workflows now
  resolve the device at runtime from a preference list and fail with the real
  list if nothing matches. Pin the OS with `OS=latest`, never a number.
- **fastlane hid that bug; `xcodebuild` found it.** `scan` fuzzy-matches device
  names, so `bundle exec fastlane test` passed locally against `iPhone 16` by
  quietly resolving it to `iPhone 16e`. Plain `xcodebuild` requires an exact
  match. Convenient abstractions can mask a misconfiguration until something
  stricter runs.
- **`macos-latest` moves.** It's convenient for practice and a liability for
  reproducibility. Pin it (`macos-15`) once you care, and bump on purpose.
- **Build numbers come from the server.** `latest_testflight_build_number + 1`
  means two pipelines can't pick the same number. Don't commit build numbers
  back into the repo.
- **Fork PRs get no secrets.** That's deliberate, not a bug. Deploy jobs must
  never be triggered by `pull_request` from a fork.
- **`readonly: true` for match on CI.** A build should be able to *read*
  certificates, never mint or revoke them.

See [docs/CD_SETUP.md](docs/CD_SETUP.md) for the one-time secret setup.
