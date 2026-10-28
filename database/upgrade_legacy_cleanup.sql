USE clothing_store_fixed;

DROP VIEW IF EXISTS vw_order_transaction_details;
DROP TRIGGER IF EXISTS trg_complete_transaction_to_sales;
DROP TRIGGER IF EXISTS trg_complete_transaction_update_sales;
DROP TRIGGER IF EXISTS trg_orders_insert_completed_transaction;
DROP TRIGGER IF EXISTS trg_orders_completed_to_transaction;
DROP TRIGGER IF EXISTS trg_orders_insert_completed_sale;
DROP TRIGGER IF EXISTS trg_orders_completed_to_sale;

SET @address_line2_column = (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'addresses'
      AND COLUMN_NAME = 'address_line2'
);
SET @upgrade_sql = IF(
    @address_line2_column = 0,
    'SELECT 1',
    'ALTER TABLE addresses DROP COLUMN address_line2'
);
PREPARE upgrade_statement FROM @upgrade_sql;
EXECUTE upgrade_statement;
DEALLOCATE PREPARE upgrade_statement;

SET @color_code_column = (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'colors'
      AND COLUMN_NAME = 'color_code'
);
SET @upgrade_sql = IF(
    @color_code_column = 0,
    'SELECT 1',
    'ALTER TABLE colors DROP COLUMN color_code'
);
PREPARE upgrade_statement FROM @upgrade_sql;
EXECUTE upgrade_statement;
DEALLOCATE PREPARE upgrade_statement;

SET @payment_reference_column = (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'payments'
      AND COLUMN_NAME = 'reference_number'
);
SET @upgrade_sql = IF(
    @payment_reference_column = 0,
    'SELECT 1',
    'ALTER TABLE payments DROP COLUMN reference_number'
);
PREPARE upgrade_statement FROM @upgrade_sql;
EXECUTE upgrade_statement;
DEALLOCATE PREPARE upgrade_statement;

SET @payment_paid_at_column = (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'payments'
      AND COLUMN_NAME = 'paid_at'
);
SET @upgrade_sql = IF(
    @payment_paid_at_column = 0,
    'SELECT 1',
    'ALTER TABLE payments DROP COLUMN paid_at'
);
PREPARE upgrade_statement FROM @upgrade_sql;
EXECUTE upgrade_statement;
DEALLOCATE PREPARE upgrade_statement;

SET @payments_method_fk = (
    SELECT CONSTRAINT_NAME
    FROM information_schema.KEY_COLUMN_USAGE
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'payments'
      AND COLUMN_NAME = 'payment_method_id'
      AND REFERENCED_TABLE_NAME IS NOT NULL
    LIMIT 1
);
SET @upgrade_sql = IF(
    @payments_method_fk IS NULL,
    'SELECT 1',
    CONCAT('ALTER TABLE payments DROP FOREIGN KEY `', @payments_method_fk, '`')
);
PREPARE upgrade_statement FROM @upgrade_sql;
EXECUTE upgrade_statement;
DEALLOCATE PREPARE upgrade_statement;

SET @sales_method_fk = (
    SELECT CONSTRAINT_NAME
    FROM information_schema.KEY_COLUMN_USAGE
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'sales'
      AND COLUMN_NAME = 'payment_method_id'
      AND REFERENCED_TABLE_NAME IS NOT NULL
    LIMIT 1
);
SET @upgrade_sql = IF(
    @sales_method_fk IS NULL,
    'SELECT 1',
    CONCAT('ALTER TABLE sales DROP FOREIGN KEY `', @sales_method_fk, '`')
);
PREPARE upgrade_statement FROM @upgrade_sql;
EXECUTE upgrade_statement;
DEALLOCATE PREPARE upgrade_statement;

SET @payments_method_column = (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'payments'
      AND COLUMN_NAME = 'payment_method_id'
);
SET @upgrade_sql = IF(
    @payments_method_column = 0,
    'SELECT 1',
    'ALTER TABLE payments DROP COLUMN payment_method_id'
);
PREPARE upgrade_statement FROM @upgrade_sql;
EXECUTE upgrade_statement;
DEALLOCATE PREPARE upgrade_statement;

SET @sales_method_column = (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'sales'
      AND COLUMN_NAME = 'payment_method_id'
);
SET @upgrade_sql = IF(
    @sales_method_column = 0,
    'SELECT 1',
    'ALTER TABLE sales DROP COLUMN payment_method_id'
);
PREPARE upgrade_statement FROM @upgrade_sql;
EXECUTE upgrade_statement;
DEALLOCATE PREPARE upgrade_statement;

DROP TABLE IF EXISTS payment_methods;

SET @has_complete_transactions = (
    SELECT COUNT(*)
    FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'complete_transactions'
);
SET @upgrade_sql = IF(
    @has_complete_transactions = 0,
    'SELECT 1',
    'INSERT INTO sales (order_id,transaction_reference,total_amount,sale_date,notes)
     SELECT ct.order_id,ct.transaction_reference,o.total_amount,ct.completed_at,ct.notes
     FROM complete_transactions ct
     INNER JOIN orders o ON o.order_id=ct.order_id
     ON DUPLICATE KEY UPDATE
       transaction_reference=VALUES(transaction_reference),
       total_amount=VALUES(total_amount),
       sale_date=VALUES(sale_date),
       notes=VALUES(notes)'
);
PREPARE upgrade_statement FROM @upgrade_sql;
EXECUTE upgrade_statement;
DEALLOCATE PREPARE upgrade_statement;

DROP TABLE IF EXISTS complete_transactions;

DELIMITER $$
CREATE TRIGGER trg_orders_insert_completed_sale
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
    IF NEW.order_status_id = (
        SELECT order_status_id FROM order_statuses WHERE status_name = 'Completed'
    )
    THEN
        INSERT INTO sales (
            order_id,
            transaction_reference,
            total_amount,
            sale_date,
            notes
        )
        VALUES (
            NEW.order_id,
            CONCAT('TXN-', NEW.order_id, '-', DATE_FORMAT(NEW.placed_at, '%Y%m%d%H%i%s')),
            NEW.total_amount,
            NEW.placed_at,
            'Auto-recorded when order was created as completed'
        )
        ON DUPLICATE KEY UPDATE
            transaction_reference = VALUES(transaction_reference),
            total_amount = VALUES(total_amount),
            sale_date = VALUES(sale_date),
            notes = VALUES(notes);
    END IF;
END$$

CREATE TRIGGER trg_orders_completed_to_sale
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    IF NEW.order_status_id = (
        SELECT order_status_id FROM order_statuses WHERE status_name = 'Completed'
    )
       AND (OLD.order_status_id IS NULL OR OLD.order_status_id <> NEW.order_status_id)
    THEN
        INSERT INTO sales (
            order_id,
            transaction_reference,
            total_amount,
            notes,
            sale_date
        )
        VALUES (
            NEW.order_id,
            CONCAT('TXN-', NEW.order_id, '-', DATE_FORMAT(NOW(), '%Y%m%d%H%i%s')),
            NEW.total_amount,
            'Auto-recorded when order was marked completed',
            CURRENT_TIMESTAMP
        )
        ON DUPLICATE KEY UPDATE
            transaction_reference = VALUES(transaction_reference),
            total_amount = VALUES(total_amount),
            notes = VALUES(notes),
            sale_date = VALUES(sale_date);
    END IF;
END$$
DELIMITER ;
