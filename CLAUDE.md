# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PhoenixVite is an Elixir library that provides seamless integration between Phoenix Framework and Vite. It bundles a pre-built JavaScript plugin within the Elixir package, eliminating the need for a separate npm package.

## Key Architecture

### Dual-Language Structure
- **Elixir Library** (`lib/`): Provides Phoenix template helpers and Mix tasks
- **JavaScript Plugin** (`priv/phoenix_vite/`): TypeScript Vite plugin that handles asset compilation and HMR

### Plugin Distribution Model
The JavaScript plugin is pre-built and committed to the repository. This allows:
- Distribution through Hex.pm without requiring npm
- Version synchronization between Elixir and JavaScript components
- Simplified dependency management for end users

### Key Components

1. **PhoenixVite Module** (`lib/phoenix_vite.ex`): Main module providing template helpers:
   - `vite_assets/1` - Generates script/link tags for entries
   - `vite_client/0` - Includes Vite dev client for HMR
   - `react_refresh/0` - Enables React Fast Refresh
   - `asset_path/1` - Returns dev server or production asset URLs

2. **Mix Tasks** (`lib/mix/tasks/`):
   - `vite.ex` - Generic Vite command runner
   - `vite.setup.ex` - Initial project setup
   - `vite.build.ex` - Production build
   - `vite.install.ex` - npm dependency installation

3. **JavaScript Plugin** (`priv/phoenix_vite/src/index.ts`):
   - Handles manifest generation for production builds
   - Creates hot file for dev server detection
   - Configures full page reload on Elixir file changes
   - Manages React Refresh integration

## Development Commands

### Plugin Development
```bash
# Rebuild the JavaScript plugin after changes
./scripts/build_plugin.sh

# Or manually:
cd priv/phoenix_vite
npm install
npm run build
```

### Testing
```bash
# Run Elixir tests
mix test

# Build documentation
mix docs
```

### Library Development Workflow
1. Modify TypeScript plugin code in `priv/phoenix_vite/src/`
2. Run `./scripts/build_plugin.sh` to rebuild
3. Built files in `priv/phoenix_vite/dist/` must be committed
4. Test integration with a Phoenix application

## Important Technical Details

### Hot File Communication
- Dev server writes its URL to `priv/hot` file
- Elixir code reads this file to detect dev server status
- Automatically switches between dev and production asset loading

### Manifest Handling
- Production builds generate `manifest.json` with hashed filenames
- Manifest maps original entries to built files with dependencies
- Supports CSS extraction and module preloading

### Package Manager Detection
Mix tasks automatically detect and use the appropriate package manager (npm, yarn, pnpm, bun) based on lock files present in the assets directory.

### Asset Paths
- Public directory: `priv/static` (Phoenix convention)
- Build output: `priv/static/assets/`
- Manifest location: `priv/static/assets/manifest.json`
- Hot file: `priv/hot`

## Common Development Tasks

### Adding New Mix Task
1. Create new module in `lib/mix/tasks/vite.{name}.ex`
2. Use `Mix.Task` behaviour
3. Implement `run/1` function
4. Follow existing task patterns for package manager detection

### Updating Plugin Dependencies
1. Modify `priv/phoenix_vite/package.json`
2. Run `cd priv/phoenix_vite && npm install`
3. Rebuild plugin with `npm run build`
4. Commit both `package-lock.json` and built files

### Testing Plugin Changes
1. Create or use a test Phoenix app
2. Add local dependency: `{:phoenix_vite, path: "../phoenix_vite"}`
3. Run `mix deps.get` and `mix vite.setup`
4. Test both development and production modes