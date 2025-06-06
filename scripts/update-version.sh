#!/bin/bash
# filepath: scripts/update-version.sh

set -e  # Exit immediately if a command exits with a non-zero status

# Colors for better output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}MR4GH Automations Version Updater${NC}"
echo -e "${BLUE}======================================${NC}"

# Ensure we're in the repository root
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"

# Array to store all detected versions
declare -a PACKAGE_VERSIONS
declare -a WORKFLOW_VERSIONS
declare -a ALL_VERSIONS

echo -e "\n${BLUE}Scanning for current versions...${NC}"

# Get versions from package.json files
echo -e "${BLUE}Package versions:${NC}"
while IFS= read -r PACKAGE_FILE; do
    VERSION=$(grep '"version"' "$PACKAGE_FILE" | sed 's/.*"version": "\(.*\)",/\1/')
    PACKAGE_NAME=$(basename $(dirname "$PACKAGE_FILE"))
    PACKAGE_VERSIONS+=("$VERSION")
    ALL_VERSIONS+=("$VERSION")
    echo -e "  ${YELLOW}$PACKAGE_NAME:${NC} $VERSION"
done < <(find actions -name "package.json" -type f)

# Get versions from workflow files
echo -e "\n${BLUE}Workflow versions:${NC}"
while IFS= read -r WORKFLOW_FILE; do
    VERSION=$(grep "WORKFLOW_VERSION:" "$WORKFLOW_FILE" | sed "s/.*WORKFLOW_VERSION: '\(.*\)'.*/\1/")
    WORKFLOW_NAME=$(basename "$WORKFLOW_FILE" .yml)
    WORKFLOW_VERSIONS+=("$VERSION")
    ALL_VERSIONS+=("$VERSION")
    echo -e "  ${YELLOW}$WORKFLOW_NAME:${NC} $VERSION"
done < <(find workflows -name "*.yml" -type f)

# Check if all versions are the same
FIRST_VERSION=${ALL_VERSIONS[0]}
VERSIONS_MATCH=true
for VERSION in "${ALL_VERSIONS[@]}"; do
    if [[ "$VERSION" != "$FIRST_VERSION" ]]; then
        VERSIONS_MATCH=false
        break
    fi
done

if [[ "$VERSIONS_MATCH" == true ]]; then
    echo -e "\n${GREEN}All versions are in sync:${NC} $FIRST_VERSION"
    CURRENT_VERSION=$FIRST_VERSION
else
    echo -e "\n${RED}Warning: Version mismatch detected!${NC}"
    echo -e "Would you like to:"
    echo -e "  ${YELLOW}1)${NC} Use the highest version found"
    echo -e "  ${YELLOW}2)${NC} Use a specific version"
    echo -e "  ${YELLOW}3)${NC} Exit and resolve manually"
    
    read -p "Enter option [1-3]: " VERSION_CHOICE
    
    case $VERSION_CHOICE in
        1)
            # Find the highest version
            CURRENT_VERSION=""
            for VERSION in "${ALL_VERSIONS[@]}"; do
                if [[ -z "$CURRENT_VERSION" ]] || [[ $(echo "$VERSION" | awk -F. '{printf "%d%03d%03d", $1, $2, $3}') > $(echo "$CURRENT_VERSION" | awk -F. '{printf "%d%03d%03d", $1, $2, $3}') ]]; then
                    CURRENT_VERSION=$VERSION
                fi
            done
            echo -e "${GREEN}Using highest version:${NC} $CURRENT_VERSION"
            ;;
        2)
            echo -e "Available versions:"
            UNIQUE_VERSIONS=($(echo "${ALL_VERSIONS[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
            for i in "${!UNIQUE_VERSIONS[@]}"; do
                echo -e "  ${YELLOW}$((i+1))${NC}) ${UNIQUE_VERSIONS[$i]}"
            done
            read -p "Select version number [1-${#UNIQUE_VERSIONS[@]}]: " VERSION_INDEX
            CURRENT_VERSION=${UNIQUE_VERSIONS[$((VERSION_INDEX-1))]}
            echo -e "${GREEN}Using selected version:${NC} $CURRENT_VERSION"
            ;;
        3)
            echo -e "${RED}Exiting. Please synchronize versions manually before running this script.${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Exiting.${NC}"
            exit 1
            ;;
    esac
fi

# Prompt for changes made
echo -e "\n${BLUE}Please describe the changes made in this update:${NC}"
read -e CHANGES

# Prompt for version update type
echo -e "\n${BLUE}What kind of update is this?${NC}"
echo -e "  ${YELLOW}1)${NC} Major (breaking changes)"
echo -e "  ${YELLOW}2)${NC} Minor (new features, non-breaking)"
echo -e "  ${YELLOW}3)${NC} Patch (bug fixes, minor changes)"
read -p "Enter option [1-3]: " VERSION_TYPE

# Parse the current version
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# Calculate new version
case $VERSION_TYPE in
  1)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    UPDATE_TYPE="major"
    ;;
  2)
    MINOR=$((MINOR + 1))
    PATCH=0
    UPDATE_TYPE="minor"
    ;;
  3)
    PATCH=$((PATCH + 1))
    UPDATE_TYPE="patch"
    ;;
  *)
    echo -e "${RED}Invalid option. Exiting.${NC}"
    exit 1
    ;;
esac

# Create the new version string
NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
echo -e "\n${BLUE}New version:${NC} ${GREEN}$NEW_VERSION${NC}"

# Confirm before proceeding
read -p "Proceed with update? (y/n): " CONFIRM
if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
  echo -e "${RED}Update canceled.${NC}"
  exit 0
fi

echo -e "\n${BLUE}Updating package.json files...${NC}"
# Find all package.json files in the actions directory
find actions -name "package.json" -type f | while read -r PACKAGE_FILE; do
  echo "Updating $PACKAGE_FILE"
  # Using sed to update the version line in package.json
  sed -i.bak "s/\"version\": \".*\"/\"version\": \"$NEW_VERSION\"/" "$PACKAGE_FILE"
  rm "${PACKAGE_FILE}.bak"  # Remove backup file
done

echo -e "\n${BLUE}Updating workflow files...${NC}"
# Find all workflow files
find workflows -name "*.yml" -type f | while read -r WORKFLOW_FILE; do
  echo "Updating $WORKFLOW_FILE"
  # Using sed to update the WORKFLOW_VERSION line in workflow files
  sed -i.bak "s/WORKFLOW_VERSION: '.*'/WORKFLOW_VERSION: '$NEW_VERSION'/" "$WORKFLOW_FILE"
  rm "${WORKFLOW_FILE}.bak"  # Remove backup file
done

# Commit changes
echo -e "\n${BLUE}Committing changes...${NC}"
git add .
git commit -m "Version $NEW_VERSION: $CHANGES

- $UPDATE_TYPE version update
- Updated all action package.json files
- Updated all workflow WORKFLOW_VERSION variables"

# Push changes
echo -e "\n${BLUE}Pushing changes...${NC}"
git push

echo -e "\n${GREEN}Version update complete!${NC}"
echo -e "${GREEN}New version:${NC} $NEW_VERSION"
echo -e "${GREEN}Changes:${NC} $CHANGES"