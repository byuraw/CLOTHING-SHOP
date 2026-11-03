USE clothing_store_fixed;

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
JOIN users u ON u.user_id=o.user_id
JOIN order_statuses os ON os.order_status_id=o.order_status_id
JOIN order_items oi ON oi.order_id=o.order_id;

UPDATE orders
SET total_amount = subtotal
WHERE total_amount <> subtotal;

UPDATE sales s
JOIN orders o ON o.order_id = s.order_id
SET s.total_amount = o.total_amount
WHERE s.total_amount <> o.total_amount;

ALTER TABLE orders
    DROP CONSTRAINT `CONSTRAINT_1`,
    DROP COLUMN shipping_fee,
    ADD CONSTRAINT chk_orders_nonnegative_amounts
        CHECK (subtotal >= 0 AND total_amount >= 0);
