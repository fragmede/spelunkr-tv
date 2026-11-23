# Schedule parity fixture provenance

`schedule-parity.json` contains synthetic input and expected results from the public Spelunkr engine-5 scheduler, inspected November 22, 2026.

- Source bundle: `https://spelunkr.tv/assets/index-ikeSMUkrUk.js`
- Bundle SHA-256: `d5c742be2466dbb4f06091b1f83f001403ed5b4c93ee098395ff9bad645c5b08`
- Source snapshot build marker: `de60ad5d0b`
- Synthetic epoch: `1795305600000` milliseconds
- Cases: plain, deck, block, ads, block-ads, versions, overlay
- Each case has 217 timestamps; total: 1,519.

The expected results were obtained by evaluating only the bundle's pure scheduling functions against the included synthetic models in an isolated Node process. Calls correspond to published-version construction (`Sw`/`Sb`), position resolution (`hn`), overlay sequence selection (`mb`), and bumper timing (`mR`). No website DOM, authentication, network runtime, or UI code was executed. The upstream JavaScript is not included in this repository.

Timestamps include one millisecond before, at, and after 70 successive airing boundaries; before and at the epoch; after several cycles; seven days later; and version cutovers. Unicode text exercises JavaScript UTF-16 string-length parity. Trimmed videos exercise media in-point handling. Ad pools exercise year tolerance, rotation phases, and carry between cycles. Audio exercises seeded bumper selection and decade overlay pools.

The URLs in synthetic media models are intentionally fictional. These fixtures verify scheduling; they are not fallback content or playback demonstrations.
