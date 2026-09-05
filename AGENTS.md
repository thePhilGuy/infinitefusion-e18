# Infinite Fusion extensions

This fork is an extension layer for Pokémon Infinite Fusion. Keep local behavior
in `Data/Scripts/998_zzz_extensions` so upstream updates remain easy to integrate.
The user understands Ruby monkey patching, script load order, and the main
entrypoint; collaborate at that level.

## Design approach

- Use lowercase `snake_case` for extension directories, filenames, new methods,
  and local variables; retain numeric load-order prefixes. Use `PascalCase` for
  classes/modules and `SCREAMING_SNAKE_CASE` for constants. Overrides and calls
  retain the exact upstream API spelling, including names such as `pbUnfuse`.
- Build small, focused extensions around upstream behavior. Prefer
  `Module#prepend`, `super`, narrow interception points, and simple callback or
  command registries. Upstream methods remain responsible for their existing work.
- Find a hook that expresses the requested change with minimal duplication.
  A whole-method replacement is a fallback when narrower hooks cannot preserve
  the intended behavior; explain that tradeoff when it arises.
- Scope temporary overrides to the relevant object or operation, restore state
  with `ensure`, and preserve upstream arguments and return values. Record
  dependencies on particular layouts or method contracts where they matter.
- Use the existing extensions as examples: `010_unfusing.rb` wraps one Pokémon's
  behavior, `002_menu.rb` provides a command registry, `021_remote_day_care.rb`
  dispatches callbacks around state changes, and `030_summary_ivs.rb` decorates
  text commands while the original stats page renders.
- Keep startup and download customizations in this same extension layer.
  `001_settings.rb` provides `FREEZE_REMOTE_SETTINGS` as an easy toggle.

## Workflow and shared context

- The `998_zzz_extensions` name deliberately places extensions after upstream
  classes and before `999_Main`. The game evaluates these Ruby files at launch;
  extension edits need no build step.
- Preserve upstream source as the default maintenance strategy. Reusing files
  from the previous install means bringing over relevant assets/data while
  retaining this fork's source and extensions.
- In the setup discussion, "freeze the version check" meant freezing the startup
  settings download. Version announcements, Pokédex downloads, and sprite
  downloads are distinct behaviors; use the requested scope in each task.
- Evaluate working-tree changes with the game's runtime in mind: downloaded
  settings, caches, generated icons, and line-ending/index differences can all
  appear alongside source changes. Many assets are tracked; use the actual ignore
  rules to determine which are excluded.
- Use the previous installation as a reference and asset source. Preserve its
  contents while developing here unless changes there are explicitly requested.
- Choose validation that answers the relevant question. Distinguish source-level
  checks from execution in the game, and communicate limitations when they affect
  confidence in the result.

Apply the global collaboration and Git authorization preferences here. Keep
project guidance focused on durable architecture and useful working context.
