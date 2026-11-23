# Spelunkr broadcast integration

Inspected on November 22, 2026. This is an unofficial native client of [Spelunkr](https://spelunkr.tv/). The app reads the same published broadcast data as the website and plays original Internet Archive media. It does not require a Spelunkr account, Supabase key, or a custom backend.

## Public resources

| Resource | Address / format |
| --- | --- |
| Live lineup | `https://data.spelunkr.tv/lineup.json` |
| Website snapshot fallback | `https://spelunkr.tv/broadcast/lineup.json` |
| Channel manifests | `manifests/{channel}/v{version}.json`, relative to either broadcast base |
| Platform interstitials | The immutable `platform` path in the channel manifest |
| Optional program descriptions | The `details` path in each lineup version pointer |
| Video | `https://archive.org/download/{identifier}/{encoded filename}` |
| Thumbnail | `https://archive.org/services/img/{identifier}` |
| Media attribution | `https://archive.org/details/{identifier}` |
| Bumper audio | The lineup's `audioBase`, currently `https://audio.spelunkr.tv/bumps/` |

The live CDN returned HTTP 403 to command-line and macOS test requests during development, while the tvOS simulator successfully loaded the live catalog with 37 channels. The website's own fallback returned 36 channels, with a snapshot generated on November 20, 2026 at 20:51:17 UTC. The client tries the live address first, then the published fallback, and exposes which source supplied the lineup. A snapshot can continue calculating the older published schedule, but it cannot reveal changes published after that snapshot. It must not be represented as a verified current live lineup.

HTTP errors, invalid JSON, and HTML challenge pages trigger fallback. Cancellation does not trigger a new fallback request. Versioned resources are cached in memory; the lineup is requested fresh. Paths are restricted to relative broadcast resource names. No bundled production catalog or media copy is included.

## Models and scheduling

The observed lineup format is engine 5. A channel includes `id`, `name`, `description`, `color`, `dial`, `family`, and version pointers. Each pointer supplies the version number, manifest path, epoch in milliseconds, effective time, and starting video index. The channel logos are pixel matrices, not ordinary image URLs, so `logoURL` is deliberately nil.

`CatalogClient.loadCatalog()` provides channel metadata and snapshot provenance. `loadSchedule(for:)` loads the versioned manifests and shared platform interstitials. `ChannelSchedule` validates the manifest format and provides synchronous, thread-safe `airing(at:)` and `upcoming(at:count:)`. Upcoming listings exclude the current airing and interstitials.

The schedule implementation matches the website's observed engine-5 rules:

- The newest eligible version takes effect at its published millisecond boundary. Its epoch need not be midnight. A future version can truncate the current program or interstitial.
- Cycle zero begins at `startIndex`; later cycles begin at the first video. Before the epoch, full earlier cycles are calculated backward.
- Manifest video duration is **already trimmed**. `inS` is added to playback position and is not subtracted from duration a second time.
- Station breaks, black gaps, title cards, and period advertisements occupy real schedule time. Omitting them would shift every later program.
- Channel bump decks use the site's signed UTF-16 string hash and Mulberry32 random generator, retain recent-deck state across cycles, and honor UTC seasonal date ranges. Platform bumps are selected independently.
- Text duration is `max(2500, 1500 + UTF16Length × 55)` milliseconds. Intro, first-slide hold, black gaps, and platform transitions use the website's timing constants.
- Hour blocks insert up-next cards with deterministic music-sting durations. Advertising uses the site's rotation phases, year tolerance, recent-ad carry, channel phase, optional decade tolerance, and off-air exclusions.
- Audio-overlay programs select a shuffled decade pool with deterministic track positions. Bumper tracks, offsets, attribution, and fade levels are returned through `Airing.audio`; text timing is returned through `Airing.currentSlide`.

The core never downloads or executes JavaScript at runtime. It uses native Swift scheduling and normal HTTPS requests. Unsupported future schedule engine versions produce a useful update error instead of silently calculating the wrong broadcast.

## Validation

`swift test` covers upstream parity, trimmed media offsets, URL encoding, invalid duration rejection, future listings, live/snapshot provenance, challenge fallback, cancellation, and forwarding a custom HTTPS audio base into scheduled playback. Missing or non-HTTPS audio bases retain the default. The checked-in synthetic fixture compares 1,519 timestamps across plain playlists, shuffled bump decks, hour blocks, ads, blocks with ads, version replacement, and audio overlays. It checks millisecond boundaries, media URLs/offsets, slide selection, and audio track selection/offsets.

The expected results were generated by evaluating the pure scheduling functions of the website's published `index-ikeSMUkrUk.js` bundle against synthetic input. The website bundle itself is not distributed with this project. The fixture includes no actual video or audio. See its adjacent provenance file.

The opt-in integration check was also run successfully:

```sh
SPELUNKR_LIVE_TESTS=1 swift test --filter LiveIntegrationTests
```

It loaded and resolved all 36 real channels using URLSession and validated future listings and HTTPS media addresses. This is network/model evidence, not evidence that every Archive file can play or that Apple TV hardware has been tested.

## Presentation limits

The native frontend can render timed text station breaks, play their music, and preserve their duration. Decorative embedded bump videos and the site's separate translated subtitle sidecars are not implemented by this core. Original media subtitle tracks remain available to AVKit when present. Program descriptions and film credits in the optional details documents are not loaded yet.

The site can replace unpublished endpoint contracts or remove Archive assets. Keep failures retryable, refresh the lineup periodically, and retain the source attribution. Availability in the Internet Archive is not a statement that every item is public domain; the project does not redistribute media or claim its ownership.

Primary references: [Spelunkr](https://spelunkr.tv/), [published lineup fallback](https://spelunkr.tv/broadcast/lineup.json), [Apple AVPlayer](https://developer.apple.com/documentation/avfoundation/avplayer/), [Apple tvOS playback](https://developer.apple.com/documentation/avkit/customizing-the-tvos-playback-experience).
