# Spelunkr for Apple TV

## Scope

Build a native SwiftUI tvOS frontend for https://spelunkr.tv/. Use the site's public channel catalog and synchronized schedule, with Internet Archive media played through AVKit. Preserve the site's channel identity and retro broadcast feel while making navigation legible and comfortable with the Siri Remote. This is an unofficial client, with no account or backend changes.

## Plan

- [x] Inspect public catalog, schedule, media sources, and branding; record the integration contract.
- [x] Create a reproducible Xcode project for tvOS 18+, using Swift 6 and no third-party runtime dependencies.
- [x] Implement typed network models, deterministic schedule resolution, resilient catalog loading, and local favorites.
- [x] Build the television channel guide with focused selection, current/upcoming programs, categories, search, and favorites.
- [x] Implement native synchronized playback, automatic program transitions, channel switching, and useful recovery states.
- [x] Verify scheduling and decoding with focused tests; build for simulator and device; exercise the Apple TV UI and real playback.
- [x] Document setup, source attribution, verification evidence, and remaining limits.
- [x] Review changes, update this checklist, and commit the completed project to git.

## Acceptance criteria

- The app loads the real Spelunkr channel lineup without a sign-in.
- A viewer can find and select a channel using remote focus navigation.
- Current/upcoming program information follows the website's scheduling rules.
- Playback starts from the current program offset and advances at the next program boundary.
- Failures are visible and retryable; favorites survive app relaunch.
- The checked-in Xcode project builds, meaningful automated checks pass, and simulator verification is recorded honestly.

## Review

Verified November 22, 2026:

- `SPELUNKR_LIVE_TESTS=1 swift test`: 10 tests passed, including 1,519 timestamp comparisons with the published engine and three custom/missing/insecure audio-base cases. The network check loaded schedules for all 36 channels in the official backup snapshot.
- Apple TV 4K simulator, tvOS 18.5: two XCTest UI tests passed. Siri Remote navigation opened and dismissed search, and a changed favorite survived relaunch before the test restored its initial value. Results: `build/UITests-final.xcresult`.
- Xcode 16.4 simulator and unsigned Apple TV device builds passed with Swift 6 complete concurrency checking. Swift 6.2.4 also type-checked the core and app against the installed tvOS 26.2 SDK. Xcode 26.3's missing tvOS platform components prevented a full build with that installation; the README documents the working installation.
- The running simulator loaded the live catalog with 37 channels and real Internet Archive artwork. Actual video playback was observed on Saturday Morning, Primetime, and Vacation Slides. The native channel menu changed channels and wrapped from the first to the last channel.
- Vacation Slides displayed track attribution; AVPlayer logs confirmed the soundtrack loaded and sought to its scheduled offset. Pausing and resuming rejoined the broadcast and loaded the current soundtrack cue. System audio was not independently recorded or auditioned.
- Manual review corrected player-menu dismissal during clock updates, asynchronous seek cancellation, stale schedule retention, periodic refresh during full-screen viewing, and loading/audio failure recovery. AVKit's default start-over action was replaced with broadcast-appropriate live/guide actions.
- Source attribution, endpoint fallback behavior, reproducible artwork, setup instructions, and the schedule fixture's provenance are documented. No production media, credentials, or downloaded website bundle is included.

Limits at this checkpoint: physical Apple TV, hardware remote feel, audible mix quality, sustained playback through every interstitial/recording, and App Store submission remained unverified. The core tests cover program and interstitial boundaries; manual simulator playback covers selected real recordings. Decorative station-break video, translated subtitle sidecars, and optional detailed credits are not included. Hardware installation and startup were subsequently verified below.

## Device installation and distribution preparation — November 23, 2026

Use the user's existing OnePatchDown, LLC developer membership. Prepare signing and a current-toolchain build, then install on the user's Apple TV when pairing is available. TestFlight upload and invitations are separate distribution steps.

- [x] Identify the existing OnePatchDown team and check connected devices.
- [x] Configure automatic signing for OnePatchDown, LLC in the reproducible project.
- [x] Install the tvOS 26.2 platform in Xcode 26.3 and validate a Release archive without signing.
- [x] Validate a signed archive after Apple account provisioning is available.
- [x] Address concrete archive/upload prerequisites found in the release configuration.
- [x] Pair the user's Apple TV and confirm it is an available Xcode destination.
- [x] Install and verify launch after OnePatchDown provisioning is available.
- [x] Record results and commit the preparation changes.

Initial evidence: the keychain contained Apple Distribution and Developer ID certificates for OnePatchDown, LLC, team `THSJJN6KNN`. No Apple TV initially appeared in `devicectl list devices`; pairing was pending.

Preparation review:

- Added the team's signing configuration to `project.yml` and regenerated the Xcode project. App and UI test targets inherit it in Debug and Release.
- Added `PrivacyInfo.xcprivacy` with UserDefaults reason `CA92.1` for app-only favorites. `plutil` validation passed and the manifest is included in the archived application.
- Installed tvOS 26.2 (23K51) using `xcodebuild -downloadPlatform tvOS`. Xcode 26.3 successfully produced `build/Spelunkr-unsigned.xcarchive` with the tvOS 26.2 SDK and minimum tvOS 18.0. This is build evidence only; the unsigned archive cannot be installed or uploaded as-is.
- The user added the Apple Account to Xcode. A signed archive attempt reached Apple's provisioning service but failed with **PLA Update available**: the OnePatchDown Account Holder must accept the latest Developer Program License Agreement before profiles can be created. The matching tvOS app provisioning profile is not available yet.
- Paired the user's **physical Apple TV** using its displayed code. Xcode and `devicectl` confirm a connected Apple TV (4th generation), tvOS 26.6.1, and Xcode lists it as an available run destination.
- Retrying signed archiving after the user's agreement confirmation returned the same PLA error. Read-only inspection showed the browser was using an individual enrollment while Xcode was using the company's separate enrollment. The signed-in Xcode account has Admin access to OnePatchDown. Acceptance by that company's Account Holder is still required. No agreement was accepted by the agent, and no TestFlight build was uploaded.
- Subsequent company sign-in verified the account's Account Holder and Admin roles. The user accepted the company's pending agreement; its banner cleared and Xcode no longer reports the PLA error.
- The first archive attempt after acceptance reported that the team had no registered devices. A Release `build` targeting the paired Apple TV with `-allowProvisioningUpdates -allowProvisioningDeviceRegistration` registered the paired TV, created its development profile, and succeeded. Archiving alone had not registered the device.
- Signed Release archive `build/OnePatchDown-Spelunkr.xcarchive` succeeded with Xcode 26.3 and tvOS 26.2. `codesign --verify --deep --strict` passed. The app's exact application identifier and team match OnePatchDown's wildcard development profile, which includes the paired Apple TV and expires November 23, 2027. The privacy manifest is embedded.
- `devicectl` installed version 1.0.0, build 1 on the paired Apple TV; Xcode's installed-app list independently shows Spelunkr. The initial launch request was refused because the TV was asleep, so the user was asked to wake it before launch verification.
- After the user woke the TV, `devicectl` successfully launched `org.fragmede.SpelunkrTV`. An Xcode device screenshot confirms the guide on the physical Apple TV, with all 37 channels, downloaded artwork, and current/upcoming program information. Evidence: `docs/screenshots/apple-tv-guide.png`; local install and launch results: `build/tv-install.json` and `build/tv-launch.json`.

Installation review: the signed archive is valid, the app is installed on the paired Apple TV, and startup plus live guide loading are verified on hardware. No application code changes were needed for installation. Hardware playback, remote interaction, audible mix, and sustained viewing remain to be exercised; the earlier simulator playback and UI-test evidence still apply. TestFlight upload, beta invitations, and App Store submission remain separate distribution work.

## GPL licensing and GitHub publication — November 23, 2026

- [x] Audit tracked files and history for private setup details and third-party material.
- [x] Add GPL-3.0-or-later licensing with a clear source/content boundary.
- [x] Prepare a public source snapshot while preserving local development history and existing working changes.
- [x] Create the public GitHub repository, push the source, and verify the remote commit and recognized license.
- [x] Record the publication result and commit the completed notes.

Publication review:

- Published [fragmede/spelunkr-tv](https://github.com/fragmede/spelunkr-tv) as a public repository on `main`.
- Added the unmodified GNU GPL version 3 text from the Free Software Foundation and an explicit GPL-3.0-or-later grant in the README. GitHub's license endpoint recognizes GNU GPL v3.0. The grant covers this client's source and original assets; existing third-party attribution and screenshot-artwork exclusions are retained.
- Audited all tracked files and the original four commits: no signing keys, credentials, device UDIDs, or private filesystem paths were tracked. Removed Apple login addresses and personal device names from the published notes. The public initial commit uses the author's GitHub noreply address.
- Preserved original development history on the local-only `local/pre-github-publication-2026-11-23` branch. Published a clean initial commit, `affc7b1bafe3b1194b40f4499d4a4d418295487d`, and verified that the remote has only `main`. The pre-existing uncommitted Xcode scheme remains untouched.
- The published source tree matches the prepared local tree. The LICENSE matches the canonical downloaded text, the remote commit matches the pushed commit, and `git diff --check` passes. Application code did not change, so the prior build, automated-test, and device-launch evidence applies.

## App Store preparation and submission — November 23, 2026

Prepare a free tvOS release under OnePatchDown, LLC with manual release after review. Keep the public source GPL-3.0-or-later. Fill Apple declarations from verified behavior and user-provided facts; leave unanswered ownership, content-rating, or legal declarations for the user rather than asserting them.

- [x] Add an offline-readable privacy policy in the app and prepare matching privacy/support documents.
- [x] Prepare listing text, a 1920 × 1080 guide screenshot, and review instructions.
- [x] Register an explicit bundle identifier and provision it for App Store distribution under the company team.
- [ ] Create the tvOS App Store Connect record under the company team.
- [x] Verify the privacy flow and export an App Store-signed build.
- [ ] Upload the App Store-signed build once the app record exists.
- [ ] Complete the store listing, pricing, availability, review details, and manual-release setting.
- [ ] Submit for review when required declarations are confirmed, or record the exact remaining inputs.
- [x] Commit and push the preparation changes.

Preparation review:

- The guide's About sheet opens an offline privacy policy. Simulator tests passed for that flow, search navigation, and favorite persistence. The public privacy and support documents accompany the listing draft.
- Apple rejected `org.fragmede.SpelunkrTV` as unavailable to the company for explicit registration. Xcode registered `net.onepatchdown.spelunkrtv` and obtained a tvOS App Store profile for team `THSJJN6KNN`. The new identifier installs separately from the original development build.
- Archived version 1.0.0, build 1 using Xcode 26.3 and the tvOS 26.2 SDK. The embedded privacy manifest validated. Xcode's first export hit a local rsync error copying symbols. Export with `uploadSymbols=false` succeeded. The resulting `build/Spelunkr-Store-export/Spelunkr.ipa` passed strict signature verification with the OnePatchDown Apple Distribution certificate and the exact App Store profile. The archive retains its local symbols.
- App Store Connect requires a signed-in company session to create the app record. Content-rights and territory declarations, age rating, reviewer contact, and the App Store binary's distribution terms still need to be resolved before submission.
