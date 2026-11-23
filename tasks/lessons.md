# Project lessons

## November 23, 2026 — Keep Apple account identities separate

- Individual and organization Apple Developer Program enrollments have separate Team IDs, even when the same person manages both. A personal account can have a paid individual enrollment; do not confuse it with Xcode's free Personal Team.
- Verify both the signed-in Apple Account and selected developer team before investigating company membership or agreement status. An accepted agreement in the personal account does not establish the company's status.
- Use a separate browser session for the company account instead of continuing company administration in the personal session. Determine the Account Holder from the company's actual user roles; do not infer that role from an email address or a signing certificate.
- An Admin label in Xcode does not exclude the Account Holder role. The company account's App Store Connect profile explicitly lists both Account Holder and Admin.

## November 23, 2026 — Keep publication notes free of account details

- Keep reusable setup lessons in the public repository; omit Apple login emails and personal device names. Check historical commits as well as the current tree before first publication.
- Preserve private local development history on a local-only backup branch when publishing a clean initial snapshot. Push only the intended public branch.
