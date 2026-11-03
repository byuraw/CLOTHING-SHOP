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
    o.shipping_fee,
    o.total_amount
FROM orders o
JOIN users u ON u.user_id=o.user_id
JOIN order_statuses os ON os.order_status_id=o.order_status_id
JOIN order_items oi ON oi.order_id=o.order_id;

DELETE older
FROM product_reviews older
JOIN product_reviews newer
    ON newer.user_id=older.user_id
    AND newer.product_id=older.product_id
    AND (
        newer.created_at>older.created_at
        OR (
            newer.created_at=older.created_at
            AND newer.review_id>older.review_id
        )
    );

SET @qa_review_index_statement = (
    SELECT IF(
        EXISTS(
            SELECT 1
            FROM (
                SELECT index_name,
                    GROUP_CONCAT(column_name ORDER BY seq_in_index) AS indexed_columns
                FROM information_schema.statistics
                WHERE table_schema=DATABASE()
                    AND table_name='product_reviews'
                    AND non_unique=0
                GROUP BY index_name
            ) existing_indexes
            WHERE indexed_columns='user_id,product_id'
        ),
        'SELECT 1',
        'ALTER TABLE product_reviews ADD UNIQUE INDEX uq_review_user_product (user_id,product_id)'
    )
);
PREPARE qa_review_index_statement FROM @qa_review_index_statement;
EXECUTE qa_review_index_statement;
DEALLOCATE PREPARE qa_review_index_statement;
