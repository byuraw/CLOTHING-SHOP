-- Ensure every completed order is represented in complete_transactions and sales.

DELIMITER $$
DROP TRIGGER IF EXISTS trg_orders_insert_completed_transaction$$
CREATE TRIGGER trg_orders_insert_completed_transaction
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
    IF NEW.order_status_id = (
        SELECT order_status_id FROM order_statuses WHERE status_name = 'Completed'
    )
    THEN
        INSERT INTO complete_transactions (
            order_id,
            transaction_reference,
            total_amount,
            payment_method_id,
            completed_at,
            notes
        )
        VALUES (
            NEW.order_id,
            CONCAT('TXN-', NEW.order_id, '-', DATE_FORMAT(NEW.placed_at, '%Y%m%d%H%i%s')),
            NEW.total_amount,
            NULL,
            NEW.placed_at,
            'Auto-recorded when order was created as completed'
        );
    END IF;
END$$
DELIMITER ;

INSERT INTO complete_transactions (
    order_id,
    transaction_reference,
    total_amount,
    payment_method_id,
    completed_at,
    notes
)
SELECT
    o.order_id,
    CONCAT(
        'TXN-',
        o.order_id,
        '-',
        DATE_FORMAT(COALESCE(h.completed_at, o.updated_at, o.placed_at), '%Y%m%d%H%i%s')
    ),
    o.total_amount,
    (
        SELECT p.payment_method_id
        FROM payments p
        WHERE p.order_id = o.order_id
        ORDER BY p.paid_at DESC, p.payment_id DESC
        LIMIT 1
    ),
    COALESCE(h.completed_at, o.updated_at, o.placed_at),
    'Backfilled for completed order'
FROM orders o
JOIN order_statuses os ON os.order_status_id = o.order_status_id
LEFT JOIN (
    SELECT order_id, order_status_id, MAX(changed_at) AS completed_at
    FROM order_status_history
    GROUP BY order_id, order_status_id
) h ON h.order_id = o.order_id AND h.order_status_id = o.order_status_id
LEFT JOIN complete_transactions ct ON ct.order_id = o.order_id
WHERE os.status_name = 'Completed'
  AND ct.order_id IS NULL;

INSERT INTO sales (
    order_id,
    transaction_reference,
    total_amount,
    payment_method_id,
    notes,
    sale_date
)
SELECT
    ct.order_id,
    ct.transaction_reference,
    ct.total_amount,
    ct.payment_method_id,
    ct.notes,
    ct.completed_at
FROM complete_transactions ct
LEFT JOIN sales s ON s.order_id = ct.order_id
WHERE s.order_id IS NULL;
