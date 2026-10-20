ALTER TABLE users
  ADD COLUMN username VARCHAR(50) NULL UNIQUE;

INSERT INTO users (
  username,
  first_name,
  last_name,
  email,
  password_hash,
  role_id,
  status_id
)
SELECT
  'admin',
  'Admin',
  'Account',
  'admin@example.com',
  '$2y$10$.swgQnJFoU16vz1MuG5R5uAFsDRhHdNiqSsm9JfgbZza8ZCOUklhm',
  r.role_id,
  s.status_id
FROM roles r
CROSS JOIN account_statuses s
WHERE r.role_name = 'Admin'
  AND s.status_name = 'Active'
  AND NOT EXISTS (
    SELECT 1
    FROM users
    WHERE username = 'admin'
      OR email = 'admin@example.com'
  );
