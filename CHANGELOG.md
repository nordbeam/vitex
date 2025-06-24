# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Automatic package manager detection (npm, yarn, pnpm, bun)
- Improved documentation with badges and better organization
- Development guidelines in CLAUDE.md

### Changed
- Reorganized README structure for better clarity
- Updated plugin configuration examples

### Removed
- Unnecessary package-lock.json from root directory

## [0.1.0] - 2025-01-21

### Added
- Initial release
- Phoenix integration for Vite bundler
- JavaScript plugin included as part of Elixir package
- Mix tasks: `vite`, `vite.setup`, `vite.build`, `vite.install`
- Support for hot module replacement (HMR) in development
- Production asset manifest handling
- React Refresh support
- Automatic detection of Phoenix ESM modules
- Built-in Tailwind CSS v4 configuration
- CommonJS plugin for vendored libraries
- Full page refresh on Elixir file changes
- Helper functions: `vite_assets/1`, `vite_client/0`, `react_refresh/0`, `asset_path/1`

[Unreleased]: https://github.com/phoenixframework/phoenix_vite/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/phoenixframework/phoenix_vite/releases/tag/v0.1.0