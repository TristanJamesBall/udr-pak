#!/bin/bash
# Quick test verification script
# Runs a minimal smoke test to verify the testing infrastructure works

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "  udr-pak Test Infrastructure Verification"
echo "=========================================="
echo ""

# Check if test files exist
echo "Checking test files..."
for test_file in functional/test_*.sql; do
    if [[ -f "$test_file" ]]; then
        echo "  ✓ $(basename "$test_file")"
    else
        echo "  ✗ Missing: $test_file"
        exit 1
    fi
done
echo ""

# Check if scripts are executable
echo "Checking scripts..."
for script in run_tests.sh ci_pipeline.sh multi_version_test.sh; do
    if [[ -x "$script" ]]; then
        echo "  ✓ $script is executable"
    else
        echo "  ✗ $script is not executable"
        exit 1
    fi
done
echo ""

# Check configuration
echo "Checking configuration..."
if [[ -f "test_config.sh" ]]; then
    echo "  ✓ test_config.sh found"
    source test_config.sh
    echo "  ✓ Configuration loaded"
else
    echo "  ✗ test_config.sh not found"
    exit 1
fi
echo ""

# Check Informix (if available)
echo "Checking Informix availability..."
if check_informix 2>/dev/null; then
    echo "  ✓ Informix is available"
    echo "    INFORMIXDIR: $INFORMIXDIR"
    
    if [[ -x "$INFORMIXDIR/bin/dbaccess" ]]; then
        echo "  ✓ dbaccess is executable"
    fi
    
    # Try to connect to database
    if sudo -u "${IFX_USER:-informix}" dbaccess "${TEST_DBNAME:-ci_test}" <<< "select count(*) from systables;" >/dev/null 2>&1; then
        echo "  ✓ Database ${TEST_DBNAME:-ci_test} is accessible"
        
        # Run a minimal test
        echo ""
        echo "Running minimal smoke test..."
        if sudo -u "${IFX_USER:-informix}" dbaccess "${TEST_DBNAME:-ci_test}" <<< "select prng();" >/dev/null 2>&1; then
            echo "  ✓ prng() function works"
        else
            echo "  ⚠ prng() function not available (may need to install udr-pak)"
        fi
    else
        echo "  ⚠ Database not accessible (Informix may not be running)"
    fi
else
    echo "  ⚠ Informix not available (set INFORMIXDIR or install Informix)"
fi
echo ""

echo "=========================================="
echo "  Verification Complete"
echo "=========================================="
echo ""
echo "Test infrastructure is ready!"
echo ""
echo "Next steps:"
echo "  1. Ensure Informix is running"
echo "  2. Build and install udr-pak: cd .. && make && make install"
echo "  3. Run tests: ./run_tests.sh"
echo ""
