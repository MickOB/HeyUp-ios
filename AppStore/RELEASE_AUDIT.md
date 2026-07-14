# HeyUp 1.0 — release-readiness audit

Audited July 14, 2026.

## Completed in this pass

- Consolidated the working Xcode project and backed it up.
- Installed a 1024×1024 app icon with no alpha channel.
- Limited the target to iPhone.
- Limited the interface to portrait orientation.
- Published support and privacy information.
- Added Support and Privacy links to Settings.
- Removed the current SwiftUI compiler deprecation warning.
- Removed avoidable force unwraps from the camera start flow.
- Confirmed there are no third-party dependencies, analytics SDKs, ads, accounts, or remote data services.
- Confirmed the camera usage description explains on-device rep counting.

## Automated verification

- Debug simulator build must succeed before each release commit.
- Release configuration must be archived and validated after Developer Program approval.
- There are currently no unit or UI test targets; version 1.0 relies on build verification and manual device testing.

## Manual device testing required

- Fresh install and complete onboarding.
- Notification permission: allow and deny paths.
- Camera permission: allow and deny paths, including Open Settings recovery.
- Timer with the app foregrounded, backgrounded, phone locked, force-quit, paused, and resumed.
- Session-length cutoff and automatic restart after a successful break.
- Every exercise type, plus Mix and Both modes.
- Rep counting in varied lighting, distances, clothing, and body proportions.
- Skip once, skip twice, ease-up flow, and keep-going flow.
- History and streak behavior across midnight and after relaunch.
- Settings persistence and redo-onboarding flow.
- Support and Privacy links.
- VoiceOver, larger text sizes, Reduce Motion, and smallest supported iPhone screen.
- TestFlight installation over an existing development build and as a fresh installation.

## Known product risks

- Pose-detection thresholds are starting values and require testing with multiple people before public release.
- App progress is local only and is lost when the app is removed unless restored through Apple device backup behavior.
- No automated regression tests exist yet.
- App Store screenshots still need to be captured from the final release build.

## Submission gate

Do not submit to App Review until:

1. Apple Developer Program enrollment is active.
2. A Release archive validates successfully.
3. The manual device matrix above is completed without launch-critical defects.
4. TestFlight feedback has been reviewed and critical issues resolved.
5. App Store metadata, privacy answers, screenshots, age rating, availability, and agreements are complete.
