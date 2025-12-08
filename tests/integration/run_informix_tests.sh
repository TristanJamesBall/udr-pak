#!/usr/bin/env bash
set -euo pipefail

# Integration test runner for udr-pak. Requires Informix SDK and server.
# It builds the extension, installs it into the Informix server extend dir,
# then runs SQL via dbaccess as the `informix` OS user.

ROOT_DIR=$(dirname "${BASH_SOURCE[0]}")/../../
ROOT_DIR=$(realpath "$ROOT_DIR")
cd "$ROOT_DIR"

echo "Building udr-pak..."
make

echo "Installing udr-pak into Informix (may require sudo)..."
make install

SQL_FILE="${ROOT_DIR}/tests/integration/integ_tests.sql"

echo "Running integration SQL tests via dbaccess..."
sudo -u informix dbaccess -a tjb "$SQL_FILE" 2>&1 | sed '/^$/d'

echo "Integration tests completed. Check dbaccess output above for failures." 
