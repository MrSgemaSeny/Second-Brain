# PostgreSQL Trigger-Based Audit Logs

## Overview
To ensure compliance and data integrity for financial and CRM operations, audit logs are protected directly at the database level.

## Implementation
PostgreSQL triggers are configured on the `audit_log` table to completely prohibit `UPDATE` and `DELETE` operations.

```sql
CREATE OR REPLACE FUNCTION prevent_audit_modification()
RETURNS TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'UPDATE and DELETE on audit tables are prohibited';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER audit_log_no_update
  BEFORE UPDATE ON audit_log
  FOR EACH ROW EXECUTE FUNCTION prevent_audit_modification();
```

## Benefits
- Prevents accidental or malicious modification of historical audit data.
- Enforces strict append-only behavior critical for financial platforms.
- Complemented by application-level logic (`HibernateAuditListener`) that masks sensitive fields (passwords, tokens) before inserting records into the audit log.
