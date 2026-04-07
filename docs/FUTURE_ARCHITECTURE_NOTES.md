# Future Architecture Notes

## Localization

The current project keeps a stable custom localization layer in
`lib/localization/app_localizations.dart`.

Recommended future migration path:
1. Keep the current localization keys as the source of truth.
2. Move the same keys into `arb` files.
3. Introduce Flutter `intl` generation gradually.
4. Migrate one screen at a time while keeping current text output unchanged.

## Routing

The current project uses standard `Navigator` flows and keeps behavior stable.

Recommended future migration path:
1. Introduce route names for current screens.
2. Add a lightweight route configuration layer.
3. Migrate safely to `go_router` only after current flows are fully stable.
4. Keep auth gating, localization, and offline-first startup behavior unchanged during migration.
