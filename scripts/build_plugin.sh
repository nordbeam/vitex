#!/bin/bash
set -e

echo "Building Phoenix Vite plugin..."
cd priv/vitex
npm install
npm run build

# Copy built files to priv/static/vitex
echo "Copying plugin to priv/static/vitex..."
mkdir -p ../static/vitex
cp dist/index.js ../static/vitex/index.js
cp src/dev-server-index.html ../static/vitex/dev-server-index.html

echo "Plugin built successfully!"
