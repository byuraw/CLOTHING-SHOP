-- ===== Source: database\migrations\006_sample_business_data.sql =====
-- Sample business data for demo/testing.
-- Compatible with the project schema in database/schema.sql.
-- Demo account password: DemoPass123!

START TRANSACTION;

INSERT INTO account_statuses (status_name)
SELECT 'Active' WHERE NOT EXISTS (SELECT 1 FROM account_statuses WHERE status_name='Active');
INSERT INTO account_statuses (status_name)
SELECT 'Disabled' WHERE NOT EXISTS (SELECT 1 FROM account_statuses WHERE status_name='Disabled');

INSERT INTO order_statuses (status_name)
SELECT x.status_name FROM (
  SELECT 'Pending' status_name UNION ALL SELECT 'Processing' UNION ALL
  SELECT 'Packed' UNION ALL SELECT 'Shipped' UNION ALL SELECT 'Delivered' UNION ALL
  SELECT 'Completed' UNION ALL SELECT 'Cancelled'
) x
WHERE NOT EXISTS (SELECT 1 FROM order_statuses s WHERE s.status_name=x.status_name);

INSERT INTO payment_methods (method_name)
SELECT x.method_name FROM (
  SELECT 'Cash on Delivery' method_name UNION ALL SELECT 'E-Wallet' UNION ALL
  SELECT 'Bank Transfer' method_name UNION ALL SELECT 'Card'
) x
WHERE NOT EXISTS (SELECT 1 FROM payment_methods m WHERE m.method_name=x.method_name);

INSERT INTO users (role_name,status_id,first_name,last_name,email,password_hash,phone)
SELECT 'Customer', st.status_id, x.first_name, x.last_name, x.email,
       '$2y$12$uBlixeb3S0LgJGB8jRQIa.HJymihGgicZ5bFI6OveOZD5SgqNyggi', x.phone
FROM (
 SELECT 'Alex' first_name,'Reyes' last_name,'alex.reyes.demo@example.com' email,'09171230001' phone UNION ALL
 SELECT 'Mika','Santos','mika.santos.demo@example.com','09171230002' UNION ALL
 SELECT 'Jordan','Cruz','jordan.cruz.demo@example.com','09171230003' UNION ALL
 SELECT 'Sam','Garcia','sam.garcia.demo@example.com','09171230004' UNION ALL
 SELECT 'Taylor','Dela Cruz','taylor.delacruz.demo@example.com','09171230005' UNION ALL
 SELECT 'Casey','Mendoza','casey.mendoza.demo@example.com','09171230006'
) x
JOIN account_statuses st ON st.status_name='Active'
WHERE NOT EXISTS (SELECT 1 FROM users u WHERE u.email=x.email);

INSERT INTO addresses (user_id,recipient_name,phone,address_line1,address_line2,city,province,postal_code,is_default)
SELECT u.user_id, CONCAT(u.first_name,' ',u.last_name), u.phone,
       x.address_line1, x.address_line2, x.city, x.province, x.postal_code, 1
FROM (
 SELECT 'alex.reyes.demo@example.com' email,'Blk 12 Lot 4, Sampaguita St.' address_line1,'Barangay Central' address_line2,'Taguig City' city,'Metro Manila' province,'1630' postal_code UNION ALL
 SELECT 'mika.santos.demo@example.com','Unit 3B, 28 Rizal Ave.','Barangay Poblacion','Makati City','Metro Manila','1210' UNION ALL
 SELECT 'jordan.cruz.demo@example.com','15 Narra Street','Barangay San Isidro','Pasig City','Metro Manila','1600' UNION ALL
 SELECT 'sam.garcia.demo@example.com','22 Mabini Road','Barangay Highway Hills','Mandaluyong City','Metro Manila','1550' UNION ALL
 SELECT 'taylor.delacruz.demo@example.com','Unit 5, 8 Bonifacio St.','Barangay Fort Bonifacio','Taguig City','Metro Manila','1634' UNION ALL
 SELECT 'casey.mendoza.demo@example.com','9 Acacia Lane','Barangay Santa Cruz','Quezon City','Metro Manila','1104'
) x
JOIN users u ON u.email=x.email
WHERE NOT EXISTS (SELECT 1 FROM addresses a WHERE a.user_id=u.user_id AND a.is_default=1);

INSERT INTO orders (user_id,address_id,order_status_id,order_number,subtotal,shipping_fee,total_amount,customer_note,placed_at)
SELECT u.user_id,a.address_id,st.order_status_id,x.order_number,x.subtotal,x.shipping_fee,
       x.subtotal+x.shipping_fee,x.customer_note,x.placed_at
FROM (
 SELECT 'alex.reyes.demo@example.com' email,'ORD-20261001-A1B201' order_number,299.00 subtotal,79.00 shipping_fee,'Single-item transaction' customer_note,'2026-10-01 10:15:00' placed_at,'Delivered' status_name UNION ALL
 SELECT 'mika.santos.demo@example.com','ORD-20261003-A1B202',748.00,79.00,'Multi-item transaction: 2 units across 2 items','2026-10-03 14:20:00','Completed' UNION ALL
 SELECT 'jordan.cruz.demo@example.com','ORD-20261005-A1B203',599.00,79.00,'Single-item transaction','2026-10-05 09:30:00','Delivered' UNION ALL
 SELECT 'sam.garcia.demo@example.com','ORD-20261008-A1B204',1048.00,79.00,'Multi-item transaction: 3 units across 2 items','2026-10-08 17:45:00','Shipped' UNION ALL
 SELECT 'taylor.delacruz.demo@example.com','ORD-20261010-A1B205',449.00,79.00,'Single-item transaction','2026-10-10 11:05:00','Processing' UNION ALL
 SELECT 'casey.mendoza.demo@example.com','ORD-20261012-A1B206',898.00,79.00,'Multi-item transaction: 2 items','2026-10-12 13:10:00','Cancelled' UNION ALL
 SELECT 'alex.reyes.demo@example.com','ORD-20261015-A1B207',399.00,79.00,'Single-item transaction','2026-10-15 16:00:00','Pending' UNION ALL
 SELECT 'mika.santos.demo@example.com','ORD-20261018-A1B208',1298.00,79.00,'Multi-item transaction: 3 items','2026-10-18 12:25:00','Delivered' UNION ALL
 SELECT 'jordan.cruz.demo@example.com','ORD-20261021-A1B209',699.00,79.00,'Single-item transaction','2026-10-21 08:40:00','Packed' UNION ALL
 SELECT 'sam.garcia.demo@example.com','ORD-20261024-A1B20A',998.00,79.00,'Multi-item transaction: 2 items','2026-10-24 19:15:00','Delivered'
) x
JOIN users u ON u.email=x.email
LEFT JOIN addresses a ON a.user_id=u.user_id AND a.is_default=1
JOIN order_statuses st ON st.status_name=x.status_name
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.order_number=x.order_number);

INSERT INTO order_items (order_id,variant_id,product_name_snapshot,sku_snapshot,size_snapshot,color_snapshot,unit_price,quantity,line_total)
SELECT o.order_id,v.variant_id,p.product_name,v.sku,sz.size_name,co.color_name,x.unit_price,x.quantity,x.unit_price*x.quantity
FROM (
 SELECT 'ORD-20261001-A1B201' order_number,'basic-t-shirt' slug,299.00 unit_price,1 quantity UNION ALL
 SELECT 'ORD-20261003-A1B202','polo-shirt',449.00,1 UNION ALL
 SELECT 'ORD-20261003-A1B202','basic-t-shirt',299.00,1 UNION ALL
 SELECT 'ORD-20261005-A1B203','button-down-shirt',599.00,1 UNION ALL
 SELECT 'ORD-20261008-A1B204','hoodie',699.00,1 UNION ALL
 SELECT 'ORD-20261008-A1B204','basic-t-shirt',349.00,1 UNION ALL
 SELECT 'ORD-20261010-A1B205','polo-shirt',449.00,1 UNION ALL
 SELECT 'ORD-20261012-A1B206','slim-fit-jeans',599.00,1 UNION ALL
 SELECT 'ORD-20261012-A1B206','baseball-cap',299.00,1 UNION ALL
 SELECT 'ORD-20261015-A1B207','basic-t-shirt',399.00,1 UNION ALL
 SELECT 'ORD-20261018-A1B208','hoodie',699.00,1 UNION ALL
 SELECT 'ORD-20261018-A1B208','polo-shirt',449.00,1 UNION ALL
 SELECT 'ORD-20261018-A1B208','baseball-cap',150.00,1 UNION ALL
 SELECT 'ORD-20261021-A1B209','slim-fit-jeans',699.00,1 UNION ALL
 SELECT 'ORD-20261024-A1B20A','button-down-shirt',599.00,1 UNION ALL
 SELECT 'ORD-20261024-A1B20A','basic-t-shirt',399.00,1
) x
JOIN orders o ON o.order_number=x.order_number
JOIN products p ON p.slug=x.slug
JOIN product_variants v ON v.product_id=p.product_id
  AND v.variant_id=(SELECT MIN(v2.variant_id) FROM product_variants v2 WHERE v2.product_id=p.product_id)
LEFT JOIN sizes sz ON sz.size_id=v.size_id
LEFT JOIN colors co ON co.color_id=v.color_id
WHERE NOT EXISTS (
    SELECT 1 FROM order_items oi
    WHERE oi.order_id=o.order_id AND oi.product_name_snapshot=p.product_name
);

UPDATE orders o SET
  o.subtotal=(SELECT COALESCE(SUM(oi.line_total),0) FROM order_items oi WHERE oi.order_id=o.order_id),
  o.total_amount=(SELECT COALESCE(SUM(oi.line_total),0) FROM order_items oi WHERE oi.order_id=o.order_id) + o.shipping_fee
WHERE o.order_number LIKE 'ORD-202610%-A1B2%';

INSERT INTO payments (order_id,payment_method_id,amount,payment_status,reference_number,paid_at)
SELECT o.order_id,pm.payment_method_id,o.total_amount,
 CASE WHEN os.status_name IN ('Delivered','Completed') THEN 'paid'
      WHEN os.status_name='Cancelled' THEN 'refunded'
      ELSE 'pending' END,
 CASE WHEN os.status_name IN ('Delivered','Completed') THEN CONCAT('PAY-',RIGHT(o.order_number,6)) ELSE NULL END,
 CASE WHEN os.status_name IN ('Delivered','Completed') THEN o.placed_at ELSE NULL END
FROM orders o
JOIN order_statuses os ON os.order_status_id=o.order_status_id
JOIN payment_methods pm ON pm.method_name=CASE MOD(o.order_id,3)
    WHEN 0 THEN 'E-Wallet'
    WHEN 1 THEN 'Cash on Delivery'
    ELSE 'Bank Transfer'
  END
WHERE o.order_number LIKE 'ORD-202610%-A1B2%'
AND NOT EXISTS (SELECT 1 FROM payments p WHERE p.order_id=o.order_id);

INSERT INTO order_status_history (order_id,order_status_id,changed_by,note,changed_at)
SELECT o.order_id,o.order_status_id,NULL,CONCAT('Sample data status: ',s.status_name),o.placed_at
FROM orders o
JOIN order_statuses s ON s.order_status_id=o.order_status_id
WHERE o.order_number LIKE 'ORD-202610%-A1B2%'
AND NOT EXISTS (SELECT 1 FROM order_status_history h WHERE h.order_id=o.order_id);

INSERT INTO expenses (recorded_by,expense_name,amount,expense_date,notes)
SELECT NULL,x.expense_name,x.amount,x.expense_date,x.notes
FROM (
 SELECT 'Packaging materials' expense_name,1850.00 amount,'2026-10-02' expense_date,'Boxes, mailers, tape, and labels for demo orders' notes UNION ALL
 SELECT 'Courier pickup fees',1260.00,'2026-10-06','Sample logistics expense' UNION ALL
 SELECT 'Product photography',3500.00,'2026-10-09','Catalog photo shoot expense' UNION ALL
 SELECT 'Store internet',1499.00,'2026-10-12','Monthly connectivity expense' UNION ALL
 SELECT 'Packaging materials',980.00,'2026-10-16','Restock of packaging supplies' UNION ALL
 SELECT 'Online promotion',2200.00,'2026-10-20','Sample social media promotion expense' UNION ALL
 SELECT 'Courier pickup fees',1640.00,'2026-10-25','Sample logistics expense'
) x
WHERE NOT EXISTS (
    SELECT 1 FROM expenses e
    WHERE e.expense_name=x.expense_name AND e.expense_date=x.expense_date AND e.amount=x.amount
);

INSERT INTO inventory_transactions (variant_id,changed_by,quantity_change,reason,reference_text,created_at)
SELECT v.variant_id,NULL,x.quantity_change,x.reason,x.reference_text,x.created_at
FROM (
 SELECT 'basic-t-shirt' slug,5 quantity_change,'INITIAL_STOCK' reason,'DEMO-STOCK-RECEIPT-001' reference_text,'2026-10-01 09:00:00' created_at UNION ALL
 SELECT 'polo-shirt',-1,'SALE','DEMO-STOCK-SALE-002','2026-10-03 14:20:00' UNION ALL
 SELECT 'hoodie',-1,'SALE','DEMO-STOCK-SALE-004','2026-10-08 17:45:00' UNION ALL
 SELECT 'slim-fit-jeans',-1,'SALE','DEMO-STOCK-SALE-006','2026-10-12 13:10:00' UNION ALL
 SELECT 'baseball-cap',10,'RESTOCK','DEMO-STOCK-RECEIPT-002','2026-10-15 10:00:00'
) x
JOIN products p ON p.slug=x.slug
JOIN product_variants v ON v.product_id=p.product_id
  AND v.variant_id=(SELECT MIN(v2.variant_id) FROM product_variants v2 WHERE v2.product_id=p.product_id)
WHERE NOT EXISTS (
    SELECT 1 FROM inventory_transactions it
    WHERE it.reference_text=x.reference_text AND it.variant_id=v.variant_id
);

COMMIT;


-- ===== Source: database\migrations\007_complete_transactions.sql =====
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


-- ===== Source: database\migrations\008_auto_record_sales_from_completed_transactions.sql =====
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


-- ===== Source: database\migrations\009_reconcile_completed_sales.sql =====
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


-- ===== Source: database\migrations\010_standardize_sample_order_numbers.sql =====
-- Align seeded sample order numbers with the format used by checkout.

START TRANSACTION;

UPDATE orders
SET order_number = CASE order_number
    WHEN 'DEMO-SAMPLE-ORD-001' THEN 'ORD-20261001-A1B201'
    WHEN 'DEMO-SAMPLE-ORD-002' THEN 'ORD-20261003-A1B202'
    WHEN 'DEMO-SAMPLE-ORD-003' THEN 'ORD-20261005-A1B203'
    WHEN 'DEMO-SAMPLE-ORD-004' THEN 'ORD-20261008-A1B204'
    WHEN 'DEMO-SAMPLE-ORD-005' THEN 'ORD-20261010-A1B205'
    WHEN 'DEMO-SAMPLE-ORD-006' THEN 'ORD-20261012-A1B206'
    WHEN 'DEMO-SAMPLE-ORD-007' THEN 'ORD-20261015-A1B207'
    WHEN 'DEMO-SAMPLE-ORD-008' THEN 'ORD-20261018-A1B208'
    WHEN 'DEMO-SAMPLE-ORD-009' THEN 'ORD-20261021-A1B209'
    WHEN 'DEMO-SAMPLE-ORD-010' THEN 'ORD-20261024-A1B20A'
END
WHERE order_number IN (
    'DEMO-SAMPLE-ORD-001',
    'DEMO-SAMPLE-ORD-002',
    'DEMO-SAMPLE-ORD-003',
    'DEMO-SAMPLE-ORD-004',
    'DEMO-SAMPLE-ORD-005',
    'DEMO-SAMPLE-ORD-006',
    'DEMO-SAMPLE-ORD-007',
    'DEMO-SAMPLE-ORD-008',
    'DEMO-SAMPLE-ORD-009',
    'DEMO-SAMPLE-ORD-010'
);

UPDATE payments p
JOIN orders o ON o.order_id = p.order_id
SET p.reference_number = CONCAT('PAY-', RIGHT(o.order_number, 6))
WHERE o.order_number IN (
    'ORD-20261001-A1B201',
    'ORD-20261003-A1B202',
    'ORD-20261005-A1B203',
    'ORD-20261008-A1B204',
    'ORD-20261010-A1B205',
    'ORD-20261012-A1B206',
    'ORD-20261015-A1B207',
    'ORD-20261018-A1B208',
    'ORD-20261021-A1B209',
    'ORD-20261024-A1B20A'
)
AND p.reference_number IS NOT NULL;

COMMIT;
