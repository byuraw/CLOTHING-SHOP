-- Migration: remove line_total and subtotal from vw_order_transaction_details
-- Database: clothing_store_fixed
--
-- Only the VIEW changes. The line_total column in `order_items` and the
-- subtotal column in `orders` are NOT touched and keep working as before.
--
-- IMPORTANT: import this together with the PHP changes
-- (order-details.php and includes/order_email.php), because those two files
-- previously read line_total from this view.

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
    o.total_amount
FROM orders o
INNER JOIN users u ON u.user_id = o.user_id
INNER JOIN order_statuses os ON os.order_status_id = o.order_status_id
INNER JOIN order_items oi ON oi.order_id = o.order_id;

-- Verification: should list the view columns without line_total and subtotal.
SHOW COLUMNS FROM vw_order_transaction_details;
