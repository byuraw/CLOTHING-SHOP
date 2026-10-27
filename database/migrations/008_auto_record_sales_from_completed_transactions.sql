-- Auto-record completed transactions as sales entries.

START TRANSACTION;

CREATE TABLE IF NOT EXISTS sales (
    sale_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL UNIQUE,
    transaction_reference VARCHAR(80) NOT NULL UNIQUE,
    total_amount DECIMAL(10, 2) NOT NULL,
    payment_method_id TINYINT UNSIGNED NULL,
    sale_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    notes VARCHAR(255) NULL,
    CHECK (total_amount >= 0),
    FOREIGN KEY (order_id) REFERENCES orders (order_id) ON DELETE CASCADE,
    FOREIGN KEY (payment_method_id) REFERENCES payment_methods (payment_method_id) ON DELETE SET NULL,
    INDEX idx_sales_date (sale_date)
) ENGINE = InnoDB;

DELIMITER $$
DROP TRIGGER IF EXISTS trg_complete_transaction_to_sales$$
CREATE TRIGGER trg_complete_transaction_to_sales
AFTER INSERT ON complete_transactions
FOR EACH ROW
BEGIN
    INSERT INTO sales (
        order_id,
        transaction_reference,
        total_amount,
        payment_method_id,
        notes,
        sale_date
    )
    VALUES (
        NEW.order_id,
        NEW.transaction_reference,
        NEW.total_amount,
        NEW.payment_method_id,
        NEW.notes,
        NEW.completed_at
    )
    ON DUPLICATE KEY UPDATE
        transaction_reference = VALUES(transaction_reference),
        total_amount = VALUES(total_amount),
        payment_method_id = VALUES(payment_method_id),
        notes = VALUES(notes),
        sale_date = VALUES(sale_date);
END$$
DELIMITER ;

INSERT INTO sales (order_id, transaction_reference, total_amount, payment_method_id, notes, sale_date)
SELECT ct.order_id, ct.transaction_reference, ct.total_amount, ct.payment_method_id, ct.notes, ct.completed_at
FROM complete_transactions ct
LEFT JOIN sales s ON s.order_id = ct.order_id
WHERE s.order_id IS NULL
ON DUPLICATE KEY UPDATE
    transaction_reference = VALUES(transaction_reference),
    total_amount = VALUES(total_amount),
    payment_method_id = VALUES(payment_method_id),
    notes = VALUES(notes),
    sale_date = VALUES(sale_date);

COMMIT;
