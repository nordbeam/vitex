# Changelog

## v0.2.5 (2025-09-13)

### Features

* Added support for Phoenix LiveView 1.0 colocated hooks
  * Automatically configures Vite resolve.alias for `phoenix-colocated` imports
  * Passes `PHOENIX_BUILD_PATH` environment variable with `Mix.Project.build_path()`
  * Works with both system package managers and Elixir-managed Bun
  * Enables imports like `import {hooks} from "phoenix-colocated/my_app"`
  * No additional configuration needed - works out of the box after `mix vitex.install`

### Technical Improvements

* Updated vite.config.js generation to always include path import for resolve aliases
* Enhanced BunIntegration to pass build path environment variable to all Bun profiles
* Ensured phoenix-colocated alias is added even without TypeScript or shadcn options

## v0.2.4 (2025-07-01)

### Bug Fixes

* Fixed Bun integration to use the Elixir bun package's module-based approach
  * Dev watcher now uses `{Bun, :install_and_run, [:dev, []]}` instead of direct executable calls
  * Added proper `dev` and `build` profiles to the Bun configuration
  * Updated mix aliases to use `bun build` task instead of `cmd _build/bun run build`
  * This ensures compatibility with how the Elixir bun package manages the executable lifecycle

## v0.2.3 (2025-07-01)

### Bug Fixes

* Fixed shadcn/ui initialization command to use `--cwd` flag instead of `cd`
  * This prevents the "Would you like to start a new project?" prompt
  * shadcn init now correctly runs in the assets directory
  * Updated all related tests to match the new command format

## v0.2.0 (2025-07-01)

### Features

* Added comprehensive shadcn/ui integration support
  * New `--shadcn` flag to enable shadcn/ui component library
  * New `--base-color` option to customize the theme color (neutral, gray, zinc, stone, slate)
  * Automatic configuration of Vite path aliases for component imports (@, @/components, @/lib, @/hooks)
  * Automatic initialization of shadcn/ui after npm/bun install
  * Support for both npm and bun package managers

### Enhancements

* Added validation to ensure shadcn/ui requirements are met (TypeScript + React/Inertia)
* Comprehensive test coverage for shadcn/ui integration
* Clear installation notices with usage examples
* Updated documentation with shadcn/ui setup and usage instructions

### Technical Improvements

* Made `maybe_setup_shadcn` and `print_next_steps` functions public for better testability
* Fixed pattern matching in notice functions to work with keyword lists
* Updated test helpers to handle both tuple and map task formats

## v0.1.5 (2025-07-01)

### Enhancements

* Added `--bun` option to use the Elixir bun package for JavaScript runtime and package management
* Refactored Bun integration into a dedicated `BunIntegration` module for better maintainability
* Improved Phoenix JS library resolution in the Vite plugin with better documentation
* Added comprehensive documentation explaining the difference between system package managers and Elixir-managed Bun

### Improvements

* Extracted Phoenix alias resolution logic into a separate function for clarity
* Fixed notice pattern matching to properly handle keyword lists
* Updated tests to be more flexible with formatting differences
* Better validation and error messages for Bun setup

## v0.1.4 (2025-07-01)

### Bug Fixes

* Fixed repository URL in mix.exs

## v0.1.3 (2025-07-01)

### Enhancements

* Enhanced Inertia.js installer with complete out-of-the-box setup
* Automatic PageController creation with example inertia action
* New dedicated inertia pipeline with proper Inertia.Plug configuration
* Added /inertia route that demonstrates a working Inertia integration
* Beautiful example Home component with Tailwind CSS detection
* React Refresh support added to inertia_root layout
* Improved pipeline configuration to use proper web module references

### Bug Fixes

* Fixed Inertia router pipeline setup to properly reference the web module
* Fixed React Refresh inclusion in Inertia layouts

## v0.1.2 (2025-06-25)

### Bug Fixes

* Fixed TypeScript file extension issue - When using `--inertia --typescript`, the installer now correctly creates `Home.tsx` instead of `Home.jsx`
* Fixed Inertia root layout creation - The installer now properly creates `inertia_root.html.heex` in the layouts directory when using `--inertia`

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