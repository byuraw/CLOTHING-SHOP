USE clothing_store_fixed;

START TRANSACTION;

DROP VIEW IF EXISTS vw_order_transaction_details;
DROP TABLE IF EXISTS complete_transactions;
DROP TRIGGER IF EXISTS trg_complete_transaction_to_sales;

ALTER TABLE addresses DROP COLUMN IF EXISTS address_line2;
ALTER TABLE colors DROP COLUMN IF EXISTS color_code;
ALTER TABLE payments DROP COLUMN IF EXISTS reference_number;
ALTER TABLE payments DROP COLUMN IF EXISTS paid_at;

COMMIT;
