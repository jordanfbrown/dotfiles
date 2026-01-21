---
name: nexus-publishing
description: Publish packages to Nexus registry from front-end-monorepo. Use when publishing npm packages. Covers branch previews, version bumping, and changelog requirements.
---

# Nexus Package Publishing (front-end-monorepo)

## Branch Publishing (Preview Packages)

Branches automatically publish preview packages when pushed:

**Format:** `@wealthsimple/package-name@<version>-<branchName>`

**Example:**
- Branch: `feature/new-button`
- Package version: `1.2.3`
- Published as: `@wealthsimple/patchwork@1.2.3-feature-new-button`

**Usage in consuming repo:**
```bash
# Install preview package
npm install @wealthsimple/patchwork@1.2.3-feature-new-button
```

No manual action needed - CI handles preview publishing automatically.

## Main Branch Publishing (Release)

To publish a new version to main:

### 1. Update version in package.json

```json
{
  "name": "@wealthsimple/my-package",
  "version": "1.2.4"
}
```

Follow semver:
- **patch** (1.2.3 -> 1.2.4): Bug fixes, no API changes
- **minor** (1.2.3 -> 1.3.0): New features, backwards compatible
- **major** (1.2.3 -> 2.0.0): Breaking changes

### 2. Add CHANGELOG.md entry

```markdown
## [1.2.4] - 2024-01-15

### Fixed
- Fixed button alignment issue in Safari

### Added
- New `variant` prop for Button component
```

### 3. Merge to main

CI will automatically publish the new version after merge.

## Dependencies in Publishable Packages

**Use `peerDependencies`** for monorepo packages, not `dependencies`:

```json
{
  "name": "@wealthsimple/my-publishable-package",
  "peerDependencies": {
    "@wealthsimple/patchwork": ">=2.0.0",
    "react": ">=18.0.0"
  },
  "devDependencies": {
    "@wealthsimple/patchwork": "^2.1.0",
    "react": "^18.2.0"
  }
}
```

**Why peerDependencies:**
- Avoids bundling duplicate copies
- Consumer controls the version
- Smaller package size

## Checking if Package is Publishable

Look in `project.json`:

```json
{
  "name": "my-package",
  "targets": {
    "publish": {
      "executor": "@wealthsimple/ws-nx:publish"
    }
  }
}
```

If no `publish` target, package is internal only.

## Common Issues

### Version already exists
```
Error: Cannot publish over existing version
```
Bump version number - can't republish same version.

### Missing CHANGELOG
CI may require CHANGELOG entry for version bumps on publishable packages.

### Peer dependency mismatch
Consumer sees warning about unmet peer dependency - update peer dependency range to be more permissive.

## Commands

```bash
# Check current published versions
npm view @wealthsimple/package-name versions

# See package.json version
cat libs/path/to/package/package.json | jq '.version'

# Test build before publishing
pnpm nx run <package-name>:build
```
