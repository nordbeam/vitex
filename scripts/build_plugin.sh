#!/bin/bash
set -e

echo "Building Phoenix Vite plugin..."
cd priv/phoenix_vite
npm install
npm run build

# Copy built files to priv/static/phoenix_vite
echo "Copying plugin to priv/static/phoenix_vite..."
mkdir -p ../static/phoenix_vite
cp dist/index.js ../static/phoenix_vite/index.js
cp src/dev-server-index.html ../static/phoenix_vite/dev-server-index.html

echo "Plugin built successfully!"