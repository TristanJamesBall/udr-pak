#!/bin/bash
# CI/CD automation script for udr-pak testing across multiple Informix versions
# This script:
# 1. Installs a specified Informix version
# 2. Builds udr-pak
# 3. Installs udr-pak into Informix
# 4. Runs functional tests
# 5. Reports results

set -euo pipefail

SCRIPT_DIR="$(realpath "$(dirname "$0" )" )"
TEST_DIR="$(realpath "${SCRIPT_DIR}/.." )"

cd "${TEST_DIR}"

# Configuration
PROJECT_ROOT="$(realpath "${TEST_DIR}/.." )"
INFORMIX_VERSION="${INFORMIX_VERSION:-}"
PACKAGE_FILE="${PACKAGE_FILE:-}"
KEEP_SERVER="${KEEP_SERVER:-0}"
RUN_TESTS="${RUN_TESTS:-1}"

# Colors
COLOR_RESET='\033[0m'
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_BLUE='\033[0;34m'

log_info() {
    echo -e "${COLOR_BLUE}[CI]${COLOR_RESET} $*"
}

log_success() {
    echo -e "${COLOR_GREEN}[CI]${COLOR_RESET} $*"
}

log_error() {
    echo -e "${COLOR_RED}[CI]${COLOR_RESET} $*"
}

err_exit() {
    echo -e "${COLOR_RED}[CI]${COLOR_RESET} $*"
    exit 1
}

log_warning() {
    echo -e "${COLOR_YELLOW}[CI]${COLOR_RESET} $*"
}

usage() {
    cat <<EOF
Usage: ${0} [OPTIONS]

CI/CD automation for testing udr-pak across Informix versions.

Options:
  -v, --version VERSION    Informix version to test (e.g., 15.0.0.2)
  -p, --package FILE       Path to Informix package tarball
  -k, --keep-server        Keep Informix server running after tests
  -n, --no-tests           Skip functional tests (only build & install)
  -h, --help               Show this help message

Environment Variables:
  INFORMIX_VERSION         Same as --version
  PACKAGE_FILE             Same as --package
  KEEP_SERVER              Set to 1 to keep server (same as --keep-server)
  RUN_TESTS                Set to 0 to skip tests (same as --no-tests)

Examples:
  # Test with Informix 15.0.0.2
  ${0} --package 15.0.0.2.tar.zst

  # Test without cleanup (for debugging)
  ${0} --package 15.0.0.2.tar.zst --keep-server

  # Only build and install, skip tests
  ${0} --package 15.0.0.2.tar.zst --no-tests

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case ${1} in
        -v|--version)
            INFORMIX_VERSION="${2}"
            shift 2
            ;;
        -p|--package)
            PACKAGE_FILE="${2}"
            shift 2
            ;;
        -k|--keep-server)
            KEEP_SERVER=1
            shift
            ;;
        -n|--no-tests)
            RUN_TESTS=0
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: ${1}"
            usage
            exit 1
            ;;
    esac
done

# Validate inputs
if [[ -z "${PACKAGE_FILE}" ]]; then
    log_error "Package file not specified. Use --package or set PACKAGE_FILE"
    usage
    exit 1
fi

[[ -f "pkg/${PACKAGE_FILE}" ]] || err_exit "Package file not found: pkg/${PACKAGE_FILE}"

INFORMIX_VERSION="${INFORMIX_VERSION:-$(basename "${PACKAGE_FILE}" .tar.zst)}"

# Main CI/CD steps
log_info "================================================"
log_info "  udr-pak CI/CD Pipeline"
log_info "================================================"
log_info "Informix Version: ${INFORMIX_VERSION}"
log_info "Package File:     ${PACKAGE_FILE}"
log_info "Project Root:     ${PROJECT_ROOT}"
log_info ""

# Step 1: Install Informix
log_info "Step 1/5: Installing Informix ${INFORMIX_VERSION}..."
if [[ -x "./scripts/ifx_install.sh" ]]; then
    if ./scripts/ifx_install.sh "pkg/${PACKAGE_FILE}"; then
        log_success "Informix installed successfully"
    else
        err_exit "Informix installation failed"
    fi
else
    err_exit "ifx_install.sh not found or not executable"
fi
echo 

# Step 2: Source environment
log_info "Step 2/5: Configuring environment..."
if [[ -f "${SCRIPT_DIR}/integ.env" ]]; then
    source "${SCRIPT_DIR}/integ.env"
    INFORMIXDIR="$(realpath server)"
    export INFORMIXDIR
    log_success "Environment configured"
    log_info "  INFORMIXDIR=${INFORMIXDIR}"
    log_info "  INFORMIXSERVER=${INFORMIXSERVER}"
else
    log_error "Environment file not found: server/integ.env"
    exit 1
fi
echo ""

# Step 3: Build udr-pak
log_info "Step 3/5: Building udr-pak..."
cd "${PROJECT_ROOT}"

# Link SDK if needed
if [[ ! -e "informix-sdk" ]] && [[ -d "${INFORMIXDIR}/SDK" ]]; then
    ln -sf "${INFORMIXDIR}/SDK" informix-sdk
fi

if [[ ! -e "informix-server" ]]; then
    ln -sf "${INFORMIXDIR}" informix-server
fi

if make clean && make; then
    log_success "Build successful"
    if [[ -f "build/lib/udr-pak.so" ]]; then
        log_info "  Library: build/lib/udr-pak.so"
        ls -lh build/lib/udr-pak.so
    fi
else
    log_error "Build failed"
    exit 1
fi
echo ""

# Step 4: Install udr-pak
log_info "Step 4/5: Installing udr-pak into Informix..."
if make install; then
    log_success "Installation successful"
else
    log_error "Installation failed"
    exit 1
fi

# Verify installation
if [[ -x "${PROJECT_ROOT}/scripts/show_install.sh" ]]; then
    log_info "Verifying installation..."
    "${PROJECT_ROOT}/scripts/show_install.sh" || true
fi
echo ""

# Step 5: Run functional tests
if [[ ${RUN_TESTS} -eq 1 ]]; then
    log_info "Step 5/5: Running functional tests..."
    cd "${SCRIPT_DIR}"
    
    if ./run_tests.sh; then
        log_success "All tests passed!"
        TEST_EXIT_CODE=0
    else
        log_error "Some tests failed"
        TEST_EXIT_CODE=1
    fi
    
    # Display summary
    if [[ -f "test_results/summary.txt" ]]; then
        echo ""
        log_info "Test Summary:"
        cat test_results/summary.txt
    fi
else
    log_warning "Step 5/5: Skipping functional tests (--no-tests)"
    TEST_EXIT_CODE=0
fi
echo ""

# Cleanup
if [[ ${KEEP_SERVER} -eq 0 ]]; then
    log_info "Cleaning up Informix server..."
    cd "${SCRIPT_DIR}"
    sudo -u informix "source '${SCRIPT_DIR}/integ.env';onmode -ky" 2>/dev/null || true
    sleep 2
    log_success "Server stopped"
else
    log_warning "Keeping Informix server running (--keep-server)"
    log_info "To stop manually: sudo -u informix onmode -ky"
fi

# Final result
echo ""
log_info "================================================"
if [[ ${TEST_EXIT_CODE} -eq 0 ]]; then
    log_success "CI/CD Pipeline Completed Successfully"
else
    log_error "CI/CD Pipeline Completed with Errors"
fi
log_info "================================================"

exit ${TEST_EXIT_CODE}
