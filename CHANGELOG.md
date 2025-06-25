# Changelog

## v0.1.1 (2025-06-25)

### Enhancements

* Automatic root layout transformation - The installer now automatically updates `root.html.heex` to use Vite helpers instead of requiring manual changes
* Improved pattern matching for various Phoenix layout formats including Phoenix 1.8+ (~p sigil) and older versions (Routes.static_path)
* Better handling of CSS assets in the layout transformation

### Bug Fixes

* Fixed issue where CSS assets were not being properly included in the layout transformation
* Added proper indentation preservation when updating layouts

## v0.1.0 (2025-06-25)

### Features

* Initial release of Vitex - Phoenix integration for Vite
* Mix tasks for installing and configuring Vite in Phoenix projects
* SSR build support
* TypeScript plugin for seamless Phoenix integration
* Hot Module Replacement (HMR) support
* Multiple entry points support
* Asset fingerprinting and manifest generation