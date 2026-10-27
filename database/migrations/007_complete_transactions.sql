-- Add a complete transaction record whenever an order is marked Completed.

START TRANSACTION;

CREATE TABLE IF NOT EXISTS complete_transactions (
    complete_transaction_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL UNIQUE,
    transaction_reference VARCHAR(80) NOT NULL UNIQUE,
    total_amount DECIMAL(10, 2) NOT NULL,
    payment_method_id TINYINT UNSIGNED NULL,
    completed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notes VARCHAR(255) NULL,
    CHECK (total_amount >= 0),
    FOREIGN KEY (order_id) REFERENCES orders (order_id) ON DELETE CASCADE,
    FOREIGN KEY (payment_method_id) REFERENCES payment_methods (payment_method_id) ON DELETE SET NULL,
    INDEX idx_complete_transactions_date (completed_at)
) ENGINE = InnoDB;

DELIMITER $$
DROP TRIGGER IF EXISTS trg_orders_completed_to_transaction$$
CREATE TRIGGER trg_orders_completed_to_transaction
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    IF NEW.order_status_id = (
        SELECT order_status_id FROM order_statuses WHERE status_name = 'Completed'
    )
       AND (OLD.order_status_id IS NULL OR OLD.order_status_id <> NEW.order_status_id)
    THEN
        INSERT INTO complete_transactions (
            order_id,
            transaction_reference,
            total_amount,
            payment_method_id,
            notes
        )
        SELECT
            NEW.order_id,
            CONCAT('TXN-', NEW.order_id, '-', DATE_FORMAT(NOW(), '%Y%m%d%H%i%s')),
            NEW.total_amount,
            p.payment_method_id,
            'Auto-recorded when order was marked completed'
        FROM (
            SELECT 1 AS dummy
        ) AS base
        LEFT JOIN (
            SELECT payment_method_id, order_id
            FROM payments
            WHERE order_id = NEW.order_id
            ORDER BY paid_at DESC, payment_id DESC
            LIMIT 1
        ) AS p ON p.order_id = NEW.order_id
        ON DUPLICATE KEY UPDATE
            total_amount = VALUES(total_amount),
            payment_method_id = VALUES(payment_method_id),
            completed_at = CURRENT_TIMESTAMP,
            notes = VALUES(notes);
    END IF;
END$$
DELIMITER ;

INSERT INTO complete_transactions (order_id, transaction_reference, total_amount, payment_method_id, notes)
SELECT o.order_id,
       CONCAT('TXN-', o.order_id, '-', DATE_FORMAT(o.updated_at, '%Y%m%d%H%i%s')),
       o.total_amount,
       p.payment_method_id,
       'Auto-recorded when order was marked completed'
FROM orders o
LEFT JOIN (
    SELECT payment_method_id, order_id
    FROM payments
    WHERE order_id IS NOT NULL
    ORDER BY paid_at DESC, payment_id DESC
) p ON p.order_id = o.order_id
JOIN order_statuses os ON os.order_status_id = o.order_status_id
WHERE os.status_name = 'Completed'
AND NOT EXISTS (
    SELECT 1 FROM complete_transactions ct WHERE ct.order_id = o.order_id
)
ON DUPLICATE KEY UPDATE
    total_amount = VALUES(total_amount),
    payment_method_id = VALUES(payment_method_id),
    completed_at = CURRENT_TIMESTAMP,
    notes = VALUES(notes);

COMMIT;
