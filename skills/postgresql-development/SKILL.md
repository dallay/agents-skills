---
name: postgresql-development
version: 1.0.0
description: >
  PostgreSQL database development patterns covering schema design, advanced queries, indexing
  strategies, performance tuning, migrations, and operational best practices.
triggers:
  - "PostgreSQL"
  - "Postgres"
  - "SQL optimization"
  - "database schema design"
  - "pg_dump"
---

## When to Use

- Designing PostgreSQL schemas with proper constraints, types, and indexes.
- Writing advanced queries using CTEs, window functions, JSONB, or array operations.
- Analyzing and optimizing slow queries with `EXPLAIN ANALYZE`.
- Setting up indexing strategies (B-tree, GIN, GiST, partial, covering indexes).
- Configuring connection pooling with PgBouncer or built-in poolers.
- Managing migrations, transactions, isolation levels, and data integrity.
- Tuning PostgreSQL server parameters for workload characteristics.
- Backup, restore, and disaster recovery with `pg_dump` and `pg_basebackup`.

## Critical Patterns

- **Constraints at the Database Level:** Enforce NOT NULL, CHECK, UNIQUE, and foreign keys in the schema — never rely solely on application-level validation. The database is the last line of defense.
- **Index Deliberately:** Every index has a write cost. Create indexes based on actual query patterns from `EXPLAIN ANALYZE`, not speculation. Monitor with `pg_stat_user_indexes` to find unused ones.
- **Use Appropriate Types:** Use `uuid` (not VARCHAR) for identifiers, `timestamptz` (not `timestamp`) for times, `text` (not VARCHAR(n)) for variable strings, `numeric` for money, and `jsonb` (not `json`) for document data.
- **CTEs Are Not Optimization Barriers (since PG 12):** PostgreSQL can inline CTEs. Use them freely for readability. Add `MATERIALIZED` only when you explicitly need to force a single evaluation.
- **Connection Pooling Is Mandatory:** PostgreSQL forks a process per connection. Always use PgBouncer (or Supavisor, pgcat) in front of PostgreSQL in production. Target max 100-200 actual connections.
- **Transactions Should Be Short:** Long-running transactions hold locks and block autovacuum. Keep transactions under a few seconds. For bulk operations, use batched commits.
- **Always EXPLAIN ANALYZE:** Never guess at query performance. Use `EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)` to see actual row counts, buffer hits, and execution time.

## Code Examples

### Schema Design with Proper Types and Constraints

```sql
-- Use uuid, timestamptz, text, and proper constraints
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

CREATE TABLE users (
    id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    email       text NOT NULL UNIQUE,
    full_name   text NOT NULL CHECK (length(full_name) BETWEEN 1 AND 200),
    role        text NOT NULL DEFAULT 'member' CHECK (role IN ('admin', 'member', 'viewer')),
    metadata    jsonb NOT NULL DEFAULT '{}',
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE orders (
    id          uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status      text NOT NULL DEFAULT 'pending'
                     CHECK (status IN ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled')),
    total       numeric(12, 2) NOT NULL CHECK (total >= 0),
    items       jsonb NOT NULL DEFAULT '[]',
    created_at  timestamptz NOT NULL DEFAULT now()
);

-- Partial index: only index rows that matter for active queries
CREATE INDEX idx_orders_pending ON orders (user_id, created_at)
    WHERE status = 'pending';

-- GIN index for JSONB containment queries
CREATE INDEX idx_orders_items_gin ON orders USING gin (items);

-- Trigram index for LIKE/ILIKE text search
CREATE INDEX idx_users_name_trgm ON users USING gin (full_name gin_trgm_ops);

-- Auto-update updated_at with a trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

### Advanced Queries: CTEs and Window Functions

```sql
-- CTE + window function: rank users by order count per month
WITH monthly_orders AS (
    SELECT
        user_id,
        date_trunc('month', created_at) AS month,
        count(*) AS order_count,
        sum(total) AS month_total
    FROM orders
    WHERE status != 'cancelled'
    GROUP BY user_id, date_trunc('month', created_at)
)
SELECT
    u.email,
    mo.month,
    mo.order_count,
    mo.month_total,
    rank() OVER (PARTITION BY mo.month ORDER BY mo.order_count DESC) AS rank
FROM monthly_orders mo
JOIN users u ON u.id = mo.user_id
ORDER BY mo.month DESC, rank;
```

### JSONB Queries

```sql
-- Query nested JSONB: find orders containing a specific product
SELECT id, total, items
FROM orders
WHERE items @> '[{"product_id": "abc-123"}]';

-- Extract and aggregate JSONB array elements
SELECT
    o.id,
    elem->>'product_id' AS product_id,
    (elem->>'quantity')::int AS quantity
FROM orders o,
     jsonb_array_elements(o.items) AS elem
WHERE (elem->>'quantity')::int > 5;

-- Update a JSONB field (merge)
UPDATE users
SET metadata = metadata || '{"verified": true, "tier": "premium"}'::jsonb
WHERE id = 'some-uuid';
```

### EXPLAIN ANALYZE: Reading Query Plans

```sql
-- Always use ANALYZE + BUFFERS for real execution stats
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT u.email, count(o.id) AS order_count
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE u.created_at > now() - interval '30 days'
GROUP BY u.email
ORDER BY order_count DESC
LIMIT 20;

-- Key things to look for in output:
-- 1. Seq Scan on large tables → missing index
-- 2. actual rows vs. estimated rows differ wildly → stale statistics, run ANALYZE
-- 3. Buffers: shared hit vs. read → cache efficiency
-- 4. Sort Method: external merge → increase work_mem for this query
```

### Indexing Strategies

```sql
-- B-tree (default): equality and range queries
CREATE INDEX idx_orders_created ON orders (created_at DESC);

-- Covering index: index-only scans, no table access needed
CREATE INDEX idx_orders_covering ON orders (user_id, created_at) INCLUDE (total, status);

-- Partial index: only index a useful subset
CREATE INDEX idx_orders_active ON orders (created_at)
    WHERE status NOT IN ('delivered', 'cancelled');

-- GiST: range types, geometric, full-text
CREATE INDEX idx_events_during ON events USING gist (tstzrange(start_at, end_at));

-- GIN: arrays, JSONB, trigrams, full-text search
CREATE INDEX idx_users_tags ON users USING gin (tags);

-- Identify unused indexes
SELECT schemaname, relname, indexrelname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;
```

### Migrations Pattern

```sql
-- Safe column addition (non-blocking)
ALTER TABLE users ADD COLUMN phone text;

-- UNSAFE: adding NOT NULL with default rewrites entire table on PG < 11
-- SAFE on PG 11+: metadata is stored, no rewrite
ALTER TABLE users ADD COLUMN is_active boolean NOT NULL DEFAULT true;

-- Safe index creation (non-blocking)
CREATE INDEX CONCURRENTLY idx_users_phone ON users (phone);

-- Safe enum value addition
ALTER TYPE order_status ADD VALUE IF NOT EXISTS 'refunded';
```

### Connection Pooling (PgBouncer)

```ini
; pgbouncer.ini
[databases]
myapp = host=127.0.0.1 port=5432 dbname=myapp

[pgbouncer]
listen_addr = 0.0.0.0
listen_port = 6432
auth_type = scram-sha-256
auth_file = /etc/pgbouncer/userlist.txt

; Transaction pooling: connections returned after each transaction
pool_mode = transaction
default_pool_size = 20
max_client_conn = 1000
max_db_connections = 50

; Timeouts
server_idle_timeout = 600
client_idle_timeout = 0
query_timeout = 30
```

### Performance Tuning (postgresql.conf)

```ini
# Memory (adjust based on available RAM)
shared_buffers = '4GB'          # 25% of total RAM
effective_cache_size = '12GB'   # 75% of total RAM
work_mem = '64MB'               # Per-operation sort/hash memory
maintenance_work_mem = '1GB'    # For VACUUM, CREATE INDEX

# WAL
wal_buffers = '64MB'
checkpoint_completion_target = 0.9
max_wal_size = '4GB'

# Query planner
random_page_cost = 1.1          # SSD storage (default 4.0 is for HDD)
effective_io_concurrency = 200  # SSD

# Connections
max_connections = 200           # Use with PgBouncer in front

# Autovacuum (don't disable it, tune it)
autovacuum_max_workers = 4
autovacuum_naptime = '30s'
autovacuum_vacuum_cost_limit = 1000
```

## Commands

```bash
# Backup (custom format, compressed, parallel)
pg_dump -Fc -j 4 -f backup.dump mydb

# Restore
pg_restore -d mydb -j 4 --clean --if-exists backup.dump

# Plain SQL dump (for version control or small DBs)
pg_dump --schema-only -f schema.sql mydb

# Check bloat and table sizes
psql -c "SELECT relname, pg_size_pretty(pg_total_relation_size(oid))
         FROM pg_class WHERE relkind = 'r' ORDER BY pg_total_relation_size(oid) DESC LIMIT 20;"

# Check active queries and locks
psql -c "SELECT pid, state, query_start, query FROM pg_stat_activity WHERE state != 'idle';"

# Run ANALYZE to update statistics after bulk load
psql -c "ANALYZE;"

# Check replication lag (if applicable)
psql -c "SELECT client_addr, state, sent_lsn, write_lsn, replay_lsn,
         pg_wal_lsn_diff(sent_lsn, replay_lsn) AS byte_lag
         FROM pg_stat_replication;"
```

## Best Practices

### DO

- Use `timestamptz` everywhere — `timestamp` silently drops timezone info and causes bugs across regions.
- Use `text` over `varchar(n)` — PostgreSQL stores them identically, and `varchar(n)` just adds a CHECK constraint that's painful to change later.
- Run `EXPLAIN (ANALYZE, BUFFERS)` on every slow query before adding indexes.
- Use `CREATE INDEX CONCURRENTLY` in production — regular `CREATE INDEX` locks the table for writes.
- Use transactions for multi-statement operations: `BEGIN; ... COMMIT;`.
- Run `ANALYZE` after bulk inserts or major data changes to keep the query planner accurate.
- Monitor with `pg_stat_user_tables`, `pg_stat_user_indexes`, and `pg_stat_activity`.

### DON'T

- Don't use `SERIAL` — use `GENERATED ALWAYS AS IDENTITY` or `uuid` for primary keys.
- Don't create indexes on every column "just in case" — each index slows writes and consumes disk.
- Don't use `SELECT *` in application queries — fetch only the columns you need.
- Don't run `VACUUM FULL` routinely — it locks the table exclusively. Regular `VACUUM` (via autovacuum) is sufficient.
- Don't store large blobs in PostgreSQL — use object storage (S3) and store the URL/reference.
- Don't use `timestamp` without timezone — timezone-unaware timestamps are a common source of production bugs.
- Don't disable autovacuum — tune it instead. Disabled autovacuum leads to transaction ID wraparound and table bloat.
- Don't connect directly from application servers without a connection pooler in production.
