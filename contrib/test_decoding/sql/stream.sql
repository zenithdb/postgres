SET synchronous_commit = on;
SELECT 'init' FROM pg_create_logical_replication_slot('regression_slot', 'test_decoding');

CREATE TABLE stream_test(data text);

-- consume DDL
SELECT data FROM pg_logical_slot_get_changes('regression_slot', NULL, NULL, 'include-xids', '0', 'skip-empty-xacts', '1');

-- streaming test with sub-transaction
BEGIN;
savepoint s1;
SELECT 'msg5' FROM pg_logical_emit_message(true, 'test', repeat('a', 50));
INSERT INTO stream_test SELECT repeat('a', 2000) || g.i FROM generate_series(1, 35) g(i);
TRUNCATE table stream_test;
rollback to s1;
INSERT INTO stream_test SELECT repeat('a', 10) || g.i FROM generate_series(1, 20) g(i);
COMMIT;

SELECT data FROM pg_logical_slot_get_changes('regression_slot', NULL,NULL, 'include-xids', '0', 'stream-changes', '1');

-- streaming test for toast changes
ALTER TABLE stream_test ALTER COLUMN data set storage external;
-- consume DDL
SELECT data FROM pg_logical_slot_get_changes('regression_slot', NULL, NULL, 'include-xids', '0', 'skip-empty-xacts', '1');

INSERT INTO stream_test SELECT repeat('a', 6000) || g.i FROM generate_series(1, 10) g(i);
SELECT data FROM pg_logical_slot_get_changes('regression_slot', NULL,NULL, 'include-xids', '0', 'stream-changes', '1');

DROP TABLE stream_test;
SELECT pg_drop_replication_slot('regression_slot');
