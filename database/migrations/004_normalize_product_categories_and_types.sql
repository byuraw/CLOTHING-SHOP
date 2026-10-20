CREATE TABLE product_categories (
  product_category_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  category_name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1
) ENGINE = InnoDB;

INSERT INTO product_categories (category_name)
VALUES ('Men''s Clothing'), ('Women''s Clothing');

INSERT INTO product_types (type_name)
VALUES ('Top'), ('Bottom'), ('Headwear')
ON DUPLICATE KEY UPDATE type_name = VALUES(type_name);

ALTER TABLE products
  ADD COLUMN product_category_id INT UNSIGNED NULL AFTER category_id;

UPDATE products p
JOIN categories c ON c.category_id = p.category_id
JOIN product_categories pc
  ON pc.category_name = CASE
    WHEN c.category_name LIKE 'Men''s %' THEN 'Men''s Clothing'
    WHEN c.category_name LIKE 'Women''s %' THEN 'Women''s Clothing'
  END
JOIN product_types pt
  ON pt.type_name = CASE
    WHEN c.category_name LIKE '% Tops' THEN 'Top'
    WHEN c.category_name LIKE '% Bottoms' THEN 'Bottom'
    WHEN c.category_name LIKE '% Headwear' THEN 'Headwear'
  END
SET p.product_category_id = pc.product_category_id,
    p.product_type_id = pt.product_type_id;

ALTER TABLE products
  DROP FOREIGN KEY products_ibfk_1,
  DROP INDEX idx_products_active_category,
  DROP INDEX category_id,
  DROP COLUMN category_id,
  MODIFY product_category_id INT UNSIGNED NOT NULL,
  MODIFY product_type_id INT UNSIGNED NOT NULL,
  ADD INDEX idx_products_active_category (is_active, product_category_id),
  ADD CONSTRAINT fk_products_product_category
    FOREIGN KEY (product_category_id)
    REFERENCES product_categories (product_category_id),
  DROP FOREIGN KEY products_ibfk_2,
  ADD CONSTRAINT fk_products_product_type
    FOREIGN KEY (product_type_id)
    REFERENCES product_types (product_type_id);

ALTER TABLE product_types
  DROP FOREIGN KEY product_types_ibfk_1,
  DROP INDEX category_id,
  DROP COLUMN category_id;

DELETE FROM product_types
WHERE type_name NOT IN ('Top', 'Bottom', 'Headwear')
  AND product_type_id NOT IN (
    SELECT product_type_id
    FROM products
  );

DROP TABLE categories;
