#!/bin/bash

# Script to sync documentation to diffyne.github.io repository
# Usage: ./sync-to-docs-repo.sh [path-to-docs-repo]

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the docs repo path
DOCS_REPO="${1:-../diffyne.github.io}"

if [ ! -d "$DOCS_REPO" ]; then
    echo -e "${YELLOW}⚠️  Documentation repository not found at: $DOCS_REPO${NC}"
    echo ""
    echo "Please provide the path to the diffyne.github.io repository:"
    echo "  ./sync-to-docs-repo.sh /path/to/diffyne.github.io"
    echo ""
    echo "Or clone it first:"
    echo "  git clone https://github.com/diffyne/diffyne.github.io.git ../diffyne.github.io"
    exit 1
fi

echo -e "${BLUE}📚 Syncing documentation to: $DOCS_REPO${NC}"
echo ""

# Get the current directory (packages/docs)
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$DOCS_REPO/docs/guide"

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"

# Copy all markdown files, preserving structure
echo -e "${BLUE}Copying documentation files...${NC}"
rsync -av --delete \
    --include='*.md' \
    --include='*/' \
    --exclude='*' \
    "$CURRENT_DIR/" "$TARGET_DIR/"

echo ""
echo -e "${GREEN}✅ Documentation synced successfully!${NC}"
echo ""
echo "Next steps:"
echo "  1. cd $DOCS_REPO"
echo "  2. Review changes: git status"
echo "  3. Commit and push: git add . && git commit -m 'docs: update from main repo' && git push"
echo ""

