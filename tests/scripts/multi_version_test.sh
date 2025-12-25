#!/bin/bash
# Multi-version testing script
# Tests udr-pak against multiple Informix versions sequentially

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Default test packages (adjust paths as needed)
declare -A TEST_PACKAGES=(
    ["12.10"]="12.10.FC16W2.tar.zst"
    ["14.10"]="14.10.12.12.tar.zst"
    ["15.0"]="15.0.0.2.tar.zst"
)

# Colors
COLOR_RESET='\033[0m'
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_BLUE='\033[0;34m'

log_info() {
    echo -e "${COLOR_BLUE}[MULTI]${COLOR_RESET} $*"
}

log_success() {
    echo -e "${COLOR_GREEN}[MULTI]${COLOR_RESET} $*"
}

log_error() {
    echo -e "${COLOR_RED}[MULTI]${COLOR_RESET} $*"
}

usage() {
    cat <<EOF
Usage: $0 [OPTIONS] [version...]

Test udr-pak across multiple Informix versions.

Options:
  -h, --help               Show this help message
  version...               Specific versions to test (e.g., 12.10 14.10 15.0)
                          If omitted, tests all available versions

Available versions:
$(for v in "${!TEST_PACKAGES[@]}"; do echo "  - $v (${TEST_PACKAGES[$v]})"; done | sort)

Examples:
  $0                       # Test all versions
  $0 15.0                  # Test only Informix 15.0
  $0 14.10 15.0            # Test Informix 14.10 and 15.0

EOF
}

# Parse arguments
TEST_VERSIONS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        *)
            TEST_VERSIONS+=("$1")
            shift
            ;;
    esac
done

# Use all versions if none specified
if [[ ${#TEST_VERSIONS[@]} -eq 0 ]]; then
    TEST_VERSIONS=("${!TEST_PACKAGES[@]}")
fi

# Results tracking
declare -A RESULTS
TOTAL_VERSIONS=0
PASSED_VERSIONS=0
FAILED_VERSIONS=0

log_info "================================================"
log_info "  udr-pak Multi-Version Test Suite"
log_info "================================================"
log_info "Testing ${#TEST_VERSIONS[@]} version(s)"
echo ""

# Test each version
for version in "${TEST_VERSIONS[@]}"; do
    if [[ ! -v TEST_PACKAGES[$version] ]]; then
        log_error "Unknown version: $version"
        RESULTS[$version]="UNKNOWN"
        continue
    fi
    
    package="${TEST_PACKAGES[$version]}"
    package_path="$SCRIPT_DIR/$package"
    
    if [[ ! -f "$package_path" ]]; then
        log_error "Package not found: $package_path"
        RESULTS[$version]="MISSING"
        FAILED_VERSIONS=$((FAILED_VERSIONS + 1))
        TOTAL_VERSIONS=$((TOTAL_VERSIONS + 1))
        continue
    fi
    
    log_info "Testing Informix $version..."
    echo ""
    
    TOTAL_VERSIONS=$((TOTAL_VERSIONS + 1))
    
    if ./ci_pipeline.sh --version "$version" --package "$package_path"; then
        log_success "Informix $version: PASSED"
        RESULTS[$version]="PASS"
        PASSED_VERSIONS=$((PASSED_VERSIONS + 1))
    else
        log_error "Informix $version: FAILED"
        RESULTS[$version]="FAIL"
        FAILED_VERSIONS=$((FAILED_VERSIONS + 1))
    fi
    
    echo ""
    echo "----------------------------------------"
    echo ""
done

# Final summary
log_info "================================================"
log_info "  Multi-Version Test Summary"
log_info "================================================"
echo ""

for version in $(printf '%s\n' "${!RESULTS[@]}" | sort); do
    result="${RESULTS[$version]}"
    case $result in
        PASS)
            log_success "Informix $version: PASSED"
            ;;
        FAIL)
            log_error "Informix $version: FAILED"
            ;;
        MISSING)
            log_error "Informix $version: PACKAGE MISSING"
            ;;
        UNKNOWN)
            log_error "Informix $version: UNKNOWN VERSION"
            ;;
    esac
done

echo ""
log_info "Total versions tested: $TOTAL_VERSIONS"
log_info "Passed: $PASSED_VERSIONS"
log_info "Failed: $FAILED_VERSIONS"
log_info "================================================"

if [[ $FAILED_VERSIONS -gt 0 ]]; then
    exit 1
else
    exit 0
fi
