#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ANSIBLE_DIR="${SCRIPT_DIR}/ansible"

# Parse arguments
ASK_BECOME_PASS=false
ANSIBLE_ARGS=()

for arg in "$@"; do
    case $arg in
        -K|--ask-become-pass|--sudo)
            ASK_BECOME_PASS=true
            ;;
        *)
            ANSIBLE_ARGS+=("$arg")
            ;;
    esac
done

echo -e "${BLUE}=== Deploying visualize-things to starbase ===${NC}"

# Check if ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
    echo -e "${RED}Error: ansible-playbook not found. Please install Ansible first.${NC}"
    echo "  brew install ansible"
    exit 1
fi

# Change to ansible directory
cd "${ANSIBLE_DIR}"

# Build command
CMD="ansible-playbook playbooks/deploy.yml"

if [ "$ASK_BECOME_PASS" = true ]; then
    echo -e "${YELLOW}Note: You will be prompted for the sudo password on starbase${NC}"
    CMD="$CMD --ask-become-pass"
fi

if [ ${#ANSIBLE_ARGS[@]} -gt 0 ]; then
    CMD="$CMD ${ANSIBLE_ARGS[@]}"
fi

# Run the playbook
echo -e "${BLUE}Running: $CMD${NC}"
eval $CMD

echo -e "${GREEN}=== Deployment complete! ===${NC}"
