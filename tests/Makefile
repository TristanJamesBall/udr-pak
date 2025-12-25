# Makefile for udr-pak tests
# Provides convenient shortcuts for testing

.PHONY: help verify test test-all test-prng test-uuid test-realtime test-seq test-util test-tracing clean results log verbose

# Default target - show help
help:
	@./QUICKREF.sh

server/integ.env:
	@./ifx_test_install.sh

tests: server/integ.env
	{ source server/integ.env; cd ..; make install DBNAME=$$DBNAME INFORMIXDIR=$$INFORMIXDIR ;}

# Verify test infrastructure
verify:
	@./verify_tests.sh

# Run all functional tests
test: test-all

test-all:
	@./run_tests.sh

# Run individual test suites
test-prng:
	@./run_tests.sh test_prng

test-uuid:
	@./run_tests.sh test_uuid

test-realtime:
	@./run_tests.sh test_realtime

test-seq:
	@./run_tests.sh test_seq

test-util:
	@./run_tests.sh test_util

test-tracing:
	@./run_tests.sh test_tracing

# Run with verbose output
verbose:
	@./run_tests.sh --verbose

# Clean test results
clean:
	@echo "Cleaning test results..."
	@rm -rf test_results
	@echo "Done."

# View test summary
results:
	@if [ -f test_results/summary.txt ]; then \
		cat test_results/summary.txt; \
	else \
		echo "No test results found. Run 'make test' first."; \
	fi

# View detailed log
log:
	@if [ -f test_results/test.log ]; then \
		less test_results/test.log; \
	else \
		echo "No test log found. Run 'make test' first."; \
	fi
