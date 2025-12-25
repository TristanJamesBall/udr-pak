#!/bin/bash
# Quick reference for udr-pak testing commands

cat <<'EOF'
╔══════════════════════════════════════════════════════════════════════╗
║                  udr-pak Testing Quick Reference                      ║
╚══════════════════════════════════════════════════════════════════════╝

📋 BASIC TESTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ./verify_tests.sh              Verify test infrastructure
  ./run_tests.sh                 Run all functional tests
  ./run_tests.sh test_prng       Run only PRNG tests
  ./run_tests.sh test_uuid       Run only UUID tests
  ./run_tests.sh --verbose       Run with detailed output
  ./run_tests.sh --stop-on-error Stop on first failure

📦 CI/CD AUTOMATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # Single version testing
  ./ci_pipeline.sh \
    --version 15.0.0.2 \
    --package 15.0.0.2.tar.zst

  # Keep server for debugging
  ./ci_pipeline.sh \
    --version 15.0.0.2 \
    --package 15.0.0.2.tar.zst \
    --keep-server

  # Multi-version testing
  ./multi_version_test.sh             # Test all versions
  ./multi_version_test.sh 14.10 15.0  # Test specific versions

🔍 DEBUGGING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # View test output
  cat test_results/test.log
  cat test_results/summary.txt
  cat test_results/test_prng.out

  # Run SQL manually
  sudo -u informix dbaccess ci_test functional/test_prng.sql

  # Check installation
  ../scripts/show_install.sh

📁 TEST SUITES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  test_prng      PRNG functions (prng, to_hex)
  test_uuid      UUID generation (uuidv7, uuidv4)
  test_realtime  Time/clock functions (realtime*, clocktick*)
  test_seq       Sequence iterator (seq)
  test_util      Utility functions (to_hex, to_hex4)
  test_tracing   Tracing infrastructure

⚙️  ENVIRONMENT VARIABLES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  VERBOSE=1 ./run_tests.sh               Enable verbose mode
  STOP_ON_ERROR=1 ./run_tests.sh         Stop on first error
  TEST_DBNAME=mydb ./run_tests.sh        Use different database
  INFORMIXDIR=/opt/ifx ./run_tests.sh    Use different Informix

🚀 TYPICAL WORKFLOW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1. Build project:        cd .. && make
  2. Install UDRs:         cd .. && make install
  3. Verify setup:         cd tests && ./verify_tests.sh
  4. Run tests:            ./run_tests.sh
  5. Check results:        cat test_results/summary.txt

🔗 MORE INFORMATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  README.md                      Full testing guide
  TESTING_FRAMEWORK.md           Framework overview
  test_config.sh                 Configuration reference

EOF
