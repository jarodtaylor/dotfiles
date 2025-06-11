#!/bin/bash
# test-vm-setup.sh - Script for testing dotfiles in VM environment

set -eo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Test environment setup
log_info "Setting up test environment for dotfiles..."

# Check if this is a fresh system
if [[ -d "$HOME/.local/share/chezmoi" ]]; then
    log_warning "Existing chezmoi installation found - this may not be a clean test"
fi

# Create test directory for logs
TEST_DIR="$HOME/dotfiles-test-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

log_info "Test directory: $TEST_DIR"

# Download and test the startup script
log_info "Downloading startup script..."
curl -sfL https://raw.githubusercontent.com/jarodtaylor/dotfiles/main/.startup.sh -o startup.sh

# Check script syntax
if bash -n startup.sh; then
    log_success "Startup script syntax is valid"
else
    log_error "Startup script has syntax errors"
    exit 1
fi

# Test the startup script
log_info "Testing startup script execution..."
log_warning "This will install software on this VM - make sure you have a snapshot!"

read -p "Continue with startup script test? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Test cancelled by user"
    exit 0
fi

# Run startup script with logging
log_info "Running startup script..."
bash startup.sh 2>&1 | tee "$TEST_DIR/startup-log.txt"

if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
    log_success "Startup script completed successfully"
else
    log_error "Startup script failed - check $TEST_DIR/startup-log.txt"
    exit 1
fi

# Test basic functionality
log_info "Testing basic dotfiles functionality..."

# Test zsh functions
if command -v fzf >/dev/null 2>&1; then
    log_success "fzf installed correctly"
else
    log_error "fzf not found"
fi

# Test chezmoi
if command -v chezmoi >/dev/null 2>&1; then
    log_success "chezmoi installed correctly"
    chezmoi --version
else
    log_error "chezmoi not found"
fi

# Test 1Password CLI (if available)
if command -v op >/dev/null 2>&1; then
    log_success "1Password CLI installed"
    # Note: Won't be authenticated in VM
else
    log_warning "1Password CLI not found (expected in VM)"
fi

# Test brew installation
if command -v brew >/dev/null 2>&1; then
    log_success "Homebrew installed correctly"
    brew --version
else
    log_error "Homebrew not found"
fi

# Test git configuration
if git config --global user.name >/dev/null 2>&1; then
    log_success "Git user configured: $(git config --global user.name)"
else
    log_warning "Git user not configured (expected without 1Password)"
fi

# Test starship prompt
if command -v starship >/dev/null 2>&1; then
    log_success "Starship prompt installed"
else
    log_error "Starship not found"
fi

# Test LaunchAgent (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    if launchctl list | grep -q "com.user.vscode-backup"; then
        log_success "VSCode backup LaunchAgent loaded"
    else
        log_warning "VSCode backup LaunchAgent not loaded"
    fi
fi

# Generate test report
log_info "Generating test report..."
cat > "$TEST_DIR/test-report.md" << EOF
# Dotfiles Test Report

**Test Date**: $(date)
**macOS Version**: $(sw_vers -productVersion) ($(sw_vers -buildVersion))
**Test Directory**: $TEST_DIR

## ✅ Successful Components
$(grep "✅" "$TEST_DIR/startup-log.txt" || echo "No explicit successes logged")

## ⚠️  Warnings
$(grep "⚠️" "$TEST_DIR/startup-log.txt" || echo "No warnings")

## ❌ Errors
$(grep "❌" "$TEST_DIR/startup-log.txt" || echo "No errors")

## 📝 Full Log
See \`startup-log.txt\` for complete installation log.

## 🧪 Test Commands Run
- Startup script syntax check
- Full startup script execution
- Basic tool verification
- Configuration verification

## 💡 Notes for Improvement
- Add specific notes about what failed or could be improved
- Note any VM-specific issues (1Password, network, etc.)
EOF

log_success "Test complete! Report saved to $TEST_DIR/test-report.md"
log_info "Review the report and startup-log.txt for detailed results"

# Optional: Upload results (if you want to track tests)
log_info "Test results saved locally. Consider copying to your main machine for review."
