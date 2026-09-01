# AGENTS.md

Instructions for agents working on the LibreMuseum iOS app.

`CONTRIBUTING.md` covers setup, code style and the SwiftUI view rules — it applies here too. This
file only documents what it leaves out: server traps, invariants and compiler constraints.

## The project in one sentence

An **empty shell** SwiftUI app: it ships no text, no image, no colour. The museum name, its logo,
its palette, its exhibitions and its audio guides all come from the PocketBase backend, so that
the museum can update its content without going through the App Store again.

The server lives in `../../backend` (a separate git repository, with its own `AGENTS.md`). Its
real contract is in `backend/pb_migrations/` (schema, API rules) and
`backend/pb_hooks/lib/content.js` (field semantics) — not in `backend/docs/`, which is a guide
aimed at the museum's non-technical staff.

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
  -destination 'platform=iOS Simulator,name=iPhone 17' build

xcrun simctl install "iPhone 17" <path>/LibreMuseum.app
xcrun simctl launch  "iPhone 17" ch.bojeux.LibreMuseum
```

Any installed simulator works — run `xcrun simctl list devices available` to pick one.

The backend on the other side:

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
Configurations/ xcconfig files — signing lives here, never in the Xcode project
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

## Current state

Foundation in place and verified: network layer, SwiftData cache, lazy loading, server-driven
theme. Every screen is in place — home, settings, exhibition detail, artwork detail with its
audio guide, Map tab with floor plans and pins, Search tab, and the museum's practical-information
pages. Interface labels are localised through `Localizable.xcstrings`, English source with a
complete French translation.

The Search and Map tabs need the whole artwork index, so they call `loadEveryArtworkIfNeeded()`,
which loads exhibition by exhibition and skips whatever already matches the current fingerprint.
This is still lazy: nothing is fetched until one of those two tabs is opened.

Still to do: `SWIFT_VERSION` 5 → 6, externalising `APIConfiguration.baseURL` (a hardcoded
constant), and a `LICENSE` plus a `README.md` before the repository goes public. The floor plan
is fit to the screen with no zoom, which will not be enough for a large museum.
