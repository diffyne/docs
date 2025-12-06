# Version-Based Documentation

This documentation repository uses **branch-based versioning**. Each version of the documentation corresponds to a git branch.

## Creating a New Version

1. **Create a new branch** from the version you want to base it on:
   ```bash
   git checkout -b 1.0 main
   ```

2. **Update the documentation** for the new version and commit and push:
   ```bash
   git add .
   git commit -m "docs: update documentation for version 1.0"
   git push origin 1.0
   ```

## Updating Documentation

### For the Latest Version (main branch)

1. Make changes on the `main` branch
2. Commit and push:
   ```bash
   git checkout main
   # Make your changes
   git add .
   git commit -m "docs: update..."
   git push
   ```

### For a Specific Version

1. Checkout the version branch:
   ```bash
   git checkout 1.0
   ```

2. Make your changes and commit:
   ```bash
   git add .
   git commit -m "docs: fix typo in 1.0"
   git push origin 1.0
   ```

## Best Practices

- **Keep versions in sync**: When fixing critical bugs, consider backporting to older versions
- **Version-specific content**: Some features may only exist in certain versions - document accordingly
- **Breaking changes**: When creating a new major version, clearly document what changed
- **Default version**: The default version should typically be the latest stable release

## Deployment

The deployment repository automatically:
- Checks out each version branch
- Syncs documentation to versioned directories
- Builds the documentation site with version switching enabled

No manual intervention needed - just push to the appropriate branch!
