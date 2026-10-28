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

INSERT INTO addresses (user_id,recipient_name,phone,address_line1,city,province,postal_code,is_default)
SELECT u.user_id, CONCAT(u.first_name,' ',u.last_name), u.phone,
       x.address_line1, x.city, x.province, x.postal_code, 1
FROM (
 SELECT 'alex.reyes.demo@example.com' email,'Blk 12 Lot 4, Sampaguita St.' address_line1,'Taguig City' city,'Metro Manila' province,'1630' postal_code UNION ALL
 SELECT 'mika.santos.demo@example.com','Unit 3B, 28 Rizal Ave.','Makati City','Metro Manila','1210' UNION ALL
 SELECT 'jordan.cruz.demo@example.com','15 Narra Street','Pasig City','Metro Manila','1600' UNION ALL
 SELECT 'sam.garcia.demo@example.com','22 Mabini Road','Mandaluyong City','Metro Manila','1550' UNION ALL
 SELECT 'taylor.delacruz.demo@example.com','Unit 5, 8 Bonifacio St.','Taguig City','Metro Manila','1634' UNION ALL
 SELECT 'casey.mendoza.demo@example.com','9 Acacia Lane','Quezon City','Metro Manila','1104'
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

INSERT INTO payments (order_id,payment_method_id,amount,payment_status)
SELECT o.order_id,pm.payment_method_id,o.total_amount,
 CASE WHEN os.status_name IN ('Delivered','Completed') THEN 'paid'
      WHEN os.status_name='Cancelled' THEN 'refunded'
      ELSE 'pending' END
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

-- Align seeded sample order numbers with the format used by checkout.
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

COMMIT;
