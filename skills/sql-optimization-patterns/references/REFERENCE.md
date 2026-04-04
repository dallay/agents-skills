## Best Practices

1. **Index Selectively**: Too many indexes slow down writes
2. **Monitor Query Performance**: Use slow query logs
3. **Keep Statistics Updated**: Run ANALYZE regularly
4. **Use Appropriate Data Types**: Smaller types = better performance
5. **Normalize Thoughtfully**: Balance normalization vs performance
6. **Cache Frequently Accessed Data**: Use application-level caching
7. **Connection Pooling**: Reuse database connections
8. **Regular Maintenance**: VACUUM, ANALYZE, rebuild indexes

```sql
-- Update statistics
ANALYZE users;
ANALYZE VERBOSE orders;

-- Vacuum (PostgreSQL)
VACUUM ANALYZE users;
VACUUM FULL users;  -- Reclaim space (locks table)

-- Reindex
REINDEX INDEX idx_users_email;
REINDEX TABLE users;
```

## Common Pitfalls

- **Over-Indexing**: Each index slows down INSERT/UPDATE/DELETE
- **Unused Indexes**: Waste space and slow writes
- **Missing Indexes**: Slow queries, full table scans
- **Implicit Type Conversion**: Prevents index usage
- **OR Conditions**: Can't use indexes efficiently
- **LIKE with Leading Wildcard**: `LIKE '%abc'` can't use index
- **Function in WHERE**: Prevents index usage unless functional index exists

## Monitoring Queries

```sql
-- Find slow queries (PostgreSQL)
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;

-- Find missing indexes (PostgreSQL)
SELECT
    schemaname,
    tablename,
    seq_scan,
    seq_tup_read,
    idx_scan,
    seq_tup_read / seq_scan AS avg_seq_tup_read
FROM pg_stat_user_tables
WHERE seq_scan > 0
ORDER BY seq_tup_read DESC
LIMIT 10;

-- Find unused indexes (PostgreSQL)
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;
```

## Resources

- **references/postgres-optimization-guide.md**: PostgreSQL-specific optimization
- **references/mysql-optimization-guide.md**: MySQL/MariaDB optimization
- **references/query-plan-analysis.md**: Deep dive into EXPLAIN plans
- **assets/index-strategy-checklist.md**: When and how to create indexes
- **assets/query-optimization-checklist.md**: Step-by-step optimization guide
- **scripts/analyze-slow-queries.sql**: Identify slow queries in your database
- **scripts/index-recommendations.sql**: Generate index recommendations
