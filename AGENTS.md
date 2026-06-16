# AGENTS.md

Guidance for agents and contributors working on `@capgo/capacitor-auto`.

## Commands

- Use `bun install` for dependencies.
- Use `bun run build` for TypeScript, docgen, and Rollup output.
- Use `bun run verify` before submitting changes.
- Use `bunx cap sync` inside the example app when testing native shells.

Documentation and marketing content should keep standard `npm` / `npx` install snippets.

## Scope

This plugin provides a small bridge for CarPlay and Android Auto templated apps:

- Phone app to car display: `setRootTemplate`.
- Car display to phone app: `carAction` events.
- Host lifecycle: `connectionChanged` events.

Do not claim that this plugin mirrors the Capacitor WebView into the car display or bypasses Apple/Google car app review requirements.

## Platform Notes

- iOS code must keep both CocoaPods and Swift Package Manager support valid.
- Android code uses Kotlin and AndroidX Car App Library.
- The default Android Auto category is `IOT`; app-specific categories may need manifest overrides in the consuming app.

## Timeout Policy

- Keep CI, script, and runtime timeouts at 10 minutes or less. Use `timeout-minutes: 10` or lower in GitHub Actions and cap timeout values at `600000` ms, `600` seconds, or `10m` unless explicitly requested.
