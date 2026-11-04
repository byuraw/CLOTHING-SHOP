USE clothing_store_fixed;
SET NAMES utf8mb4;

-- BACK UP FIRST: this migration updates reconciled order, sales, and payment amounts.

-- Before-migration mismatch counts.
SELECT 'before_orders_total_vs_subtotal' AS check_name, COUNT(*) AS mismatch_count
FROM orders
WHERE total_amount <> subtotal
UNION ALL
SELECT 'before_orders_subtotal_vs_line_sum', COUNT(*)
FROM (
    SELECT o.order_id
    FROM orders o
    LEFT JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY o.order_id, o.subtotal
    HAVING o.subtotal <> COALESCE(ROUND(SUM(oi.line_total), 2), 0)
) mismatched_orders
UNION ALL
SELECT 'before_order_item_line_math', COUNT(*)
FROM order_items
WHERE line_total <> ROUND(unit_price * quantity, 2)
UNION ALL
SELECT 'before_sales_amount_vs_subtotal', COUNT(*)
FROM sales s
INNER JOIN orders o ON o.order_id = s.order_id
WHERE s.total_amount <> o.subtotal
UNION ALL
SELECT 'before_payment_amount_vs_subtotal', COUNT(*)
FROM payments p
INNER JOIN orders o ON o.order_id = p.order_id
WHERE p.amount <> o.subtotal;

-- Reconcile line items first, then use those line items as the source of truth.
UPDATE order_items
SET line_total = ROUND(unit_price * quantity, 2)
WHERE line_total <> ROUND(unit_price * quantity, 2);

UPDATE orders o
LEFT JOIN (
    SELECT order_id, ROUND(SUM(line_total), 2) AS corrected_subtotal
    FROM order_items
    GROUP BY order_id
) item_totals ON item_totals.order_id = o.order_id
SET o.subtotal = COALESCE(item_totals.corrected_subtotal, 0),
    o.total_amount = COALESCE(item_totals.corrected_subtotal, 0)
WHERE o.subtotal <> COALESCE(item_totals.corrected_subtotal, 0)
   OR o.total_amount <> COALESCE(item_totals.corrected_subtotal, 0);

UPDATE sales s
INNER JOIN orders o ON o.order_id = s.order_id
SET s.total_amount = o.total_amount
WHERE s.total_amount <> o.total_amount;

UPDATE payments p
INNER JOIN orders o ON o.order_id = p.order_id
SET p.amount = o.total_amount
WHERE p.amount <> o.total_amount;

-- Find and remove only the legacy orders CHECK that refers to shipping_fee.
SET @orders_shipping_check = NULL;
SELECT tc.CONSTRAINT_NAME
INTO @orders_shipping_check
FROM information_schema.TABLE_CONSTRAINTS tc
WHERE tc.CONSTRAINT_SCHEMA = DATABASE()
  AND tc.TABLE_NAME = 'orders'
  AND tc.CONSTRAINT_TYPE = 'CHECK'
  AND tc.CONSTRAINT_NAME IN (
      SELECT cc.CONSTRAINT_NAME
      FROM information_schema.CHECK_CONSTRAINTS cc
      WHERE cc.CONSTRAINT_SCHEMA = DATABASE()
        AND LOWER(cc.CHECK_CLAUSE) LIKE '%shipping_fee%'
  )
LIMIT 1;

SET @drop_orders_check_sql = IF(
    @orders_shipping_check IS NULL,
    'SELECT 1',
    IF(
        LOCATE('MariaDB', @@version) > 0,
        CONCAT(
            'ALTER TABLE `orders` DROP CONSTRAINT `',
            REPLACE(@orders_shipping_check, '`', '``'),
            '`'
        ),
        CONCAT(
            'ALTER TABLE `orders` DROP CHECK `',
            REPLACE(@orders_shipping_check, '`', '``'),
            '`'
        )
    )
);
PREPARE migration_statement FROM @drop_orders_check_sql;
EXECUTE migration_statement;
DEALLOCATE PREPARE migration_statement;

SET @drop_shipping_fee_sql = IF(
    (
        SELECT COUNT(*)
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'orders'
          AND COLUMN_NAME = 'shipping_fee'
    ) > 0,
    'ALTER TABLE `orders` DROP COLUMN `shipping_fee`',
    'SELECT 1'
);
PREPARE migration_statement FROM @drop_shipping_fee_sql;
EXECUTE migration_statement;
DEALLOCATE PREPARE migration_statement;

SET @add_orders_check_sql = IF(
    (
        SELECT COUNT(*)
        FROM information_schema.TABLE_CONSTRAINTS
        WHERE CONSTRAINT_SCHEMA = DATABASE()
          AND TABLE_NAME = 'orders'
          AND CONSTRAINT_TYPE = 'CHECK'
          AND CONSTRAINT_NAME = 'chk_orders_amounts'
    ) = 0,
    'ALTER TABLE `orders` ADD CONSTRAINT `chk_orders_amounts` CHECK (`subtotal` >= 0 AND `total_amount` >= 0)',
    'SELECT 1'
);
PREPARE migration_statement FROM @add_orders_check_sql;
EXECUTE migration_statement;
DEALLOCATE PREPARE migration_statement;

-- Drop obsolete columns only when each column is present.
SET @drop_column_sql = IF(
    (
        SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'addresses'
          AND COLUMN_NAME = 'created_at'
    ) > 0,
    'ALTER TABLE `addresses` DROP COLUMN `created_at`',
    'SELECT 1'
);
PREPARE migration_statement FROM @drop_column_sql;
EXECUTE migration_statement;
DEALLOCATE PREPARE migration_statement;

SET @drop_column_sql = IF(
    (
        SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'expenses'
          AND COLUMN_NAME = 'created_at'
    ) > 0,
    'ALTER TABLE `expenses` DROP COLUMN `created_at`',
    'SELECT 1'
);
PREPARE migration_statement FROM @drop_column_sql;
EXECUTE migration_statement;
DEALLOCATE PREPARE migration_statement;

SET @drop_column_sql = IF(
    (
        SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'users'
          AND COLUMN_NAME = 'updated_at'
    ) > 0,
    'ALTER TABLE `users` DROP COLUMN `updated_at`',
    'SELECT 1'
);
PREPARE migration_statement FROM @drop_column_sql;
EXECUTE migration_statement;
DEALLOCATE PREPARE migration_statement;

SET @drop_column_sql = IF(
    (
        SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'products'
          AND COLUMN_NAME = 'updated_at'
    ) > 0,
    'ALTER TABLE `products` DROP COLUMN `updated_at`',
    'SELECT 1'
);
PREPARE migration_statement FROM @drop_column_sql;
EXECUTE migration_statement;
DEALLOCATE PREPARE migration_statement;

SET @drop_column_sql = IF(
    (
        SELECT COUNT(*) FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'cart_items'
          AND COLUMN_NAME = 'updated_at'
    ) > 0,
    'ALTER TABLE `cart_items` DROP COLUMN `updated_at`',
    'SELECT 1'
);
PREPARE migration_statement FROM @drop_column_sql;
EXECUTE migration_statement;
DEALLOCATE PREPARE migration_statement;

CREATE OR REPLACE VIEW vw_order_transaction_details AS
SELECT
    o.order_id,
    o.order_number,
    o.placed_at,
    os.status_name,
    u.user_id,
    CONCAT_WS(' ', u.first_name, u.last_name) AS customer_name,
    u.email,
    oi.order_item_id,
    oi.product_name_snapshot,
    oi.size_snapshot,
    oi.color_snapshot,
    oi.unit_price,
    oi.quantity,
    oi.line_total,
    o.subtotal,
    o.total_amount
FROM orders o
INNER JOIN users u ON u.user_id=o.user_id
INNER JOIN order_statuses os ON os.order_status_id=o.order_status_id
INNER JOIN order_items oi ON oi.order_id=o.order_id;

-- Recreate the canonical triggers after data reconciliation.
DROP TRIGGER IF EXISTS trg_orders_insert_completed_sale;
DROP TRIGGER IF EXISTS trg_orders_completed_to_sale;
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

SET @add_review_index_sql = IF(
    (
        SELECT COUNT(*)
        FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'product_reviews'
          AND INDEX_NAME = 'uq_review_user_product'
          AND NON_UNIQUE = 0
    ) = 0,
    'ALTER TABLE `product_reviews` ADD UNIQUE INDEX `uq_review_user_product` (`user_id`, `product_id`)',
    'SELECT 1'
);
PREPARE migration_statement FROM @add_review_index_sql;
EXECUTE migration_statement;
DEALLOCATE PREPARE migration_statement;

-- After-migration mismatch counts; all amount reconciliation counts should be zero.
SELECT 'after_orders_total_vs_subtotal' AS check_name, COUNT(*) AS mismatch_count
FROM orders
WHERE total_amount <> subtotal
UNION ALL
SELECT 'after_orders_subtotal_vs_line_sum', COUNT(*)
FROM (
    SELECT o.order_id
    FROM orders o
    LEFT JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY o.order_id, o.subtotal
    HAVING o.subtotal <> COALESCE(ROUND(SUM(oi.line_total), 2), 0)
) mismatched_orders
UNION ALL
SELECT 'after_order_item_line_math', COUNT(*)
FROM order_items
WHERE line_total <> ROUND(unit_price * quantity, 2)
UNION ALL
SELECT 'after_sales_amount_mismatches', COUNT(*)
FROM sales s
INNER JOIN orders o ON o.order_id = s.order_id
WHERE s.total_amount <> o.total_amount
UNION ALL
SELECT 'after_payment_amount_mismatches', COUNT(*)
FROM payments p
INNER JOIN orders o ON o.order_id = p.order_id
WHERE p.amount <> o.total_amount;

SELECT 'after_sales_status_mismatches' AS check_name, COUNT(*) AS mismatch_count
FROM (
    SELECT o.order_id, os.status_name, COUNT(s.sale_id) AS sale_count
    FROM orders o
    INNER JOIN order_statuses os ON os.order_status_id = o.order_status_id
    LEFT JOIN sales s ON s.order_id = o.order_id
    GROUP BY o.order_id, os.status_name
    HAVING (os.status_name = 'Completed' AND COUNT(s.sale_id) <> 1)
        OR (os.status_name <> 'Completed' AND COUNT(s.sale_id) <> 0)
) invalid_sales
UNION ALL
SELECT 'after_duplicate_transaction_references', COUNT(*)
FROM (
    SELECT transaction_reference
    FROM sales
    GROUP BY transaction_reference
    HAVING COUNT(*) > 1
) duplicate_references
UNION ALL
SELECT 'after_duplicate_reviews_per_user_product', COUNT(*)
FROM (
    SELECT user_id, product_id
    FROM product_reviews
    GROUP BY user_id, product_id
    HAVING COUNT(*) > 1
) duplicate_reviews
UNION ALL
SELECT 'after_review_order_item_owner_product_mismatches', COUNT(*)
FROM product_reviews r
INNER JOIN order_items oi ON oi.order_item_id = r.order_item_id
INNER JOIN orders o ON o.order_id = oi.order_id
LEFT JOIN product_variants v ON v.variant_id = oi.variant_id
WHERE r.user_id <> o.user_id
   OR v.variant_id IS NULL
   OR r.product_id <> v.product_id;

SELECT 'vw_order_transaction_details_rows' AS check_name, COUNT(*) AS result_count
FROM vw_order_transaction_details;
SELECT 'completed_sale_insert_trigger_exists' AS check_name, COUNT(*) AS result_count
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = DATABASE()
  AND TRIGGER_NAME = 'trg_orders_insert_completed_sale';
SELECT 'completed_sale_update_trigger_exists' AS check_name, COUNT(*) AS result_count
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = DATABASE()
  AND TRIGGER_NAME = 'trg_orders_completed_to_sale';
SELECT 'uq_review_user_product_exists' AS check_name, COUNT(DISTINCT INDEX_NAME) AS result_count
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'product_reviews'
  AND INDEX_NAME = 'uq_review_user_product'
  AND NON_UNIQUE = 0;
