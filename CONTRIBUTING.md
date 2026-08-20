# Contributing to LibreMuseum iOS

Thanks for your interest. This repository holds the iOS app; the server feeding it lives in
[LibreMuseum-pocketbase](https://github.com/lebojo/LibreMuseum-pocketbase), with its own
guidelines.

The app is an **empty shell**: it ships no text, no image, no colour. The museum name, its logo,
its palette and its exhibitions all come from the server, so that the museum can update its
content without going through the App Store again. That constraint governs nearly every rule
below.

## Getting started

You need Xcode 26 or newer — the project uses the `objectVersion = 110` format, which earlier
versions cannot open. Minimum target: iOS 18.6, iPhone and iPad.

The app is useless without a server. Start one locally:

```bash
cd ../../backend && ./scripts/dev.sh --seed   # PocketBase on :8090, bilingual demo museum
```

`APIConfiguration.baseURL` points at `http://127.0.0.1:8090`, which works as is in the simulator.
On a physical device, replace it with your machine's IP — but do not commit that change.

```bash
xcodebuild -project LibreMuseum.xcodeproj -scheme LibreMuseum \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

In the simulator there is nothing to sign: the command above works untouched. To build on a
device you need a development team — it lives in a non-versioned file, never in the Xcode
project:

```bash
cp Configurations/Signing.local.example.xcconfig Configurations/Signing.local.xcconfig
```

Fill in your team id and your bundle id. `Configurations/Signing.xcconfig` includes it with
`#include?`, so its absence breaks nothing, and `Signing.local.xcconfig` is ignored by git: nobody
will ever see your configuration in a diff.

**Set signing in that file, not in the Signing & Capabilities tab.** Xcode would write
`DEVELOPMENT_TEAM` straight back into `project.pbxproj`, which is exactly what this setup avoids.
If a diff on the Xcode project shows `DEVELOPMENT_TEAM`, that is the sign to strip it before
committing.

## Layout

```
Core/          API, Repository, Sync, Media, Localization, Theme — no views here
Models/Data/   DTO (mirror of the server JSON) + Entities (@Model SwiftData)
Models/UI/     flat models suffixed `UI` + Mapping/
Views/         one folder per view that has subviews; Components/ for the reusable ones
Extensions/    Color and Font styles
Configurations/ xcconfig files — signing lives here
```

Xcode groups are synchronised with the file system: a file added to the right folder is picked up
without touching `project.pbxproj`.

**Primary views query SwiftData through `@Query`; subviews only ever receive `*UI` models.** A
subview must never see an entity — the mapping happens once and for all in `EntityToUI`, which
decides the language and the empty values.

## Code style

Everything is written in English: code, comments, documentation, commit messages. The only French
in this repository lives in `Localizable.xcstrings`, as a translation.

**Code is not commented, it is named.** No file header, no `///` on every member, no decorative
`// MARK:`. If a line needs an explanation, the name is what should change:
`container.stringOrEmpty(.name)` and not `container.string(.name)`,
`cachedOrDownloadedData(for:)` and not `data(for:)`. The name carries the fallback value, the
error policy, the caching strategy. What does not fit in a name — a server trap, an architectural
decision — is documented in `AGENTS.md`, not in the file.

Prefer value types, in this order: `enum` first (state, configuration, variants), then `struct`,
`class` only when reference semantics are unavoidable, `actor` for shared mutable state. Do not
hesitate to nest an `enum` inside a view for state that only makes sense there.

### SwiftUI views

**No `@ViewBuilder` on a member, and no function or computed property returning a view** —
including `Text`. Only `body` returns a view. Everything else becomes a full subview in the
parent view's folder, or a component in `Views/Components/` if it is reusable. Conditional
branching happens inside the extracted subview's `body`, or through an `enum` the parent computes
and passes in. Computed properties returning a `String` or an `enum` remain welcome.

Declaration order, one blank line between each group:

```swift
@AppStorage private var …
@Environment private var …        // @Query right after, with the data sources
@State private var …
@FocusState private var …
@Binding var …
let …
private var … { }                 // computed
var body: some View { }           // always last
```

Colours and fonts go through the `Color+Museum` and `Font+Museum` extensions — never a hex
literal or a `Font.system` call inside a view. Every visual resource lives in an `.xcassets`.
Prefer native components before writing one.

### Interface strings

Interface labels are localised, with **English as the source language**. Write the English
literal directly in the view — `Text("Space used")` — and Xcode extracts it into
`Localizable.xcstrings`, where the French translation is added.

Outside of a view, where the type is a plain `String` and not a `LocalizedStringKey`, wrap it:
`String(localized: "Never")`. A parameter meant to be displayed must be typed
`LocalizedStringKey`, otherwise the literal at the call site is never extracted and stays
untranslated.

## Rules not to break

These invariants are not preferences; breaking them breaks the product.

**No hardcoded content text.** Museum name, titles, colours: everything comes from the server. A
content literal in the code defeats the very principle of the project. Interface labels are the
exception: they belong to the app and go through the string catalog.

**Never persist an absolute media URL** — only the relative `/api/files/…` path, prefixed at
request time. A domain change must not expire the media already cached on phones.

**Do not use `AsyncImage`**: it bypasses `MediaStore`, hence the SwiftData cache — a new download
on every appearance, and nothing at all offline. Always `RemoteImageView`.

**Always handle the three empties**: missing `museum`, empty `translations`, `""` file path. All
three are reachable in production.

**Decode tolerating absence.** The server schema is append-only: a missing field must never fail
a whole record. Use `stringOrEmpty`, `intOrZero`, and ignore unknown keys.

`AGENTS.md` covers the rest — PocketBase API traps, version-fingerprint invalidation, `MainActor`
isolation by default. **Read it before touching `Core/` or a DTO**: it documents hard-to-read
compiler errors and server behaviours that have already cost time.

## Commits

**A single line, never a body.** No description, no bullet list, no `Co-Authored-By`, no link.
The message stands on its own.

[Conventional Commits](https://www.conventionalcommits.org) format, description in the
imperative, no trailing period:

```
feat(home): show cached exhibitions before the network answers
fix(media): keep the cache after a content update
refactor(views): extract the empty states into subviews
```

One commit = one coherent change. Split rather than lump together.

## Pull requests

Work on a branch, never directly on `main`. Before opening the PR:

- `xcodebuild … build` passes with no error and no new warning;
- no stray change is committed — `DEVELOPMENT_TEAM` back in `project.pbxproj`, `baseURL` pointed
  at your machine, `xcuserdata/`;
- a visual change comes with a screenshot or a recording.

Describe the **why** in the PR: the *what* is readable in the diff. If you change a behaviour
documented in `AGENTS.md`, update that file in the same batch.

## Reporting a problem

Open an issue stating the iOS version, the device or simulator, and the version of the server on
the other side (visible under Settings → Content version). A content bug often comes from the
backend: check the raw response with `curl` before concluding it is the app.

## AI-assisted contributions

They are welcome. `AGENTS.md` is written for that — point your agent at it. You remain
responsible for the code you propose: read it, run it, and make sure it follows the rules above,
in particular the absence of decorative comments and hardcoded content.
