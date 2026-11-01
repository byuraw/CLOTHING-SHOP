USE clothing_store_fixed;

-- STEP 1: run this SELECT first. It MUST return 0 rows.
-- Any row returned is a product with no variants, which would have no price after the migration.
SELECT p.product_id, p.product_name
FROM products p
LEFT JOIN product_variants pv ON pv.product_id = p.product_id
WHERE pv.variant_id IS NULL;

-- STEP 2: only if STEP 1 returned 0 rows. The CHECK constraint must be dropped before the column.
ALTER TABLE products DROP CONSTRAINT chk_products_price;
ALTER TABLE products DROP COLUMN base_price;
