
<div align="center">
<h1 align="center">
Vitex
</h1>
<img src="https://raw.githubusercontent.com/nordbeam/vitex/main/logo.svg" width="200px"/>

[![Hex.pm](https://img.shields.io/hexpm/v/vitex.svg)](https://hex.pm/packages/vitex)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/vitex/)
[![License](https://img.shields.io/hexpm/l/vitex.svg)](https://github.com/nordbeam/vitex/blob/main/LICENSE)
[![Elixir Version](https://img.shields.io/badge/elixir-~%3E%201.14-purple)](https://elixir-lang.org/)
[![Phoenix Version](https://img.shields.io/badge/phoenix-~%3E%201.8-orange)](https://www.phoenixframework.org/)

**Phoenix integration for Vite - a fast frontend build tool**

[Features](#features) • [Installation](#installation) • [Usage](#usage) • [Configuration](#configuration) • [Documentation](#documentation)

</div>

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Installation](#installation)
  - [Automatic Installation (Recommended)](#automatic-installation-recommended)
  - [Manual Installation](#manual-installation)
- [Usage](#usage)
  - [Basic Usage](#basic-usage)
  - [React Support](#react-support)
  - [TypeScript Support](#typescript-support)
  - [Inertia.js Integration](#inertiajs-integration)
  - [shadcn/ui Integration](#shadcnui-integration)
  - [Server-Side Rendering (SSR)](#server-side-rendering-ssr)
- [Configuration](#configuration)
  - [Vite Configuration](#vite-configuration)
  - [TLS/HTTPS Setup](#tlshttps-setup)
  - [Environment Variables](#environment-variables)
- [Mix Tasks](#mix-tasks)
- [Helper Functions](#helper-functions)
- [Common Use Cases](#common-use-cases)
  - [Single Page Applications](#single-page-applications)
  - [Tailwind CSS](#tailwind-css)
  - [Multiple Entry Points](#multiple-entry-points)
  - [Code Splitting](#code-splitting)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Introduction

Vitex brings the power of [Vite](https://vitejs.dev/) to Phoenix applications, replacing the traditional esbuild setup with a modern, fast, and feature-rich development experience. With Vitex, you get instant hot module replacement (HMR), optimized production builds, and seamless integration with modern frontend frameworks.

### Why Vitex?

- **⚡ Lightning Fast HMR**: See your changes instantly without page reloads
- **🔧 Zero Configuration**: Works out of the box with sensible defaults
- **🎯 Framework Agnostic**: Support for React, Vue, Svelte, and vanilla JavaScript
- **📦 Optimized Builds**: Automatic code splitting and tree shaking
- **🔥 Modern Development**: ES modules, TypeScript, JSX, and CSS modules support
- **🚀 Production Ready**: Efficient bundling with rollup under the hood

## Features

- ✅ **Hot Module Replacement (HMR)** - Instant updates without losing state
- ✅ **React Fast Refresh** - Preserve component state during development
- ✅ **TypeScript Support** - First-class TypeScript support with zero config
- ✅ **Inertia.js Integration** - Build SPAs with server-side routing
- ✅ **SSR Support** - Server-side rendering for better SEO and performance
- ✅ **Asset Optimization** - Automatic minification, tree-shaking, and code splitting
- ✅ **CSS Processing** - PostCSS, CSS modules, and preprocessor support
- ✅ **Static Asset Handling** - Import images, fonts, and other assets
- ✅ **Manifest Generation** - Production-ready asset manifests with hashing
- ✅ **Multiple Entry Points** - Support for multiple JavaScript/CSS entry files
- ✅ **Phoenix LiveView Compatible** - Works seamlessly with LiveView
- ✅ **Automatic TLS Detection** - Detects and uses local certificates for HTTPS

## Installation

### Automatic Installation (Recommended)

The easiest way to add Vitex to your Phoenix application is using the automatic installer with [Igniter](https://github.com/ash-project/igniter):

1. Use the [Igniter](https://hexdocs.pm/igniter) installer.

```sh
mix archive.install hex igniter_new
```

3. Run the installer:

```bash
# Basic installation
mix igniter.install vitex

# With React support
mix igniter.install vitex --react

# With TypeScript
mix igniter.install vitex --typescript

# With Inertia.js (includes React)
mix igniter.install vitex --inertia

# With shadcn/ui components (requires TypeScript and React/Inertia)
mix igniter.install vitex --typescript --react --shadcn

# With custom shadcn theme color
mix igniter.install vitex --typescript --react --shadcn --base-color slate

# With Bun as package manager (Elixir-managed)
mix igniter.install vitex --bun

# With all features
mix igniter.install vitex --react --typescript --tls --bun
```

#### Installation Options

- `--react` - Enable React with Fast Refresh support
- `--typescript` - Enable TypeScript support  
- `--inertia` - Enable Inertia.js for building SPAs (automatically includes React)
- `--shadcn` - Enable shadcn/ui component library (requires TypeScript and React/Inertia)
- `--base-color` - Set shadcn/ui theme color: neutral (default), gray, zinc, stone, or slate
- `--bun` - Use Bun as the package manager via the Elixir bun package
- `--tls` - Enable automatic TLS certificate detection for HTTPS development
- `--ssr` - Enable Server-Side Rendering support

The installer will:
- Create `vite.config.js` with appropriate settings
- Update `package.json` with necessary dependencies
- Configure Phoenix watchers for development
- Update your root layout to use Vite helpers
- Set up asset files for your chosen configuration

### Manual Installation

If you prefer manual setup or don't want to use Igniter:

1. Add Vitex to your dependencies:

```elixir
# mix.exs
def deps do
  [
    {:vitex, "~> 0.2"}
  ]
end
```

2. Create `assets/vite.config.js`:

```javascript
import { defineConfig } from 'vite'
import phoenix from '../deps/vitex/priv/static/vitex'

export default defineConfig({
  plugins: [
    phoenix({
      input: ['js/app.js', 'css/app.css'],
      publicDirectory: '../priv/static',
      buildDirectory: 'assets',
      hotFile: '../priv/hot',
      manifestPath: '../priv/static/assets/manifest.json',
      refresh: true
    })
  ],
})
```

3. Update `assets/package.json`:

```json
{
  "name": "your_app",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build"
  },
  "dependencies": {
    "vite": "^7.0.0"
  }
}
```

4. Update your Phoenix configuration:

```elixir
# config/dev.exs
config :your_app, YourAppWeb.Endpoint,
  watchers: [
    node: ["node_modules/.bin/vite", cd: "assets"]
  ]
```

5. Update your root layout:

```heex
# lib/your_app_web/components/layouts/root.html.heex
<!DOCTYPE html>
<html>
  <head>
    <!-- ... -->
    <%= Vitex.vite_client() %>
    <%= Vitex.vite_assets("css/app.css") %>
    <%= Vitex.vite_assets("js/app.js") %>
  </head>
  <!-- ... -->
</html>
```

## Usage

### Basic Usage

After installation, Vitex provides helper functions for your templates:

```heex
<!-- In your root layout -->
<%= Vitex.vite_client() %> <!-- Enables HMR in development -->
<%= Vitex.vite_assets("js/app.js") %>
<%= Vitex.vite_assets("css/app.css") %>
```

Start your Phoenix server:

```bash
mix phx.server
```

Vite will automatically start in development mode with HMR enabled.

### React Support

To use React with Fast Refresh:

```heex
<!-- In your layout -->
<%= Vitex.react_refresh() %> <!-- Add before your app scripts -->
<%= Vitex.vite_assets("js/app.jsx") %>
```

Configure Vite for React:

```javascript
// vite.config.js
import { defineConfig } from 'vite'
import phoenix from '../deps/vitex/priv/static/vitex'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [
    react(),
    phoenix({
      input: ['js/app.jsx', 'css/app.css'],
      reactRefresh: true,
      // ... other options
    })
  ],
})
```

### TypeScript Support

Vitex supports TypeScript out of the box:

```javascript
// vite.config.js
export default defineConfig({
  plugins: [
    phoenix({
      input: ['js/app.ts', 'css/app.css'],
      // ... other options
    })
  ],
})
```

Create `assets/tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "lib": ["ES2020", "DOM"],
    "jsx": "react-jsx",
    "strict": true,
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true
  },
  "include": ["js/**/*"]
}
```

### Inertia.js Integration

For building SPAs with Inertia.js:

```elixir
# In your controller
def index(conn, _params) do
  conn
  |> assign_prop(:users, Users.list_users())
  |> render_inertia("Users/Index")
end
```

```jsx
// assets/js/pages/Users/Index.jsx
import React from 'react'

export default function UsersIndex({ users }) {
  return (
    <div>
      <h1>Users</h1>
      {users.map(user => (
        <div key={user.id}>{user.name}</div>
      ))}
    </div>
  )
}
```

### shadcn/ui Integration

Vitex supports [shadcn/ui](https://ui.shadcn.com/), a collection of reusable components built with Radix UI and Tailwind CSS.

**Requirements:**
- TypeScript must be enabled (`--typescript`)
- Either React (`--react`) or Inertia.js (`--inertia`) must be enabled

```bash
# Install with shadcn/ui
mix igniter.install vitex --typescript --react --shadcn

# With custom theme color (neutral, gray, zinc, stone, slate)
mix igniter.install vitex --typescript --react --shadcn --base-color slate
```

The installer will:
- Configure path aliases for component imports
- Initialize shadcn/ui with your chosen theme
- Set up CSS variables for theming
- Create the components directory structure

**Adding Components:**

```bash
cd assets && npx shadcn@latest add button
cd assets && npx shadcn@latest add card dialog
```

**Usage in your React components:**

```tsx
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"

export default function MyComponent() {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Welcome</CardTitle>
      </CardHeader>
      <CardContent>
        <Button variant="outline">Click me</Button>
      </CardContent>
    </Card>
  )
}
```

**Path Aliases:**
- `@` - Root JavaScript directory (`assets/js`)
- `@/components` - Component directory
- `@/lib` - Utility functions
- `@/hooks` - Custom React hooks

### Server-Side Rendering (SSR)

Enable SSR in your Vite config:

```javascript
// vite.config.js
export default defineConfig({
  plugins: [
    phoenix({
      input: ['js/app.js', 'css/app.css'],
      ssr: 'js/ssr.js',
      // ... other options
    })
  ],
})
```

Build your SSR bundle:

```bash
mix vitex.ssr.build
```

## Configuration

### Vite Configuration

The Phoenix Vite plugin accepts the following options:

```javascript
phoenix({
  // Entry files (required)
  input: ['js/app.js', 'css/app.css'],

  // Output directories
  publicDirectory: '../priv/static',
  buildDirectory: 'assets',

  // Development server
  hotFile: '../priv/hot',
  detectTls: true, // Auto-detect local certificates

  // Build options
  manifestPath: '../priv/static/assets/manifest.json',

  // Features
  refresh: true, // Enable full page reload on blade/heex changes
  reactRefresh: true, // Enable React Fast Refresh

  // SSR
  ssr: 'js/ssr.js', // SSR entry point
})
```

### TLS/HTTPS Setup

Vitex can automatically detect local TLS certificates. Enable with:

```javascript
phoenix({
  detectTls: true,
  // ... other options
})
```

For manual TLS configuration, see the [TLS setup guide](priv/vitex/docs/tls-setup.md).

### Environment Variables

Vitex respects the following environment variables:

- `NODE_ENV` - Set to "production" for production builds
- `VITE_PORT` - Custom Vite dev server port
- `VITE_DEV_SERVER_KEY` - Path to TLS key file
- `VITE_DEV_SERVER_CERT` - Path to TLS certificate file

### Package Manager Support

Vitex supports two approaches for package management:

#### System Package Managers (Default)
By default, Vitex detects and uses whatever package manager is installed on your system (npm, pnpm, yarn, or bun). The installer will:
- Detect your system package manager automatically
- Configure watchers to use `node_modules/.bin/vite`
- Run `npm install` (or equivalent) during setup

#### Elixir-Managed Bun (--bun flag)
When you use the `--bun` flag, Vitex integrates with the [Elixir bun package](https://hex.pm/packages/bun):
- Adds `{:bun, "~> 1.5", runtime: Mix.env() == :dev}` to your dependencies
- Downloads and manages the bun executable at `_build/bun`
- Uses Bun workspaces for Phoenix JS dependencies
- Configures watchers to use `{Bun, :install_and_run, [:dev, []]}`
- Mix tasks handle the bun installation lifecycle

Example with Bun:
```bash
# Install with Bun support
mix igniter.install vitex --bun

# After installation, these commands are available:
mix bun.install          # Install bun executable
mix bun assets           # Install npm dependencies
mix bun build            # Build assets for production
```

## Mix Tasks

Vitex provides several Mix tasks:

### `mix vitex`
Run Vite commands directly:

```bash
mix vitex build         # Build for production
mix vitex dev          # Start dev server
mix vitex preview      # Preview production build
```

### `mix vitex.install`
Install and configure Vitex (requires Igniter):

```bash
mix vitex.install [options]

Options:
  --react        Enable React support
  --typescript   Enable TypeScript
  --inertia      Enable Inertia.js (includes React)
  --shadcn       Enable shadcn/ui components (requires TypeScript + React/Inertia)
  --base-color   Base color for shadcn/ui theme (neutral, gray, zinc, stone, slate)
  --tls          Enable TLS auto-detection
  --ssr          Enable SSR support
```

### `mix vitex.build`
Build assets for production:

```bash
mix vitex.build
```

### `mix vitex.ssr.build`
Build SSR bundle:

```bash
mix vitex.ssr.build
```

## Helper Functions

Vitex provides the following helper functions:

### `Vitex.vite_assets/1`
Generate script/link tags for entries:

```elixir
Vitex.vite_assets("js/app.js")
# In dev: <script type="module" src="http://localhost:5173/js/app.js"></script>
# In prod: <script type="module" src="/assets/app.123abc.js"></script>

Vitex.vite_assets(["js/app.js", "js/admin.js"])
# Generates tags for multiple entries
```

### `Vitex.vite_client/0`
Enable HMR in development:

```elixir
Vitex.vite_client()
# In dev: <script type="module" src="http://localhost:5173/@vite/client"></script>
# In prod: <!-- nothing -->
```

### `Vitex.react_refresh/0`
Enable React Fast Refresh:

```elixir
Vitex.react_refresh()
# Injects React Refresh runtime in development
```

### `Vitex.asset_path/1`
Get the URL for an asset:

```elixir
Vitex.asset_path("images/logo.png")
# In dev: "http://localhost:5173/images/logo.png"
# In prod: "/assets/logo.123abc.png"
```

### `Vitex.hmr_enabled?/0`
Check if HMR is active:

```elixir
if Vitex.hmr_enabled?() do
  # Development-specific code
end
```

## Common Use Cases

### Single Page Applications

Build SPAs with client-side routing:

```javascript
// vite.config.js
export default defineConfig({
  plugins: [
    phoenix({
      input: ['js/app.jsx'],
      // ... other options
    })
  ],
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom', 'react-router-dom']
        }
      }
    }
  }
})
```

### Tailwind CSS

Vitex works great with Tailwind CSS v4:

```javascript
// vite.config.js
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [
    tailwindcss(),
    phoenix({
      // ... options
    })
  ],
})
```

### Multiple Entry Points

Support multiple sections of your app:

```javascript
phoenix({
  input: [
    'js/app.js',
    'js/admin.js',
    'css/app.css',
    'css/admin.css'
  ],
  // ... other options
})
```

### Code Splitting

Vite automatically handles code splitting for dynamic imports:

```javascript
// Lazy load a component
const AdminPanel = lazy(() => import('./components/AdminPanel'))

// Dynamic import based on route
if (route === '/admin') {
  const { initAdmin } = await import('./admin')
  initAdmin()
}
```

## Troubleshooting

### Common Issues

**Vite dev server not starting**
- Check that Node.js is installed (v18+ recommended)
- Ensure `assets/package.json` exists
- Run `npm install` in the assets directory

**Assets not loading in production**
- Run `mix vitex.build` before deploying
- Check that manifest.json is generated in `priv/static/assets/`
- Ensure `priv/static` is included in your release

**HMR not working**
- Verify Vite dev server is running (check `priv/hot` file)
- Check browser console for connection errors
- Ensure `Vitex.vite_client()` is included in your layout

**TypeScript errors**
- Vite doesn't type-check by default (for speed)
- Use your editor's TypeScript integration
- Run `tsc --noEmit` for full type checking

### Getting Help

- 📚 [Documentation](https://hexdocs.pm/vitex)
- 💬 [Phoenix Forum](https://elixirforum.com/c/phoenix-forum)
- 🐛 [Issue Tracker](https://github.com/nordbeam/vitex/issues)

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Setup

```bash
# Clone the repo
git clone https://github.com/nordbeam/vitex.git
cd vitex

# Install dependencies
mix deps.get
cd priv/vitex && npm install

# Run tests
mix test

# Build the Vite plugin
cd priv/vitex && npm run build
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Copyright (c) 2025 Nordbeam Team

---

<div align="center">
Made with ❤️ by the Nordbeam Team
</div>
