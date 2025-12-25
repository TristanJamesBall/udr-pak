# udr-pak Functional Testing Guide

This directory contains a comprehensive automated testing framework for udr-pak User Defined Routines (UDRs).

## Overview

The testing framework provides:
- **Functional tests** for all UDR modules (PRNG, UUID, realtime, seq, util, tracing)
- **Automated test runner** with detailed reporting
- **CI/CD pipeline** for testing across multiple Informix versions
- **Multi-version testing** support

## Quick Start

### Prerequisites

1. Informix server installed and running
2. Test database created (default: `ci_test`)
3. udr-pak built and installed (`make && make install`)

### Running Tests

```bash
# Run all functional tests
cd tests
./run_tests.sh

# Run specific test suite
./run_tests.sh test_prng

# Run multiple test suites
./run_tests.sh test_prng test_uuid

# Run with verbose output
./run_tests.sh --verbose

# Stop on first failure
./run_tests.sh --stop-on-error
```

## Test Structure

### Test Files

```
tests/
├── test_config.sh              # Common test configuration and utilities
├── run_tests.sh                # Main test runner
├── ci_pipeline.sh              # CI/CD automation script
├── multi_version_test.sh       # Multi-version testing
├── ifx_install.sh              # Informix installation script
└── functional/                 # Functional test SQL files
    ├── test_prng.sql          # PRNG function tests
    ├── test_uuid.sql          # UUID function tests
    ├── test_realtime.sql      # Realtime/clock function tests
    ├── test_seq.sql           # Sequence iterator tests
    ├── test_util.sql          # Utility function tests
    └── test_tracing.sql       # Tracing function tests
```

### Test Output

Test results are stored in `test_results/`:
```
test_results/
├── test.log                    # Detailed test log
├── summary.txt                 # Test summary
├── test_prng.out              # Individual test output files
├── test_uuid.out
└── ...
```

## Test Suites

### PRNG Tests (`test_prng.sql`)
Tests for pseudo-random number generation:
- Basic functionality
- Value uniqueness and distribution
- Integration with hex conversion functions
- Performance baseline

### UUID Tests (`test_uuid.sql`)
Tests for UUID generation:
- UUIDv7 and UUIDv4 format validation
- Uniqueness guarantees
- Monotonic ordering (UUIDv7)
- Performance baseline

### Realtime Tests (`test_realtime.sql`)
Tests for time/clock functions:
- All realtime variants (realtime, utc, monotime, proctime, threadtime)
- Clock tick functions (ns, μs, seconds)
- Monotonic behavior
- Date range sanity checks

### Sequence Tests (`test_seq.sql`)
Tests for sequence iterator:
- Single, two, and three parameter variants
- Positive and negative steps
- Cross joins
- Edge cases and large ranges

### Utility Tests (`test_util.sql`)
Tests for utility functions:
- Hex conversion (to_hex, to_hex4)
- NULL handling
- Value consistency
- Performance

### Tracing Tests (`test_tracing.sql`)
Tests for tracing infrastructure:
- Trace configuration
- Trace level management
- On/off toggling
- Trace class registration

## CI/CD Integration

### Single Version Testing

Test with a specific Informix version:

```bash
# Basic usage
./ci_pipeline.sh --version 15.0.0.2 --package 15.0.0.2.tar.zst

# Keep server running after tests (for debugging)
./ci_pipeline.sh --version 15.0.0.2 --package 15.0.0.2.tar.zst --keep-server

# Only build and install, skip tests
./ci_pipeline.sh --version 15.0.0.2 --package 15.0.0.2.tar.zst --no-tests
```

The CI pipeline performs:
1. Installs Informix from package
2. Configures environment
3. Builds udr-pak
4. Installs udr-pak into Informix
5. Runs functional tests
6. Reports results
7. Cleanup (optional)

### Multi-Version Testing

Test across multiple Informix versions:

```bash
# Test all available versions
./multi_version_test.sh

# Test specific versions
./multi_version_test.sh 14.10 15.0

# Test single version
./multi_version_test.sh 15.0
```

Configure available versions in `multi_version_test.sh`:
```bash
declare -A TEST_PACKAGES=(
    ["12.10"]="12.10.FC16W2.tar.zst"
    ["14.10"]="14.10.12.12.tar.zst"
    ["15.0"]="15.0.0.2.tar.zst"
)
```

## Configuration

### Environment Variables

Key environment variables (set in `test_config.sh`):

```bash
# Informix paths
INFORMIXDIR              # Informix installation directory
INFORMIXSDK              # Informix SDK directory
INFORMIXSERVER           # Server name (default: ifx_ci)

# Test configuration
TEST_DBNAME              # Test database name (default: ci_test)
TEST_USER                # Regular test user
IFX_USER                 # Informix admin user (default: informix)

# Test behavior
VERBOSE                  # Enable verbose output (0 or 1)
STOP_ON_ERROR           # Stop on first failure (0 or 1)
CLEANUP_ON_SUCCESS      # Cleanup after successful run (0 or 1)

# Output
TEST_OUTPUT_DIR         # Test results directory
TEST_LOG_FILE           # Main log file
TEST_SUMMARY_FILE       # Summary file
```

### Customization

Modify `test_config.sh` to customize:
- Database names and users
- Output directories
- Logging behavior
- Color schemes
- Helper functions

## Writing New Tests

### SQL Test File Structure

```sql
-- Functional tests for <module>
-- Tests: function1(), function2()

DATABASE ci_test;

-- Test 1: Description
-- Expected: What should happen
SELECT 'TEST: Description' AS test_name;
SELECT 
    -- test logic here
    CASE 
        WHEN condition THEN 'PASS' 
        ELSE 'FAIL' 
    END AS status
FROM ...;

-- Test 2: Another test
SELECT 'TEST: Another test' AS test_name;
-- ... test logic ...
```

### Test Naming Convention

- Test name line: `SELECT 'TEST: <description>' AS test_name;`
- Status field: Must return `PASS`, `FAIL`, or `WARN`
- Always include expected behavior in comments

### Adding New Test Suite

1. Create SQL file in `tests/functional/test_<module>.sql`
2. Follow the test structure above
3. Test file will be auto-discovered by `run_tests.sh`
4. Run with: `./run_tests.sh test_<module>`

## Troubleshooting

### Common Issues

**Database not accessible:**
```bash
# Verify Informix is running
onstat -

# Check database exists
dbaccess sysmaster <<< "select name from sysdatabases"

# Verify permissions
dbaccess ci_test <<< "select count(*) from systables"
```

**Build failures:**
```bash
# Check SDK is available
ls -l informix-sdk/incl

# Rebuild from scratch
make clean && make

# Check for specific errors in build output
make 2>&1 | grep -i error
```

**Test failures:**
```bash
# Run with verbose output
./run_tests.sh --verbose test_prng

# Check individual test output
cat test_results/test_prng.out

# Run SQL manually for debugging
dbaccess ci_test functional/test_prng.sql
```

**Permission issues:**
```bash
# Ensure running as correct user
sudo -u informix dbaccess ci_test

# Check file permissions
ls -l build/lib/udr-pak.so
ls -l $INFORMIXDIR/extend/udr-pak/
```

### Debug Mode

Enable detailed debugging:
```bash
# Verbose output
export VERBOSE=1
./run_tests.sh

# Keep Informix running for inspection
./ci_pipeline.sh --keep-server --version 15.0 --package 15.0.0.2.tar.zst

# Manual SQL execution
sudo -u informix dbaccess -e ci_test functional/test_prng.sql
```

## Integration with Existing Tools

### Compatibility with Existing Scripts

The test framework integrates with existing tools:
- `scripts/show_install.sh` - Verify UDR installation
- `bench/udr_bench.sh` - Performance benchmarking
- Existing demo SQL files

### Running with Existing Infrastructure

```bash
# Use existing Informix installation
export INFORMIXDIR=/opt/informix
export INFORMIXSDK=/opt/informix/SDK
./run_tests.sh

# Use existing database
export TEST_DBNAME=mydb
./run_tests.sh
```

## Best Practices

1. **Always run tests after code changes** - Catch regressions early
2. **Test across multiple Informix versions** - Ensure compatibility
3. **Review test output files** - Don't just check pass/fail counts
4. **Add tests for new features** - Maintain coverage
5. **Keep tests independent** - Each test should run standalone
6. **Use meaningful test names** - Make failures easy to diagnose
7. **Document expected behavior** - Help future maintainers

## Performance Testing

While functional tests include basic performance checks, use dedicated benchmarks for detailed analysis:

```bash
# PRNG benchmark
bench/udr_bench.sh

# Realtime benchmark
dev/realtime_bench.sh

# Sequence benchmark
dev/seq_bench.sh
```

## Continuous Integration

### GitHub Actions / GitLab CI Example

```yaml
test:
  script:
    - cd tests
    - ./ci_pipeline.sh --version 15.0.0.2 --package $CI_PACKAGES/15.0.0.2.tar.zst
  artifacts:
    paths:
      - tests/test_results/
    when: always
```

### Jenkins Example

```groovy
stage('Test') {
    steps {
        sh '''
            cd tests
            ./ci_pipeline.sh --version 15.0.0.2 --package ${WORKSPACE}/packages/15.0.0.2.tar.zst
        '''
    }
    post {
        always {
            archiveArtifacts artifacts: 'tests/test_results/**/*'
        }
    }
}
```

## Support

For issues or questions:
1. Check test output in `test_results/`
2. Review existing test files for examples
3. Consult main project documentation
4. Check `.github/copilot-instructions.md` for repo conventions
