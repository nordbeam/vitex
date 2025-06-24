# PhoenixVite

[![Hex.pm](https://img.shields.io/hexpm/v/phoenix_vite.svg)](https://hex.pm/packages/phoenix_vite)
[![Hex Docs](https://img.shields.io/badge/hex-docs-purple.svg)](https://hexdocs.pm/phoenix_vite)
[![License](https://img.shields.io/hexpm/l/phoenix_vite.svg)](https://github.com/phoenixframework/phoenix_vite/blob/main/LICENSE)

Phoenix integration for [Vite](https://vite.dev) - the next generation frontend build tool. Fast, reliable, and developer-friendly.

## Features

- ⚡️ Lightning-fast hot module replacement (HMR)
- 📦 Zero npm package installation required
- 🔧 Automatic configuration for Phoenix 1.7+ and 1.8+
- 🎨 Built-in Tailwind CSS v4 support
- ⚛️ React Fast Refresh support
- 🗂️ Proper handling of vendored libraries
- 🚀 Optimized production builds with hashed assets
- 🔄 Full page refresh on Elixir file changes
- 🔒 TLS/HTTPS support for development
- 🌐 Server-Side Rendering (SSR) support
- 🛡️ Environment checks to prevent production mistakes
- 🔌 Advanced server configuration options

## Requirements

- Elixir 1.13+
- Phoenix 1.7+
- Node.js 16+ (for running Vite)

## Installation

Add `phoenix_vite` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:phoenix_vite, "~> 0.1.0"}
  ]
end
```

Then run:

```bash
mix deps.get
mix vite.setup

# Optional: automatically update config/dev.exs
mix vite.setup --update-config
```

### What `vite.setup` does:

1. **Auto-detects Phoenix ESM modules** - Uses `phoenix.mjs` and `phoenix_live_view.esm.js` when available
2. **Auto-configures Tailwind CSS v4** - Detects and sets up @tailwindcss/vite plugin
3. **Handles vendored libraries** - CommonJS plugin automatically excludes `vendor/` directory
4. **Sets package.json type to "module"** - Required for ESM compatibility
5. **Configures all necessary aliases** - Maps Phoenix dependencies correctly
6. **Auto-detects package manager** - Works with npm, yarn, pnpm, or bun

## Configuration

After running the setup task, you'll have a `assets/vite.config.js` file. The Vite plugin is loaded directly from your Elixir dependencies:

```javascript
import { defineConfig } from 'vite'
import phoenix from '../deps/phoenix_vite/priv/static/phoenix_vite'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [
    tailwindcss(),
    phoenix({
      input: ['js/app.js', 'css/app.css'],
      publicDirectory: '../priv/static',
      buildDirectory: 'assets',
      hotFile: '../priv/hot',
      manifestPath: '../priv/static/assets/manifest.json',
      refresh: true, // Enable full page refresh on Elixir file changes
    })
  ],
})
```

Note: The Tailwind CSS plugin is automatically included if Tailwind is detected in your project.

## Development Setup

1. Update your `config/dev.exs` to use Vite as a watcher:

```elixir
config :my_app, MyAppWeb.Endpoint,
  watchers: [
    node: ["node_modules/.bin/vite", cd: Path.expand("../assets", __DIR__)]
  ]
```

2. Update your root layout template (`lib/my_app_web/components/layouts/root.html.heex`):

```heex
<!DOCTYPE html>
<html>
  <head>
    <!-- ... -->
    <%= PhoenixVite.vite_client() %>
    <%= if function_exported?(PhoenixVite, :react_refresh, 0) && Application.get_env(:my_app, :react_refresh, false) do %>
      <%= PhoenixVite.react_refresh() %>
    <% end %>
  </head>
  <body>
    <%= @inner_content %>
    <%= PhoenixVite.vite_assets("js/app.js") %>
  </body>
</html>
```

## Production Build

Add an assets build step to your deployment process:

```elixir
# In mix.exs
defp aliases do
  [
    # ...
    "assets.build": ["vite.build"],
    "assets.deploy": ["vite.build", "phx.digest"]
  ]
end
```

## Vendored Libraries

PhoenixVite correctly handles vendored JavaScript libraries in the `assets/vendor/` directory. Simply import them using relative paths:

```javascript
// In your app.js
import topbar from "../vendor/topbar"
```

The CommonJS plugin is configured to exclude the vendor directory from transformation, allowing UMD and other module formats to work correctly.

## TLS/HTTPS Support

PhoenixVite supports HTTPS in development for scenarios requiring secure connections (e.g., testing with external APIs, OAuth flows).

### Environment Variables

Configure TLS using environment variables:

```bash
# .env or export directly
VITE_DEV_SERVER_KEY=/path/to/key.pem
VITE_DEV_SERVER_CERT=/path/to/cert.pem
```

### Auto-Detection

Enable automatic certificate detection in your config:

```javascript
phoenix({
  // ... other options
  detectTls: true, // Auto-detect from mkcert/Caddy
  // or
  detectTls: 'myapp.test', // Detect for specific host
})
```

The plugin searches for certificates in:
- mkcert: `~/.local/share/mkcert/`
- Caddy: `~/.local/share/caddy/certificates/local/`
- Project: `priv/cert/`

### Generating Certificates

Using mkcert (recommended):

```bash
# Install mkcert
brew install mkcert

# Install root CA
mkcert -install

# Generate certificates
mkcert -key-file priv/cert/key.pem -cert-file priv/cert/cert.pem localhost myapp.test
```

## Server-Side Rendering (SSR)

PhoenixVite supports SSR for frameworks like React, Vue, or custom solutions.

### Configuration

```javascript
phoenix({
  input: 'js/app.js',
  ssr: 'js/ssr.js', // SSR entry point
  ssrOutputDirectory: '../priv/ssr', // SSR build output
})
```

### Building for SSR

```bash
# Client build
mix vite.build

# SSR build
mix vite build --ssr
```

### SSR Manifest

SSR builds generate a separate manifest at `priv/ssr/ssr-manifest.json` for server-side asset resolution.

## Environment Protection

PhoenixVite includes safeguards to prevent running the dev server in production environments.

### Automatic Detection

The plugin detects and blocks dev server in:
- CI environments (`CI=true`)
- Production (`MIX_ENV=prod`, `NODE_ENV=production`)
- Deployment platforms (Fly.io, Gigalixir, Heroku, Render, Railway)
- Test environments (`MIX_ENV=test`)
- Docker production (`DOCKER_ENV=production`)
- Elixir releases (`RELEASE_NAME` present)

### Bypassing Checks

For special cases (e.g., integration tests):

```bash
PHOENIX_BYPASS_ENV_CHECK=1 mix phx.server
```

## Advanced Server Configuration

### Custom HMR Configuration

```javascript
export default defineConfig({
  server: {
    hmr: {
      host: 'localhost',
      port: 5173,
      protocol: 'ws', // or 'wss' for secure WebSocket
    },
    cors: {
      // Custom CORS configuration
      origin: ['http://localhost:4000', 'http://myapp.test'],
    }
  },
  plugins: [
    phoenix({
      // plugin options...
    })
  ],
})
```

### Docker/Container Support

PhoenixVite auto-configures for container environments:

```bash
# Detected automatically
PHOENIX_DOCKER=1
# or
DOCKER_ENV=development

# Custom port
VITE_PORT=3000
```

In containers, the dev server:
- Binds to `0.0.0.0` instead of `localhost`
- Uses `strictPort: true` to ensure consistent port mapping
- Properly configures HMR for container networking

### Using PHX_HOST

Set your application URL for proper CORS and dev server configuration:

```bash
PHX_HOST=https://myapp.test mix phx.server
```

## Full Page Refresh

PhoenixVite includes automatic full page refresh when your Elixir files change. This feature is powered by the same `vite-plugin-full-reload` used in Laravel's Vite integration.

### Default Configuration

Simply set `refresh: true` in your plugin configuration to watch the default Phoenix paths:

```javascript
phoenix({
  // ... other options
  refresh: true,
})
```

This watches:
- `lib/**/*.ex` - Elixir source files
- `lib/**/*.heex` - HEEx templates  
- `lib/**/*.eex` - EEx templates
- `lib/**/*.leex` - LiveView templates
- `lib/**/*.sface` - Surface templates
- `priv/gettext/**/*.po` - Translation files

### Custom Paths

You can specify custom paths to watch:

```javascript
phoenix({
  // ... other options
  refresh: ['../lib/my_app_web/**/*.ex', '../priv/custom/**/*.json'],
})
```

### Advanced Configuration

For more control, use an object configuration:

```javascript
phoenix({
  // ... other options
  refresh: {
    paths: ['../lib/**/*.ex'],
    config: {
      delay: 100, // Delay before refresh (ms)
    }
  },
})
```

## Mix Tasks

The following Mix tasks are available:

- `mix vite` - Run any Vite command (e.g., `mix vite build`, `mix vite dev`)
- `mix vite.build` - Build production assets (runs `vite build`)
- `mix vite.ssr.build` - Build SSR assets (runs `vite build --ssr`)
- `mix vite.install` - Install npm dependencies in the assets directory
- `mix vite.setup` - Initial setup for Phoenix Vite in your project
  - `--update-config` - Auto-update config/dev.exs
  - `--ssr` - Configure SSR support
  - `--tls` - Enable TLS auto-detection
  - `--react` - Enable React Fast Refresh

## Troubleshooting

### WebSocket Connection Warning

If you see this warning in your browser console:
```
[vite] Direct websocket connection fallback. Check out https://vite.dev/config/server-options.html#server-hmr to remove the previous connection error.
```

This happens because Phoenix's development server doesn't proxy WebSocket connections for Vite's HMR. The warning is harmless - Vite automatically falls back to a direct connection and HMR continues to work.

To remove the warning, you can configure Vite to use a direct WebSocket connection from the start:

```javascript
export default defineConfig({
  server: {
    hmr: {
      port: 5173,
    }
  },
  plugins: [
    // ... your plugins
  ],
})
```

### Common Issues

**Certificate not found errors**: Run with `DEBUG=1` to see all searched paths:
```bash
DEBUG=1 mix phx.server
```

**CORS errors**: Ensure `PHX_HOST` is set to your application URL:
```bash
PHX_HOST=http://localhost:4000 mix phx.server
```

**Port conflicts**: The plugin will warn if Phoenix and Vite are on the same port. Use different ports or configure appropriately.

**WSL users**: The plugin detects WSL and provides specific configuration guidance.

## Plugin Options

The Vite plugin accepts the following options:

### Core Options

- `input` (required): Entry points to compile
- `publicDirectory`: Phoenix's public directory (default: `"priv/static"`)
- `buildDirectory`: Public subdirectory for compiled assets (default: `"assets"`)
- `hotFile`: Path to the hot file (default: `"priv/hot"`)
- `manifestPath`: Path to manifest file (default: `"priv/static/assets/manifest.json"`)
- `refresh`: Enable full page refresh on file changes (default: `false`)
  - `true` - Watches default Phoenix paths (`.ex`, `.heex`, `.eex`, `.leex`, `.sface`, `.po` files)
  - `false` - Disabled
  - `string` or `string[]` - Custom paths to watch
  - `object` - Advanced configuration with `paths` array and optional config
- `reactRefresh`: Enable React Refresh support (default: `false`)

### SSR Options

- `ssr`: SSR entry point(s) (default: uses main `input` value)
- `ssrOutputDirectory`: Directory for SSR builds (default: `"priv/ssr"`)

### Advanced Options

- `detectTls`: Auto-detect TLS certificates (default: `false`)
  - `true` - Auto-detect certificates from mkcert/Caddy
  - `false` - Disable TLS detection
  - `string` - Detect certificates for specific host
- `transformOnServe`: Function to transform code during development

## Phoenix 1.8.0-rc.3 Compatibility

PhoenixVite is fully compatible with Phoenix 1.8.0-rc.3 and newer versions. The setup task automatically:

- Detects and uses Phoenix ESM modules (`.mjs` files)
- Configures Tailwind CSS v4 with the new @tailwindcss/vite plugin
- Handles CommonJS vendor files with @rollup/plugin-commonjs
- Sets up proper aliases for Phoenix JavaScript dependencies

### Generated Configuration

For Phoenix 1.8.0-rc.3, the generated `vite.config.js` is now much simpler:

```javascript
import { defineConfig } from 'vite'
import phoenix from '../deps/phoenix_vite/priv/static/phoenix_vite'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [
    tailwindcss(),
    phoenix({
      input: ['js/app.js', 'css/app.css'],
      publicDirectory: '../priv/static',
      buildDirectory: 'assets',
      hotFile: '../priv/hot',
      manifestPath: '../priv/static/assets/manifest.json',
      refresh: true, // Enable full page refresh on Elixir file changes
    })
  ],
})
```

The Phoenix Vite plugin now automatically:
- Includes CommonJS plugin for vendor files
- Configures aliases for Phoenix JavaScript dependencies
- Detects and uses ESM versions when available
- Sets up optimizeDeps for Phoenix modules
- Handles all necessary build configuration

## How It Works

Unlike the npm package approach, this Elixir library includes the Vite plugin as part of the package. When you add `phoenix_vite` as a dependency:

1. The JavaScript plugin is pre-built and bundled in `priv/static/phoenix_vite/`
2. The `PhoenixVite` module provides helpers for your templates
3. The setup Mix task configures your project to use the plugin from deps
4. Your `assets/vite.config.js` imports the plugin directly from the Elixir dependency

This approach means:
- No need to install a separate npm package
- The Vite plugin version is tied to the Elixir library version
- Easier version management through Mix dependencies
- Plugin code is distributed through Hex.pm with the Elixir package
- All JavaScript dependencies are bundled (except Vite itself)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Setup

If you need to modify the JavaScript plugin:

1. Make changes in `priv/phoenix_vite/src/`
2. Run `./scripts/build_plugin.sh` to rebuild
3. The built files are committed to the repository
4. Test your changes with a Phoenix application

For more details, see [CLAUDE.md](CLAUDE.md) for development guidelines.

## License

Copyright (c) 2025 Phoenix Framework Contributors

Licensed under the MIT License. See [LICENSE](LICENSE) for details.
