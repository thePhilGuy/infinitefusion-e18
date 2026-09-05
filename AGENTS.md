# Working on this fork

## Purpose

This fork hosts extensions to Pokémon Infinite Fusion in
`Data/Scripts/998_ZZZ_Extensions`.
Keep upstream game files untouched by default so upstream changes can be brought
in without losing or repeatedly reapplying local modifications.

## Extension design

- Keep custom behavior in small, focused Ruby files in
  `Data/Scripts/998_ZZZ_Extensions` unless the user requests a different location.
- The late-loading directory name is intentional: extensions load after the
  classes they modify and before `999_Main` starts the game.
- Prefer `Module#prepend`, `super`, targeted method interception, and small
  extension registries or callbacks. Let upstream code continue doing its work.
- Find the narrowest useful hook before replacing a method. Copying an entire
  upstream method into a prepended module still duplicates upstream behavior and
  creates maintenance work; do not use that as the default approach.
- Scope temporary behavior to the relevant object or operation. Restore temporary
  state with `ensure`, including when the wrapped operation raises an exception.
- Preserve upstream arguments, return values, and behavior outside the intended
  extension. Document any dependency on a particular upstream layout or contract.
- Read the existing extensions for patterns: `010_Unfusing.rb` temporarily changes
  one Pokémon's behavior; `002_Menu.rb` adds an extensible menu registry;
  `021_RemoteDayCare.rb` wraps state changes and dispatches custom callbacks;
  `030_SummaryIVs.rb` intercepts drawing commands around the original stats page.
- Apply the same approach to changes in startup or download behavior: implement
  a localized extension rather than editing upstream startup scripts.

## Communication and context

- Treat the user as familiar with this game's script ordering, main entrypoint,
  and monkey-patching techniques. Explain relevant discoveries and tradeoffs
  without repeatedly teaching fundamentals they have already demonstrated.
- Interpret shorthand using the established task and architecture. In the setup
  discussion, copying files from the previous install meant reusing assets/data
  while retaining the extension-based source here, not blindly copying the whole
  install over the fork.
- In that same discussion, disabling the "new version check" meant stopping the
  startup download of new settings, not merely hiding the update announcement.
  Keep that context without assuming all future network-related requests mean
  disabling every download.
- Carry established intent forward. Clarify when a distinction materially affects
  the requested action and cannot reasonably be resolved from context.

## Preservation and Git

- Preserve user-authored work, including staged changes. Do not stage, unstage,
  commit, reset, or otherwise alter Git state on your own initiative.
- Follow the user's global operating constitution. Explicit requests authorize
  the particular Git action requested; they are not blanket authorization for
  other Git mutations. Do not repeatedly ask the user to authorize an action they
  have already explicitly requested, apart from required tool permissions.
- Ask before destructive or difficult-to-recover actions. Keep the previous game
  installation intact unless the user explicitly requests changes there.
- Distinguish source changes from downloaded settings, caches, generated icons,
  and line-ending/index noise when reviewing a working tree.
- Report validation accurately: source inspection and diff checks are not an
  in-game test. Ruby extension edits do not require rebuilding the game.
