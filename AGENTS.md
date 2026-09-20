# AGENTS.md

Instructions for agents working on the LibreMuseum iOS app.

`CONTRIBUTING.md` covers setup, code style and the SwiftUI view rules — it applies here too. This
file only documents what it leaves out: server traps, invariants and compiler constraints.

## The project in one sentence

An **empty shell** SwiftUI app: it ships no text, no image, no colour. The museum name, its logo,
its palette, its exhibitions and its audio guides all come from the PocketBase backend, so that
the museum can update its content without going through the App Store again.

The server is [LibreMuseum-pocketbase](https://github.com/lebojo/LibreMuseum-pocketbase), a
separate git repository with its own `AGENTS.md`, cloned here at `../../backend`. Its real
contract is in `pb_migrations/` (schema, API rules) and `pb_hooks/lib/content.js` (field
semantics) — not in `docs/`, which is a guide aimed at the museum's non-technical staff.

## Code style

**Code is not commented, it is named.** No file header, no `///` on every member, no decorative
`// MARK:`. If a line needs an explanation, the name is what should change.

That is why the code says `container.stringOrEmpty(.name)` and not `container.string(.name)`,
`runIgnoringNetworkFailure { }` and not `run { }`, `cachedOrDownloadedData(for:)` and not
`data(for:)`, `existingSymbolName(_:)` and not `validSymbol(_:)`. The name carries the fallback
value, the error policy, the caching strategy.

What **cannot** fit in a name — a server trap, a compiler constraint, an architectural decision —
is documented here, not in the file.

Everything is written in English: code, comments, documentation, commit messages. The only French
in this repository lives in `Localizable.xcstrings`, as a translation.

Commits: a single line, [Conventional Commits](https://www.conventionalcommits.org), description
in the imperative, no body, no `Co-Authored-By`.

## Commands

```bash
export DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer   # xcode-select points at the CLT

xcodebuild -project LibreMuseum.xcodeproj -scheme LibreMuseum \
  -destination 'generic/platform=iOS Simulator' build

xcrun simctl install "<simulator>" <path>/LibreMuseum.app
xcrun simctl launch  "<simulator>" ch.bojeux.LibreMuseum
```

`generic/platform=iOS Simulator` builds without naming a device; to install and launch, pick one
from `xcrun simctl list devices available` — the names change with every Xcode release, so do not
hardcode one here.

The backend on the other side, in its own clone:

```bash
cd ../../backend && ./scripts/test.sh    # DISPOSABLE database on :8091 — use it for every test
cd ../../backend && ./scripts/dev.sh     # working database on :8090
```

**Every test that modifies content goes through `scripts/test.sh`**, never through `pb_data/`. It
recreates `.test-data/` from scratch and both instances run side by side on different ports.

## Architecture

```
Core/          API, Repository, Sync, Media, Localization, Theme — no views
Models/Data/   DTO (mirror of the server JSON) + Entities (@Model SwiftData)
Models/UI/     flat models suffixed `UI` + Mapping/
Views/         one folder per view that has subviews; Components/ for the reusable ones
Extensions/    Color and Font styles
Configurations/ xcconfig files and the Info.plist they feed — never in the Xcode project
```

**Primary views query SwiftData through `@Query`; subviews only ever receive `*UI` models.** A
subview must never see an entity: the mapping happens in `EntityToUI`, which decides the language
and the empty values once and for all.

**Content loads lazily**, screen by screen, through the PocketBase REST API. `@Query` shows the
cache instantly, `.task` triggers the network, which repopulates SwiftData and updates the view.
The visitor never waits in front of an empty screen — inside a museum, the network is the
exception.

`/api/app/bundle` is **not** used: it returns everything in one block, the opposite of lazy
loading.

## PocketBase REST API traps verified on this project

These cost time; do not rediscover them.

**Dates come out as `"2026-09-15 00:00:00.000Z"` — a space, not a `T`.** `ISO8601DateFormatter`
rejects them. Everything goes through `PocketBaseDate`. A missing date is `""`, never `null`.
(The bundle normalised to ISO 8601: do not trust what it shows.)

**File fields only contain the file name**, not the path. Hence `id` and `collectionName` decoded
on every DTO carrying media, and `APIConfiguration.mediaPath`.

**`museum.location` is a geoPoint `{lon, lat}`**, not two flat fields — the bundle flattened
them, the REST API does not.

**`museum.default_lang` and `translation.language` are relation ids, not codes.** The bundle
resolved them; here the app does. That is why `loadShell` loads languages **first**: without the
`language` table, the importer cannot attach any translation.

**`artwork.code` sorts lexicographically**: `1, 10, 11, 2, 3`. Never use it as a number.

**API rules already filter `published`** server-side. The app does not have to redo it. An
unpublished artwork becomes a `404`, which is not a failure but a deletion to propagate.

## Invariants not to break

**Never persist an absolute media URL** — only the relative `/api/files/…` path, prefixed at
request time. This is an explicit backend invariant: a domain change must not expire the media
cached on phones.

**No hardcoded content text.** Museum name, titles, colours: everything comes from the server. A
content literal in the code defeats the very principle of the project. Interface labels are the
exception — they belong to the app and go through `Localizable.xcstrings`.

**The `/api/app/version` fingerprint drives invalidation.** Every entity stores its
`fetchedVersion`; if it differs from the current fingerprint it is stale — but stays on screen
while reloading. Stale is not invalid.

**The media cache survives a content update.** `MediaAssetEntity` is spared by invalidation: the
path contains the record id and the file name, which a server-side replacement regenerates.
Unchanged path = same bytes.

**Lists exclude heavy fields through `fields`.** `artwork_translation.text` reaches 500,000
characters. The `includesFullText` parameter exists so that a translation loaded in a list
context does not overwrite a full text already cached, and `ArtworkEntity.fullTextVersion` —
stamped only by `loadArtworkDetail` — is what `needsArtworkFullText` compares. It is
deliberately distinct from the shared `fetchedVersion`: stamping that one in a list pass would
certify a text the pass never downloaded, and the description would stay empty on screen until
the visitor purged the cache.

**A record deleted server-side must be pruned locally, translations included.** The museum
deleting a translation and re-entering it produces a new id, and the stale row keeps its language
code — `LanguageResolver.pick` returns the *first* match over a relationship whose order is not
guaranteed, so the orphan wins and the screen stays empty. The three importers prune their
translations, which turns `isCompleteSet` into a real contract rather than a hint: pruning
against a truncated page would delete live content. That is why every list goes through
`everyPage`; a lone `perPage: 500` request used to truncate a large museum in silence.

**The server's `UNIQUE (parent, language)` is mirrored on import.** `dropSuperseded` deletes a
sibling holding the same language code under a different id. Pruning already covers the complete
loads, but this also protects a partial one, where it does not run — two rows can never race for
the same slot.

**A locked exhibition is decided once, in `EntityToUI.ticketAccess`.** Every screen builds a
`TicketAccess` from its exhibitions and the `TicketStore`, then carries it into the `*UI` models;
no subview ever reads the store. That is what keeps the padlock identical in the exhibition list,
in Search and on the Map, and it is why `ArtworkLinkView` — not each call site — decides between a
`NavigationLink` and the unlock sheet. An exhibition that requires a ticket but carries an empty
`unlock_code` is deliberately **not** locked: no scan and no typed code could ever match it, so
locking it would strand the visitor on a screen with no way forward.

**Scanned tickets live in `UserDefaults`, not in SwiftData.** `purgeAll` empties the content cache
from the settings screen; a visitor who has paid must not lose their unlock by freeing some space.
`TicketStore` also wakes up once at the earliest deadline, because nothing else would notice a
ticket expiring while its screen is open. A non-positive validity falls back to 24 hours rather
than to `.distantFuture`: `ticket_validity_hours` is decoded with `intOrZero`, so a museum that
never published it — or whose record has not synced yet — would otherwise turn every paid ticket
into a lifetime one.

**The padlock discourages, it does not protect.** The artworks stay readable through the public
REST API, as they must be for an app with no visitor account. `unlock_code` is compared on the
device, so it travels in the `exhibition` response: do not present the lock as a protection, and
do not put anything behind it that would actually harm the museum if read.

**A locked artwork shows its teaser and nothing else.** `ArtworkUI` keeps the real title so that
unlocking reveals it without a refetch, which makes every display path a leak waiting to happen:
Search matches a locked artwork on its code alone, never on its title or its artist, and the map
pin announces "Locked artwork" to VoiceOver instead of `pin.title`. Route a new display through
`LockedTitle.teaser`, never through the raw title.

**Do not use `AsyncImage`**: it would bypass `MediaStore`, hence the SwiftData cache — a new
download on every appearance, and nothing at all offline. Always `RemoteImageView`. Audio obeys
the same rule: `AudioGuidePlayer` is fed `Data` by `MediaStore`, never a remote `URL`.

**A server colour is never applied to text without checking it stays legible.** The demo museum
ships `primary_color = #1B1B1F`, invisible on a dark background. `theme.legiblePrimary(on:)`
falls back to the system label colour when the relative luminance is too close to the current
scheme. Use it for text; `theme.accent` is safe as is.

**Text imported from HTML carries UIKit attributes.** `NSAttributedString`'s HTML importer sets a
black foreground and a Times font in the *UIKit* attribute scope, which survives
`AttributedString.foregroundColor = nil` (SwiftUI scope) — black on black in dark mode.
`HTMLTextView` clears the UIKit scope and re-maps bold/italic traits onto the museum font.

**`pos_x = 0, pos_y = 0` means "not placed", not "top-left corner".** The fields are optional and
decoded with `doubleOrZero`, so an artwork without coordinates is indistinguishable from one at
the corner. `ArtworkEntity.hasMapPosition` treats that pair as unplaced and no pin is drawn.

**Do not position map pins from a `GeometryReader` nested in a `List` row**: it reports a rect
that is not the image's, and every pin comes out uniformly offset. `FloorPlanView` measures the
image with `onGeometryChange` and lays the pins out in an `overlay(alignment: .topLeading)`.

**Always handle the three empties**: missing `museum`, empty `translations`, `""` file path. All
three are reachable in production.

## Project constraints

**`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`.** Any unannotated type is isolated to the main
thread. Value types that cross the network actor or the import actor must be marked
`nonisolated` — otherwise their `Decodable` conformance is isolated and can no longer satisfy the
`Sendable` requirement of off-main decoding. The resulting compiler error is hard to read: think
of it before creating a DTO or a protocol in `Core/`.

**Siri's voice is not reachable from `AVSpeechSynthesizer`.** On macOS the
`com.apple.siri.natural.*` voices are listed and do synthesise; inside the iOS simulator
`speechVoices()` returns none of them, and Apple exposes no API to request one. The best a third
party gets is the highest `quality` voice the visitor has installed — `.premium` and `.enhanced`
are downloads made in Settings → Accessibility → Spoken Content → Voices, so a stock
device only offers `.default`. Do not chase a Siri identifier; rank what `speechVoices()` returns.

**`AVSpeechSynthesisVoice(language:)` returns the compact voice, and guesses the region badly.**
For `"fr"` it answers `fr-CA` Amélie. `ReadAloudSpeaker.voiceMatching` therefore never calls it
first: it filters `speechVoices()` by base language, then ranks by quality, then by the region
`Locale.Language.maximalIdentifier` expects (`fr` → `fr-Latn-FR`, `pt` → `pt-Latn-BR`), then by
the device's own region.

**`ReadAloudSpeaker` polls `AVSpeechSynthesizer.isSpeaking` instead of using its delegate.**
`AVSpeechSynthesizerDelegate` is not main-actor isolated, so a `@MainActor` conformance warns
under default `MainActor` isolation and would fail under Swift 6. A 200 ms ticker — the same one
`AudioGuidePlayer` already uses to follow progress — detects the end of the utterance without the
conformance. Two consequences: play/pause branches on the speaker's own `Phase`, never on
`isPaused`, because `pauseSpeaking(at: .word)` only takes effect at the next word boundary and a
fast second tap would otherwise pause twice; and the ticker tolerates `isSpeaking == false` until
`speechStartDeadline`, because the first utterance of a session loads its voice asset before
speech actually starts. That window is the `.preparing` phase, shown as a spinner — nothing is
pre-generated, `speak(_:)` streams as it goes.

**The backend schema is append-only by policy.** Decode tolerating missing fields
(`stringOrEmpty`, `intOrZero`…) and ignore unknown keys. A missing field must never fail a whole
record.

**PocketBase is pre-1.0**, with no backwards-compatibility guarantee. Verify an API assumption
with `curl` before writing code against it.

**`Application Support` does not exist in a fresh container** and SwiftData does not create it:
`LibreMuseumApp` creates it before opening the store, otherwise the app crashes on first launch.

**SVG is allowed** for `museum.logo` and `floor.map`. `?thumb=` does not apply to it and
`UIImage` cannot decode it: `mediaURL` omits the thumbnail for a `.svg`, and `RemoteImageView`
falls back cleanly.

**Signing is not in the Xcode project.** `DEVELOPMENT_TEAM`, `PRODUCT_BUNDLE_IDENTIFIER` and
`CODE_SIGN_STYLE` come from `Configurations/Signing.xcconfig`, which optionally includes a
non-versioned `Signing.local.xcconfig`. A build setting written into `project.pbxproj` overrides
the xcconfig silently: never put them back there.

**The server address is not in Swift either.** `Configurations/Server.xcconfig` defines
`LIBREMUSEUM_SERVER_URL`, `Configurations/Info.plist` carries it into the bundle as
`ServerBaseURL`, and `APIConfiguration.serverURLFromInfoPlist` reads it once. `Base.xcconfig`
is what the target points at; it includes `Signing.xcconfig` and `Server.xcconfig`, each with
its own optional `*.local.xcconfig`. Three traps: in an xcconfig `//` opens a comment, so the
value is written `http:/$()/127.0.0.1:8090`; `INFOPLIST_KEY_<name>` only works for keys Xcode
knows, which is why a custom key needs a real `INFOPLIST_FILE` — it merges with
`GENERATE_INFOPLIST_FILE`, both coexist; and only the scheme and host are used, since every
request replaces the whole path.

## Current state

Foundation in place and verified: network layer, SwiftData cache, lazy loading, server-driven
theme. Every screen is in place — home, settings, exhibition detail, artwork detail with its
audio guide — or, when the museum published none, a read-aloud button that speaks the description
with `AVSpeechSynthesizer` under an "Autogenerated" badge — Map tab with floor plans and pins,
Search tab, and the museum's practical-information pages. Interface labels are localised through
`Localizable.xcstrings`, English source with a complete French translation.

The Search and Map tabs need the whole artwork index, so they call `loadEveryArtworkIfNeeded()`,
which loads exhibition by exhibition and skips whatever already matches the current fingerprint.
This is still lazy: nothing is fetched until one of those two tabs is opened.

Paying exhibitions are in place: `requires_ticket` locks the artwork list behind a QR code scanned with `CodeScanner`, `museum.ticket_validity_hours` says for how long, and the description of the exhibition stays readable without a ticket.

Still to do: `SWIFT_VERSION` 5 → 6. The app target already compiles clean in Swift 6 mode —
the only errors come from `CodeScanner`, whose `AVCapture` delegate conformances cross into
main-actor-isolated code, and they only appear when the version is forced globally on the command
line instead of on the target. The floor plan is fit to the screen with no zoom, which will not be
enough for a large museum.
