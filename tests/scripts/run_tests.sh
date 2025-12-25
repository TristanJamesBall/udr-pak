#!/bin/bash
# Automated functional test runner for udr-pak
# Usage: ./run_tests.sh [--verbose] [--stop-on-error] [test_suite...]
#
# Examples:
#   ./run_tests.sh                    # Run all tests
#   ./run_tests.sh test_prng          # Run only PRNG tests
#   ./run_tests.sh --verbose          # Run all tests with verbose output
#   ./run_tests.sh test_prng test_uuid # Run specific test suites

set -euo pipefail 
shopt -s nullglob


# Change to test directory
SCRIPT_DIR=$(realpath "$(dirname "$0")")
TEST_DIR="$(realpath "${SCRIPT_DIR}/../functional" )"
# Source configuration
echo "SCRIPT_DIR:: ${SCRIPT_DIR}"

. "./test_config.sh"
cd "${TEST_DIR}" || exit 1

# Parse command line arguments
VERBOSE=${VERBOSE:-0}
STOP_ON_ERROR=${STOP_ON_ERROR:-0}
TEST_SUITES=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=1
            export VERBOSE
            shift
            ;;
        -s|--stop-on-error)
            STOP_ON_ERROR=1
            export STOP_ON_ERROR
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS] [test_suite...]"
            echo ""
            echo "Options:"
            echo "  -v, --verbose         Enable verbose output"
            echo "  -s, --stop-on-error   Stop on first test failure"
            echo "  -h, --help            Show this help message"
            echo ""
            echo "Test Suites:"
            echo "  test_any              Any_int_t custom type"
            echo "  test_prng             PRNG functions"
            echo "  test_realtime         Realtime/clock functions"
            echo "  test_seq              Sequence iterator"
            echo "  test_util             Utility functions"
            echo "  test_uuid             UUID functions"
            echo ""
            echo "If no test suites specified, all tests will run."
            exit 0
            ;;
        *)
            TEST_SUITES+=("$1")
            shift
            ;;
    esac
done

# Initialize test results
mkdir -p "$TEST_OUTPUT_DIR"
: > "$TEST_LOG_FILE"
: > "$TEST_SUMMARY_FILE"

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNED_TESTS=0

# Banner
echo "=========================================="
echo "  udr-pak Functional Test Suite"
echo "=========================================="
echo "Start time: $(date)"
echo ""

# Check Informix availability
log_info "Checking Informix installation..."
if ! check_informix; then
    log_error "Informix check failed. Ensure INFORMIXDIR is set and Informix is installed."
    exit 1
fi
log_success "Informix check passed"

# Verify database is accessible
log_info "Verifying database access..."
if ! sudo -u "$IFX_USER" dbaccess "$TEST_DBNAME" <<< "select count(*) from systables;" > /dev/null 2>&1; then
    log_error "Cannot access database $TEST_DBNAME"
    exit 1
fi
log_success "Database $TEST_DBNAME is accessible"


# Find test SQL files
if [[ ${#TEST_SUITES[@]} -eq 0 ]]; then
    # Run all tests if none specified
    TEST_FILES=(test_*.sql)
else
    # Run specified tests
    TEST_FILES=()
    for suite in "${TEST_SUITES[@]}"; do
        # Handle both with and without .sql extension
        suite_file="${suite%.sql}.sql"
        if [[ -f "$suite_file" ]]; then
            TEST_FILES+=("$suite_file")
        else
            log_warning "Test suite not found: $suite"
        fi
    done
fi


if [[ ${#TEST_FILES[@]} -eq 0 ]]; then
    log_error "No test files found to run"
    exit 1
fi

log_info "Found ${#TEST_FILES[@]} test suite(s) to run"
echo ""

if tty -s; then
    function result_hightlight {
        local red="$(printf %b "$COLOR_RED")"
        local green="$(printf %b "$COLOR_GREEN")"
        local blue="$(printf %b "$COLOR_BLUE")"
        local yellow="$(printf %b "$COLOR_YELLOW")"
        local reset="$(printf %b "$COLOR_RESET")"

        echo        
        sed -r "s/^/\\t/g; s/(test_name.+status)/${blue}\1${reset}/; s/FAIL/${red}}FAIL${reset}/; s/WARN/${yellow}WARN${reset}/; s/PASS/${green}PASS${reset}/;"
        echo
    }
else
  function result_hightlight {
        echo
        sed -r "s/^/\\t/g;"
        echo
    }
fi
# Run each test suite

for test_file in "${TEST_FILES[@]}"; do
    test_name=$(basename "$test_file" .sql)

    output_file="$TEST_OUTPUT_DIR/${test_name}.out"
    
    log_info "Running test suite: $test_name"

    suite_total=$( grep -c -i "^insert into results" "$test_file" ) 
    (( suite_total-- )) ## Don't count the header line
    # Run the test file

    if ! run_sql_test "$test_file" "$TEST_DBNAME" "$output_file"; then 
        FAILED_TESTS=$(( FAILED_TESTS + suite_total ))
        log_error "FATAL: $( basename "${test_file}" .sql) failed with SQL error"
        break
    fi

    RESULTS="../results/results.txt"

    if [[ ! -s "${RESULTS}" ]]; then
        FAILED_TESTS=$(( FAILED_TESTS + suite_total ))
        log_error "FATAL: $( basename "${test_file}" .sql) failed, no results found"
        break
    fi
    CWIDTH=$(( ${COLUMNS:-140} * 4 / 5  ))

    if grep -q expected3 "$RESULTS"
    then column -t -c "$CWIDTH" -T 4,7 -s'|' "$RESULTS"
    else column -t -c "$CWIDTH" -T 2,3,4 -s'|' "$RESULTS"
    fi |result_hightlight

    suite_passed=$( grep -c -E 'PASS[|]?$' "${RESULTS}" || true )
    suite_failed=$( grep -c -E 'FAIL[|]?$' "${RESULTS}" || true )
    suite_warned=$( grep -c -E 'WARN[|]?$' "${RESULTS}" || true )
    
    TOTAL_TESTS=$((TOTAL_TESTS + suite_total))
    PASSED_TESTS=$((PASSED_TESTS + suite_passed))
    FAILED_TESTS=$((FAILED_TESTS + suite_failed))
    WARNED_TESTS=$((WARNED_TESTS + suite_warned))
    
    if [[ $suite_failed -gt 0 ]]; then
        log_error "$test_name: $suite_passed passed, $suite_failed failed, $suite_warned warnings"
        if [[ $STOP_ON_ERROR -eq 1 ]]; then
            log_error "Stopping due to --stop-on-error flag"
            break
        fi
    elif [[ $suite_warned -gt 0 ]]; then
        log_warning "$test_name: $suite_passed passed, $suite_warned warnings"
    else
        log_success "$test_name: All $suite_passed tests passed"
    fi
    echo ""
    
done

# Summary
echo 
echo "=========================================="
echo "  Test Summary"
echo "=========================================="
echo "Total tests:   $TOTAL_TESTS"
echo "Passed:        $PASSED_TESTS"
echo "Failed:        $FAILED_TESTS"
echo "Warnings:      $WARNED_TESTS"
echo ""
echo "End time: $(date)"
echo "=========================================="

# Write summary to file
cat > "$TEST_SUMMARY_FILE" <<EOF
udr-pak Test Summary
====================
Date: $(date)
Total: $TOTAL_TESTS
Passed: $PASSED_TESTS
Failed: $FAILED_TESTS
Warnings: $WARNED_TESTS
EOF

echo ""

# Exit with appropriate code
if [[ $FAILED_TESTS -gt 0 ]]; then
    log_error "Test suite completed with failures"
    exit 1
elif [[ $WARNED_TESTS -gt 0 ]]; then
    log_warning "Test suite completed with warnings"
    exit 0
elif [[ $PASSED_TESTS -lt $TOTAL_TESTS ]] ; then
    log_error "FATAL - TEST RESULTS LOST"
else
    log_success "All tests passed!"
    exit 0
fi
