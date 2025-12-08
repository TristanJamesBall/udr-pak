-- Integration smoke tests for udr-pak functions
-- Run with: sudo -u informix dbaccess tjb tests/integration/integ_tests.sql

-- prng
SELECT prng() AS prng_val;

-- prng2
SELECT prng2() AS prng2_val;

-- uuid
SELECT uuidv7() AS uuid_val;

-- realtime family
SELECT realtime() AS realtime_val;
SELECT utc_realtime_dt() AS utc_realtime_val;
SELECT monotime_dt() AS monotime_val;
SELECT proctime_dt() AS proctime_val;
SELECT threadtime_dt() AS threadtime_val;

-- simple function
SELECT udr_fn('trace') AS udr_fn_count;
