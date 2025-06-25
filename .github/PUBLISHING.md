# Publishing to Hex.pm

This document describes how Vitex is automatically published to Hex.pm.

## Automated Publishing Process

Vitex uses GitHub Actions to automatically publish new versions to Hex.pm whenever changes are pushed to the main branch.

### Prerequisites

1. **Hex.pm Account**: You need an account on [Hex.pm](https://hex.pm)
2. **Package Ownership**: You must be an owner of the `vitex` package
3. **API Key**: Generate a Hex.pm API key for publishing

### Setting up the Hex API Key

1. Log in to your Hex.pm account
2. Go to your [dashboard](https://hex.pm/dashboard)
3. Click on "API keys" in the sidebar
4. Click "Generate new key"
5. Give it a name like "GitHub Actions - Vitex"
6. Select the following permissions:
   - `api:read` (to check existing versions)
   - `api:write` (to publish packages)
7. Copy the generated key

### Adding the Key to GitHub

1. Go to your repository settings on GitHub
2. Navigate to "Secrets and variables" → "Actions"
3. Click "New repository secret"
4. Name: `HEX_API_KEY`
5. Value: Paste the API key from Hex.pm
6. Click "Add secret"

## Publishing Workflow

The publishing process is handled by `.github/workflows/publish.yml`:

1. **Trigger**: Git tags matching `v*.*.*` pattern (e.g., `v0.1.0`, `v1.2.3`)
2. **Build Plugin**: Compiles the JavaScript plugin in `priv/vitex`
3. **Run Tests**: Ensures all tests pass
4. **Verify Version**: Ensures tag version matches mix.exs version
5. **Publish**: Publishes to Hex.pm
6. **Create Release**: Creates a GitHub release with changelog

## Version Management

### Release Process

Vitex uses semantic versioning and tag-based releases. Here's the recommended workflow:

#### Option 1: Using the Prepare Release Workflow (Recommended)

1. Run the "Prepare Release" workflow:
   ```
   Actions → Prepare Release → Run workflow → Enter version (e.g., 0.1.1)
   ```

2. This creates a PR that:
   - Updates version in `mix.exs`
   - Updates version in README examples
   - Updates CHANGELOG.md with date

3. Review and merge the PR

4. Create and push a tag to trigger publishing:
   ```bash
   git checkout main
   git pull origin main
   git tag v0.1.1
   git push origin v0.1.1
   ```

#### Option 2: Manual Release Process

1. Update version in `mix.exs`:
   ```elixir
   @version "0.1.1"
   ```

2. Update README examples:
   ```elixir
   {:vitex, "~> 0.1.1"}
   ```

3. Update CHANGELOG.md:
   - Move items from "Unreleased" to a new version section
   - Add the release date

4. Commit changes:
   ```bash
   git add .
   git commit -m "Prepare release v0.1.1"
   git push origin main
   ```

5. Create and push tag:
   ```bash
   git tag v0.1.1
   git push origin v0.1.1
   ```

The tag push will automatically trigger the publishing workflow.

### Version Guidelines

- **Patch releases** (0.1.x): Bug fixes, documentation updates
- **Minor releases** (0.x.0): New features, backward-compatible changes
- **Major releases** (x.0.0): Breaking changes (after 1.0.0)

## Important Notes

1. **Plugin Build**: The JavaScript plugin MUST be built before publishing
2. **Version Sync**: The git tag version must match the version in mix.exs
3. **Test Matrix**: PRs are tested against multiple Elixir/OTP versions
4. **Formatting**: Code must be properly formatted (`mix format`)
5. **No Auto-increment**: Versions are NOT automatically incremented - releases are intentional

## Troubleshooting

### Build Failures

If the publish workflow fails:

1. Check the GitHub Actions logs
2. Ensure the JavaScript plugin builds correctly:
   ```bash
   cd priv/vitex
   npm ci
   npm run build
   ```

3. Verify the built file exists:
   ```bash
   ls -la priv/static/vitex/index.js
   ```

### Tag/Version Mismatch

If you see "Tag version does not match mix.exs version":
- Ensure the tag matches the version in mix.exs
- Delete the incorrect tag: `git push --delete origin v0.1.0`
- Create correct tag: `git tag v0.1.1 && git push origin v0.1.1`

### API Key Issues

If you see authentication errors:
- Verify the `HEX_API_KEY` secret is set correctly
- Ensure the API key has write permissions
- Generate a new key if needed

## Local Publishing (Not Recommended)

For emergency releases, you can publish locally:

```bash
# Build the plugin first
cd priv/vitex
npm ci
npm run build
cd ../..

# Set your Hex API key
export HEX_API_KEY=your_api_key_here

# Publish
mix hex.publish

# Create git tag
git tag v0.1.1
git push origin v0.1.1
```

**Note**: Always prefer the automated workflow to ensure consistency.