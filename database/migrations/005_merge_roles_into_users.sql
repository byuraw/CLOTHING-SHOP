ALTER TABLE users
  ADD COLUMN role_name ENUM('Customer', 'Admin') NULL AFTER user_id;

UPDATE users u
JOIN roles r ON r.role_id = u.role_id
SET u.role_name = r.role_name;

ALTER TABLE users
  MODIFY role_name ENUM('Customer', 'Admin') NOT NULL DEFAULT 'Customer',
  DROP FOREIGN KEY fk_users_role,
  DROP INDEX fk_users_role,
  DROP COLUMN role_id;

DROP TABLE roles;
