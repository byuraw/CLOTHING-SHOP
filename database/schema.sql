CREATE DATABASE IF NOT EXISTS clothing_store_fixed CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE clothing_store_fixed;

CREATE TABLE roles (
  role_id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  role_name VARCHAR(30) NOT NULL UNIQUE
) ENGINE = InnoDB;

CREATE TABLE account_statuses (
  status_id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  status_name VARCHAR(30) NOT NULL UNIQUE
) ENGINE = InnoDB;

CREATE TABLE users (
  user_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  role_id TINYINT UNSIGNED NOT NULL,
  status_id TINYINT UNSIGNED NOT NULL,
  username VARCHAR(50) NULL UNIQUE,
  first_name VARCHAR(80) NOT NULL,
  last_name VARCHAR(80) NOT NULL,
  email VARCHAR(190) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  phone VARCHAR(30) NULL,
  profile_photo VARCHAR(255) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES roles (role_id),
  CONSTRAINT fk_users_status FOREIGN KEY (status_id) REFERENCES account_statuses (status_id)
) ENGINE = InnoDB;

CREATE TABLE addresses (
  address_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  recipient_name VARCHAR(160) NOT NULL,
  phone VARCHAR(30) NOT NULL,
  address_line1 VARCHAR(190) NOT NULL,
  address_line2 VARCHAR(190) NULL,
  city VARCHAR(100) NOT NULL,
  province VARCHAR(100) NOT NULL,
  postal_code VARCHAR(20) NOT NULL,
  is_default TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE,
  INDEX idx_addresses_user_default (user_id, is_default)
) ENGINE = InnoDB;

CREATE TABLE product_categories (
  product_category_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  category_name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1
) ENGINE = InnoDB;

CREATE TABLE product_types (
  product_type_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  type_name VARCHAR(100) NOT NULL UNIQUE
) ENGINE = InnoDB;

INSERT INTO product_categories (category_name)
VALUES ("Men's Clothing"), ("Women's Clothing");

INSERT INTO product_types (type_name)
VALUES ('Top'), ('Bottom'), ('Headwear');

CREATE TABLE products (
  product_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_category_id INT UNSIGNED NOT NULL,
  product_type_id INT UNSIGNED NOT NULL,
  product_name VARCHAR(180) NOT NULL,
  slug VARCHAR(200) NOT NULL UNIQUE,
  description TEXT NULL,
  base_price DECIMAL(10, 2) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT chk_products_price CHECK (base_price >= 0),
  FOREIGN KEY (product_category_id) REFERENCES product_categories (product_category_id),
  FOREIGN KEY (product_type_id) REFERENCES product_types (product_type_id),
  INDEX idx_products_active_category (is_active, product_category_id)
) ENGINE = InnoDB;

CREATE TABLE product_images (
  image_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  image_path VARCHAR(255) NOT NULL,
  alt_text VARCHAR(190) NULL,
  sort_order SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  FOREIGN KEY (product_id) REFERENCES products (product_id) ON DELETE CASCADE,
  INDEX idx_images_product_order (product_id, sort_order)
) ENGINE = InnoDB;

CREATE TABLE sizes (
  size_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  size_name VARCHAR(30) NOT NULL UNIQUE
) ENGINE = InnoDB;

CREATE TABLE colors (
  color_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  color_name VARCHAR(50) NOT NULL UNIQUE,
  color_code CHAR(7) NULL
) ENGINE = InnoDB;

CREATE TABLE product_variants (
  variant_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  size_id SMALLINT UNSIGNED NULL,
  color_id SMALLINT UNSIGNED NULL,
  sku VARCHAR(80) NOT NULL UNIQUE,
  price DECIMAL(10, 2) NOT NULL,
  stock_quantity INT UNSIGNED NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  CHECK (price >= 0),
  FOREIGN KEY (product_id) REFERENCES products (product_id) ON DELETE CASCADE,
  FOREIGN KEY (size_id) REFERENCES sizes (size_id) ON DELETE SET NULL,
  FOREIGN KEY (color_id) REFERENCES colors (color_id) ON DELETE SET NULL,
  UNIQUE KEY uq_variant_options (product_id, size_id, color_id),
  INDEX idx_variants_stock (product_id, is_active, stock_quantity)
) ENGINE = InnoDB;

CREATE TABLE cart_items (
  cart_item_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  variant_id BIGINT UNSIGNED NOT NULL,
  quantity INT UNSIGNED NOT NULL,
  added_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CHECK (quantity > 0),
  FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE,
  FOREIGN KEY (variant_id) REFERENCES product_variants (variant_id),
  UNIQUE KEY uq_cart_user_variant (user_id, variant_id)
) ENGINE = InnoDB;

CREATE TABLE order_statuses (
  order_status_id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  status_name VARCHAR(30) NOT NULL UNIQUE
) ENGINE = InnoDB;

CREATE TABLE orders (
  order_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  address_id BIGINT UNSIGNED NULL,
  order_status_id TINYINT UNSIGNED NOT NULL,
  order_number VARCHAR(40) NOT NULL UNIQUE,
  subtotal DECIMAL(10, 2) NOT NULL,
  shipping_fee DECIMAL(10, 2) NOT NULL DEFAULT 0,
  total_amount DECIMAL(10, 2) NOT NULL,
  customer_note VARCHAR(500) NULL,
  placed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CHECK (
    subtotal >= 0
    AND shipping_fee >= 0
    AND total_amount >= 0
  ),
  FOREIGN KEY (user_id) REFERENCES users (user_id),
  FOREIGN KEY (address_id) REFERENCES addresses (address_id) ON DELETE SET NULL,
  FOREIGN KEY (order_status_id) REFERENCES order_statuses (order_status_id),
  INDEX idx_orders_user_date (user_id, placed_at),
  INDEX idx_orders_status_date (order_status_id, placed_at)
) ENGINE = InnoDB;

CREATE TABLE order_items (
  order_item_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_id BIGINT UNSIGNED NOT NULL,
  variant_id BIGINT UNSIGNED NULL,
  product_name_snapshot VARCHAR(180) NOT NULL,
  sku_snapshot VARCHAR(80) NULL,
  size_snapshot VARCHAR(30) NULL,
  color_snapshot VARCHAR(50) NULL,
  unit_price DECIMAL(10, 2) NOT NULL,
  quantity INT UNSIGNED NOT NULL,
  line_total DECIMAL(10, 2) NOT NULL,
  CHECK (
    unit_price >= 0
    AND quantity > 0
    AND line_total >= 0
  ),
  FOREIGN KEY (order_id) REFERENCES orders (order_id) ON DELETE CASCADE,
  FOREIGN KEY (variant_id) REFERENCES product_variants (variant_id) ON DELETE SET NULL,
  INDEX idx_order_items_order (order_id)
) ENGINE = InnoDB;

CREATE TABLE payment_methods (
  payment_method_id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  method_name VARCHAR(40) NOT NULL UNIQUE
) ENGINE = InnoDB;

CREATE TABLE payments (
  payment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_id BIGINT UNSIGNED NOT NULL,
  payment_method_id TINYINT UNSIGNED NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  payment_status ENUM('pending', 'paid', 'failed', 'refunded') NOT NULL DEFAULT 'pending',
  reference_number VARCHAR(100) NULL,
  paid_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (amount >= 0),
  FOREIGN KEY (order_id) REFERENCES orders (order_id) ON DELETE CASCADE,
  FOREIGN KEY (payment_method_id) REFERENCES payment_methods (payment_method_id),
  INDEX idx_payments_order_status (order_id, payment_status)
) ENGINE = InnoDB;

CREATE TABLE order_status_history (
  history_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_id BIGINT UNSIGNED NOT NULL,
  order_status_id TINYINT UNSIGNED NOT NULL,
  changed_by BIGINT UNSIGNED NULL,
  note VARCHAR(500) NULL,
  changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (order_id) REFERENCES orders (order_id) ON DELETE CASCADE,
  FOREIGN KEY (order_status_id) REFERENCES order_statuses (order_status_id),
  FOREIGN KEY (changed_by) REFERENCES users (user_id) ON DELETE SET NULL,
  INDEX idx_history_order_time (order_id, changed_at)
) ENGINE = InnoDB;

CREATE TABLE inventory_transactions (
  inventory_transaction_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  variant_id BIGINT UNSIGNED NOT NULL,
  changed_by BIGINT UNSIGNED NULL,
  quantity_change INT NOT NULL,
  reference_text VARCHAR(100) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (variant_id) REFERENCES product_variants (variant_id),
  FOREIGN KEY (changed_by) REFERENCES users (user_id) ON DELETE SET NULL,
  INDEX idx_inventory_variant_time (variant_id, created_at)
) ENGINE = InnoDB;

CREATE TABLE expenses (
  expense_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  recorded_by BIGINT UNSIGNED NULL,
  expense_name VARCHAR(180) NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  expense_date DATE NOT NULL,
  notes VARCHAR(500) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (amount >= 0),
  FOREIGN KEY (recorded_by) REFERENCES users (user_id) ON DELETE SET NULL,
  INDEX idx_expenses_date (expense_date)
) ENGINE = InnoDB;

INSERT INTO
  roles (role_name)
VALUES
  ('Customer'),
  ('Admin');

INSERT INTO
  account_statuses (status_name)
VALUES
  ('Active'),
  ('Disabled');

INSERT INTO users (
  username,
  first_name,
  last_name,
  email,
  password_hash,
  role_id,
  status_id
)
SELECT
  'admin',
  'Admin',
  'Account',
  'admin@example.com',
  '$2y$10$.swgQnJFoU16vz1MuG5R5uAFsDRhHdNiqSsm9JfgbZza8ZCOUklhm',
  r.role_id,
  s.status_id
FROM roles r
CROSS JOIN account_statuses s
WHERE r.role_name = 'Admin'
  AND s.status_name = 'Active'
  AND NOT EXISTS (
    SELECT 1
    FROM users
    WHERE username = 'admin'
      OR email = 'admin@example.com'
  );

INSERT INTO
  order_statuses (status_name)
VALUES
  ('Pending'),
  ('Processing'),
  ('Packed'),
  ('Shipped'),
  ('Delivered'),
  ('Completed'),
  ('Cancelled');

INSERT INTO
  payment_methods (method_name)
VALUES
  ('Cash on Delivery'),
  ('Bank Transfer'),
  ('E-Wallet');

INSERT INTO
  sizes (size_id, size_name)
VALUES
  (1, 'XS'),
  (2, 'S'),
  (3, 'M'),
  (4, 'L'),
  (5, 'XL'),
  (6, 'XXL'),
  (7, 'One Size');

INSERT INTO
  colors (color_id, color_name, color_code)
VALUES
  (1, 'Black', '#000000'),
  (2, 'White', '#FFFFFF'),
  (3, 'Blue', '#0000FF');

CREATE TABLE product_reviews (
  review_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  order_item_id BIGINT UNSIGNED NOT NULL,
  rating TINYINT UNSIGNED NOT NULL,
  review_text TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CHECK (rating BETWEEN 1 AND 5),
  FOREIGN KEY (product_id) REFERENCES products (product_id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE,
  FOREIGN KEY (order_item_id) REFERENCES order_items (order_item_id) ON DELETE CASCADE,
  UNIQUE KEY uq_review_user_order_item (user_id, order_item_id),
  INDEX idx_reviews_product (product_id, created_at)
) ENGINE = InnoDB;

CREATE OR REPLACE VIEW vw_order_transaction_details AS
SELECT
  o.order_id,
  o.order_number,
  o.placed_at,
  o.subtotal,
  o.shipping_fee,
  o.total_amount,
  os.status_name,
  u.user_id,
  u.first_name,
  u.last_name,
  u.email,
  oi.order_item_id,
  oi.product_name_snapshot,
  oi.sku_snapshot,
  oi.size_snapshot,
  oi.color_snapshot,
  oi.unit_price,
  oi.quantity,
  oi.line_total
FROM
  orders o
  JOIN users u ON u.user_id = o.user_id
  JOIN order_statuses os ON os.order_status_id = o.order_status_id
  JOIN order_items oi ON oi.order_id = o.order_id;
