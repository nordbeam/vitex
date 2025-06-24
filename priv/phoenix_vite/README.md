# Phoenix Vite Plugin

This directory contains the JavaScript/TypeScript source for the Phoenix Vite plugin.

## Development

To build the plugin:

```bash
npm install
npm run build
```

The built plugin will be in `dist/index.js`.

## Structure

- `src/` - TypeScript source files
- `dist/` - Built JavaScript output (gitignored)
- `rollup.config.js` - Build configuration

The plugin is bundled with all its dependencies (except Vite itself) into a single file that can be distributed with the Elixir package.