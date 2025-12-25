#!/bin/bash
# Configuration for udr-pak functional tests

# Test environment configuration
TEST_ROOT="$(realpath "$(dirname "${BASH_SOURCE[0]}")" )"
TEST_ROOT="$(realpath "${TEST_ROOT}/.." )"
PROJECT_ROOT="$(realpath "${TEST_ROOT}/..")"
BUILD_DIR="${PROJECT_ROOT}/build"
SRC_DIR="${PROJECT_ROOT}/src"
export TEST_ROOT PROJECT_ROOT BUILD_DIR SRC_DIR

# Informix configuration
export INFORMIXSDK="${INFORMIXSDK:-${TEST_ROOT}/../informix-sdk}"
export INFORMIXDIR="${INFORMIXDIR:-${TEST_ROOT}/server}"
export INFORMIXSERVER="${INFORMIXSERVER:-ifx_ci}"
export ONCONFIG="${ONCONFIG:-onconfig.ifx_ci}"
export PATH="${INFORMIXDIR}/bin:${PATH}"
export LD_LIBRARY_PATH="${INFORMIXDIR}/lib:${INFORMIXDIR}/lib/esql:${LD_LIBRARY_PATH:-}"

# Test database configuration
export TEST_DBNAME="${TEST_DBNAME:-ci_test}"
export TEST_USER="${TEST_USER:-$(whoami)}"
export IFX_USER="${IFX_USER:-informix}"

# Test output configuration
export TEST_OUTPUT_DIR="${TEST_OUTPUT_DIR:-${TEST_ROOT}/results}"
export TEST_LOG_FILE="${TEST_OUTPUT_DIR}/test.log"
export TEST_SUMMARY_FILE="${TEST_OUTPUT_DIR}/summary.txt"

# Test behavior flags
export VERBOSE="${VERBOSE:-0}"
export STOP_ON_ERROR="${STOP_ON_ERROR:-0}"
export CLEANUP_ON_SUCCESS="${CLEANUP_ON_SUCCESS:-1}"

# Colors for output
export COLOR_RESET='\033[0m'
export COLOR_RED='\033[0;31m'
export COLOR_GREEN='\033[0;32m'
export COLOR_YELLOW='\033[0;33m'
export COLOR_BLUE='\033[0;34m'

# Helper functions
log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*" | tee -a "${TEST_LOG_FILE}"
}

log_success() {
    echo -e "${COLOR_GREEN}[PASS]${COLOR_RESET} $*" | tee -a "${TEST_LOG_FILE}"
}

log_error() {
    echo -e "${COLOR_RED}[FAIL]${COLOR_RESET} $*" | tee -a "${TEST_LOG_FILE}"
}

log_warning() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $*" | tee -a "${TEST_LOG_FILE}"
}

# Ensure output directory exists
mkdir -p "${TEST_OUTPUT_DIR}"
chmod 777 "${TEST_OUTPUT_DIR}"

# Check if Informix is accessible
check_informix() {
    if [[ ! -d "${INFORMIXDIR}" ]]; then
        log_error "INFORMIXDIR not found: ${INFORMIXDIR}"
        return 1
    fi
    
    if [[ ! -x "${INFORMIXDIR}/bin/dbaccess" ]]; then
        log_error "dbaccess not found or not executable"
        return 1
    fi
    
    return 0
}

# Run SQL and capture output
run_sql() {
    local sql="${1}"
    local db="${2:-${TEST_DBNAME}}"
    local output_file="${3:-/dev/null}"
    
    if [[ "${VERBOSE}" == "1" ]]; then
        log_info "Running SQL: ${sql}"
    fi
    
    sudo -u "${IFX_USER}" dbaccess "${db}" 2>&1 <<< "${sql}" | tee "${output_file}"
    return "${PIPESTATUS[0]}"
}

# Run SQL tests
# SQL Scripts are expected to unload their results to 'results.txt'
run_sql_test() {
    local sql_file="${1}"
    local db="${2:-${TEST_DBNAME}}"
    local stderr_file="${3:-/dev/null}"
    
    log_info "Running SQL file: $(basename "${sql_file}")"
    
    sudo -u "${IFX_USER}" rm -f '../results/results.txt' 
    rm -f "${stderr_file}"
    # Note: dbaccess returns non-zero even on success, so we ignore the exit code
    # and rely on checking the output for errors
    touch "${stderr_file}"
    sudo -u "${IFX_USER}" dbaccess  "${db}" "${sql_file}" 2> "${stderr_file}" || true 

    if grep -E -q '^ +[0-9]+[:] |Error in line' "${stderr_file}"; then
        line=$(awk '/Error in line/ {print $4; exit}' "${stderr_file}")
        grep -E -B2 'Error in line' "${stderr_file}"
        cat -n "${sql_file}" | grep -B10 -E "^ +${line}"
        return 1
    fi
    return 0
}
