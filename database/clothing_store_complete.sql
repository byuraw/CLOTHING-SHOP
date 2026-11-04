/*
  Wearwell Clothing Store complete database import
  Date: 2026-11-03
  Import with phpMyAdmin or the MySQL client. This file creates missing tables
  in clothing_store_fixed and reloads the corrected backup data. Back up first.
*/
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS=0;
CREATE DATABASE IF NOT EXISTS clothing_store_fixed CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE clothing_store_fixed;

DROP VIEW IF EXISTS `vw_order_transaction_details`;
DROP TRIGGER IF EXISTS `trg_orders_insert_completed_sale`;
DROP TRIGGER IF EXISTS `trg_orders_completed_to_sale`;
CREATE TABLE IF NOT EXISTS `account_statuses` (
  `status_id` tinyint(3) unsigned NOT NULL AUTO_INCREMENT,
  `status_name` varchar(30) NOT NULL,
  PRIMARY KEY (`status_id`),
  UNIQUE KEY `status_name` (`status_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `product_categories` (
  `product_category_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `category_name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`product_category_id`),
  UNIQUE KEY `category_name` (`category_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `product_types` (
  `product_type_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `type_name` varchar(100) NOT NULL,
  PRIMARY KEY (`product_type_id`),
  UNIQUE KEY `type_name` (`type_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sizes` (
  `size_id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `size_name` varchar(30) NOT NULL,
  PRIMARY KEY (`size_id`),
  UNIQUE KEY `size_name` (`size_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `colors` (
  `color_id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `color_name` varchar(50) NOT NULL,
  PRIMARY KEY (`color_id`),
  UNIQUE KEY `color_name` (`color_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `order_statuses` (
  `order_status_id` tinyint(3) unsigned NOT NULL AUTO_INCREMENT,
  `status_name` varchar(30) NOT NULL,
  PRIMARY KEY (`order_status_id`),
  UNIQUE KEY `status_name` (`status_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `users` (
  `user_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `role_name` enum('Customer','Admin') NOT NULL DEFAULT 'Customer',
  `status_id` tinyint(3) unsigned NOT NULL,
  `first_name` varchar(80) NOT NULL,
  `last_name` varchar(80) NOT NULL,
  `email` varchar(190) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `phone` varchar(30) DEFAULT NULL,
  `profile_photo` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `email` (`email`),
  KEY `fk_users_status` (`status_id`),
  CONSTRAINT `fk_users_status` FOREIGN KEY (`status_id`) REFERENCES `account_statuses` (`status_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `addresses` (
  `address_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) unsigned NOT NULL,
  `recipient_name` varchar(160) NOT NULL,
  `phone` varchar(30) NOT NULL,
  `address_line1` varchar(190) NOT NULL,
  `city` varchar(100) NOT NULL,
  `province` varchar(100) NOT NULL,
  `postal_code` varchar(20) NOT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`address_id`),
  KEY `idx_addresses_user_default` (`user_id`,`is_default`),
  CONSTRAINT `addresses_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `products` (
  `product_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `product_category_id` int(10) unsigned NOT NULL,
  `product_type_id` int(10) unsigned NOT NULL,
  `product_name` varchar(180) NOT NULL,
  `slug` varchar(200) NOT NULL,
  `description` text DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`product_id`),
  UNIQUE KEY `slug` (`slug`),
  KEY `product_category_id` (`product_category_id`),
  KEY `product_type_id` (`product_type_id`),
  KEY `idx_products_active_category` (`is_active`,`product_category_id`),
  CONSTRAINT `products_ibfk_1` FOREIGN KEY (`product_category_id`) REFERENCES `product_categories` (`product_category_id`),
  CONSTRAINT `products_ibfk_2` FOREIGN KEY (`product_type_id`) REFERENCES `product_types` (`product_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `product_images` (
  `image_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `product_id` bigint(20) unsigned NOT NULL,
  `image_path` varchar(255) NOT NULL,
  `alt_text` varchar(190) DEFAULT NULL,
  `sort_order` smallint(5) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`image_id`),
  KEY `idx_images_product_order` (`product_id`,`sort_order`),
  CONSTRAINT `product_images_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `product_variants` (
  `variant_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `product_id` bigint(20) unsigned NOT NULL,
  `size_id` smallint(5) unsigned DEFAULT NULL,
  `color_id` smallint(5) unsigned DEFAULT NULL,
  `sku` varchar(80) NOT NULL,
  `price` decimal(10,2) NOT NULL,
  `stock_quantity` int(10) unsigned NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`variant_id`),
  UNIQUE KEY `sku` (`sku`),
  UNIQUE KEY `uq_variant_options` (`product_id`,`size_id`,`color_id`),
  KEY `size_id` (`size_id`),
  KEY `color_id` (`color_id`),
  KEY `idx_variants_stock` (`product_id`,`is_active`,`stock_quantity`),
  CONSTRAINT `product_variants_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE,
  CONSTRAINT `product_variants_ibfk_2` FOREIGN KEY (`size_id`) REFERENCES `sizes` (`size_id`) ON DELETE SET NULL,
  CONSTRAINT `product_variants_ibfk_3` FOREIGN KEY (`color_id`) REFERENCES `colors` (`color_id`) ON DELETE SET NULL,
  CONSTRAINT `CONSTRAINT_1` CHECK (`price` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `orders` (
  `order_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) unsigned NOT NULL,
  `address_id` bigint(20) unsigned DEFAULT NULL,
  `order_status_id` tinyint(3) unsigned NOT NULL,
  `order_number` varchar(40) NOT NULL,
  `subtotal` decimal(10,2) NOT NULL,
  `total_amount` decimal(10,2) NOT NULL,
  `customer_note` varchar(500) DEFAULT NULL,
  `placed_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`order_id`),
  UNIQUE KEY `order_number` (`order_number`),
  KEY `address_id` (`address_id`),
  KEY `idx_orders_user_date` (`user_id`,`placed_at`),
  KEY `idx_orders_status_date` (`order_status_id`,`placed_at`),
  CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`),
  CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`address_id`) REFERENCES `addresses` (`address_id`) ON DELETE SET NULL,
  CONSTRAINT `orders_ibfk_3` FOREIGN KEY (`order_status_id`) REFERENCES `order_statuses` (`order_status_id`),
  CONSTRAINT `chk_orders_amounts` CHECK (`subtotal` >= 0 AND `total_amount` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `order_items` (
  `order_item_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` bigint(20) unsigned NOT NULL,
  `variant_id` bigint(20) unsigned DEFAULT NULL,
  `product_name_snapshot` varchar(180) NOT NULL,
  `sku_snapshot` varchar(80) DEFAULT NULL,
  `size_snapshot` varchar(30) DEFAULT NULL,
  `color_snapshot` varchar(50) DEFAULT NULL,
  `unit_price` decimal(10,2) NOT NULL,
  `quantity` int(10) unsigned NOT NULL,
  `line_total` decimal(10,2) NOT NULL,
  PRIMARY KEY (`order_item_id`),
  KEY `variant_id` (`variant_id`),
  KEY `idx_order_items_order` (`order_id`),
  CONSTRAINT `order_items_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE,
  CONSTRAINT `order_items_ibfk_2` FOREIGN KEY (`variant_id`) REFERENCES `product_variants` (`variant_id`) ON DELETE SET NULL,
  CONSTRAINT `CONSTRAINT_1` CHECK (`unit_price` >= 0 and `quantity` > 0 and `line_total` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `payments` (
  `payment_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` bigint(20) unsigned NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `payment_status` enum('pending','paid','failed','refunded') NOT NULL DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`payment_id`),
  KEY `idx_payments_order_status` (`order_id`,`payment_status`),
  CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE,
  CONSTRAINT `CONSTRAINT_1` CHECK (`amount` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sales` (
  `sale_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` bigint(20) unsigned NOT NULL,
  `transaction_reference` varchar(80) NOT NULL,
  `total_amount` decimal(10,2) NOT NULL,
  `sale_date` timestamp NOT NULL DEFAULT current_timestamp(),
  `notes` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`sale_id`),
  UNIQUE KEY `order_id` (`order_id`),
  UNIQUE KEY `transaction_reference` (`transaction_reference`),
  KEY `idx_sales_date` (`sale_date`),
  CONSTRAINT `sales_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE,
  CONSTRAINT `CONSTRAINT_1` CHECK (`total_amount` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `expenses` (
  `expense_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `recorded_by` bigint(20) unsigned DEFAULT NULL,
  `expense_name` varchar(180) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `expense_date` date NOT NULL,
  `notes` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`expense_id`),
  KEY `recorded_by` (`recorded_by`),
  KEY `idx_expenses_date` (`expense_date`),
  CONSTRAINT `expenses_ibfk_1` FOREIGN KEY (`recorded_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  CONSTRAINT `CONSTRAINT_1` CHECK (`amount` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `cart_items` (
  `cart_item_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) unsigned NOT NULL,
  `variant_id` bigint(20) unsigned NOT NULL,
  `quantity` int(10) unsigned NOT NULL,
  `added_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`cart_item_id`),
  UNIQUE KEY `uq_cart_user_variant` (`user_id`,`variant_id`),
  KEY `variant_id` (`variant_id`),
  CONSTRAINT `cart_items_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `cart_items_ibfk_2` FOREIGN KEY (`variant_id`) REFERENCES `product_variants` (`variant_id`),
  CONSTRAINT `CONSTRAINT_1` CHECK (`quantity` > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `product_reviews` (
  `review_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `product_id` bigint(20) unsigned NOT NULL,
  `user_id` bigint(20) unsigned NOT NULL,
  `order_item_id` bigint(20) unsigned NOT NULL,
  `rating` tinyint(3) unsigned NOT NULL,
  `review_text` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`review_id`),
  UNIQUE KEY `uq_review_user_order_item` (`user_id`,`order_item_id`),
  UNIQUE KEY uq_review_user_product (user_id,product_id),
  KEY `order_item_id` (`order_item_id`),
  KEY `idx_reviews_product` (`product_id`,`created_at`),
  CONSTRAINT `product_reviews_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE,
  CONSTRAINT `product_reviews_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `product_reviews_ibfk_3` FOREIGN KEY (`order_item_id`) REFERENCES `order_items` (`order_item_id`) ON DELETE CASCADE,
  CONSTRAINT `CONSTRAINT_1` CHECK (`rating` between 1 and 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Reload the seed data without dropping any table objects.
DELETE FROM `product_reviews`;
DELETE FROM `cart_items`;
DELETE FROM `expenses`;
DELETE FROM `sales`;
DELETE FROM `payments`;
DELETE FROM `order_items`;
DELETE FROM `orders`;
DELETE FROM `product_variants`;
DELETE FROM `product_images`;
DELETE FROM `addresses`;
DELETE FROM `products`;
DELETE FROM `users`;
DELETE FROM `order_statuses`;
DELETE FROM `colors`;
DELETE FROM `sizes`;
DELETE FROM `product_types`;
DELETE FROM `product_categories`;
DELETE FROM `account_statuses`;

ALTER TABLE `account_statuses` AUTO_INCREMENT=1;
ALTER TABLE `product_categories` AUTO_INCREMENT=1;
ALTER TABLE `product_types` AUTO_INCREMENT=1;
ALTER TABLE `sizes` AUTO_INCREMENT=1;
ALTER TABLE `colors` AUTO_INCREMENT=1;
ALTER TABLE `order_statuses` AUTO_INCREMENT=1;
ALTER TABLE `users` AUTO_INCREMENT=1;
ALTER TABLE `addresses` AUTO_INCREMENT=1;
ALTER TABLE `products` AUTO_INCREMENT=1;
ALTER TABLE `product_images` AUTO_INCREMENT=1;
ALTER TABLE `product_variants` AUTO_INCREMENT=1;
ALTER TABLE `orders` AUTO_INCREMENT=1;
ALTER TABLE `order_items` AUTO_INCREMENT=1;
ALTER TABLE `payments` AUTO_INCREMENT=1;
ALTER TABLE `sales` AUTO_INCREMENT=1;
ALTER TABLE `expenses` AUTO_INCREMENT=1;
ALTER TABLE `cart_items` AUTO_INCREMENT=1;
ALTER TABLE `product_reviews` AUTO_INCREMENT=1;

-- Order transaction details view.
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
INNER JOIN users u ON u.user_id=o.user_id
INNER JOIN order_statuses os ON os.order_status_id=o.order_status_id
INNER JOIN order_items oi ON oi.order_id=o.order_id;

-- Backup data (explicit columns, FK-safe order).
INSERT INTO `account_statuses` (`status_id`, `status_name`) VALUES (1,'Active');
INSERT INTO `account_statuses` (`status_id`, `status_name`) VALUES (2,'Disabled');
INSERT INTO `product_categories` (`product_category_id`, `category_name`, `description`, `is_active`) VALUES (1,'Men\'s Clothing',NULL,1);
INSERT INTO `product_categories` (`product_category_id`, `category_name`, `description`, `is_active`) VALUES (2,'Women\'s Clothing',NULL,1);
INSERT INTO `product_types` (`product_type_id`, `type_name`) VALUES (2,'Bottom');
INSERT INTO `product_types` (`product_type_id`, `type_name`) VALUES (3,'Headwear');
INSERT INTO `product_types` (`product_type_id`, `type_name`) VALUES (1,'Top');
INSERT INTO `sizes` (`size_id`, `size_name`) VALUES (4,'L');
INSERT INTO `sizes` (`size_id`, `size_name`) VALUES (3,'M');
INSERT INTO `sizes` (`size_id`, `size_name`) VALUES (7,'One Size');
INSERT INTO `sizes` (`size_id`, `size_name`) VALUES (2,'S');
INSERT INTO `sizes` (`size_id`, `size_name`) VALUES (5,'XL');
INSERT INTO `sizes` (`size_id`, `size_name`) VALUES (1,'XS');
INSERT INTO `sizes` (`size_id`, `size_name`) VALUES (6,'XXL');
INSERT INTO `colors` (`color_id`, `color_name`) VALUES (5,'Beige');
INSERT INTO `colors` (`color_id`, `color_name`) VALUES (1,'Black');
INSERT INTO `colors` (`color_id`, `color_name`) VALUES (3,'Blue');
INSERT INTO `colors` (`color_id`, `color_name`) VALUES (9,'Brown');
INSERT INTO `colors` (`color_id`, `color_name`) VALUES (6,'Gray');
INSERT INTO `colors` (`color_id`, `color_name`) VALUES (4,'Navy');
INSERT INTO `colors` (`color_id`, `color_name`) VALUES (7,'Olive');
INSERT INTO `colors` (`color_id`, `color_name`) VALUES (8,'Pink');
INSERT INTO `colors` (`color_id`, `color_name`) VALUES (2,'White');
INSERT INTO `order_statuses` (`order_status_id`, `status_name`) VALUES (7,'Cancelled');
INSERT INTO `order_statuses` (`order_status_id`, `status_name`) VALUES (6,'Completed');
INSERT INTO `order_statuses` (`order_status_id`, `status_name`) VALUES (5,'Delivered');
INSERT INTO `order_statuses` (`order_status_id`, `status_name`) VALUES (3,'Packed');
INSERT INTO `order_statuses` (`order_status_id`, `status_name`) VALUES (1,'Pending');
INSERT INTO `order_statuses` (`order_status_id`, `status_name`) VALUES (2,'Processing');
INSERT INTO `order_statuses` (`order_status_id`, `status_name`) VALUES (4,'Shipped');
INSERT INTO `users` (`user_id`, `role_name`, `status_id`, `first_name`, `last_name`, `email`, `password_hash`, `phone`, `profile_photo`, `created_at`) VALUES (1,'Admin',1,'Admin','Account','admin@example.com','$2y$10$.swgQnJFoU16vz1MuG5R5uAFsDRhHdNiqSsm9JfgbZza8ZCOUklhm',NULL,NULL,'2026-10-27 18:15:18');
INSERT INTO `users` (`user_id`, `role_name`, `status_id`, `first_name`, `last_name`, `email`, `password_hash`, `phone`, `profile_photo`, `created_at`) VALUES (9,'Customer',1,'Alex','Reyes','alex.reyes.demo@example.com','$2y$10$XY5cUT6S9Nd0P10faJdnHOkACaEAzprREJJjzKFltcvG49GiHXGYa','09171230001',NULL,'2026-10-27 18:55:57');
INSERT INTO `users` (`user_id`, `role_name`, `status_id`, `first_name`, `last_name`, `email`, `password_hash`, `phone`, `profile_photo`, `created_at`) VALUES (10,'Customer',1,'Mika','Santos','mika.santos.demo@example.com','$2y$10$eAhg.pU2veSDcP7yoBnOquBA0prbsHwxfnwO9DXEwZ4ZjNy7TtJwu','09171230002',NULL,'2026-10-27 18:55:57');
INSERT INTO `users` (`user_id`, `role_name`, `status_id`, `first_name`, `last_name`, `email`, `password_hash`, `phone`, `profile_photo`, `created_at`) VALUES (11,'Customer',1,'Jordan','Cruz','jordan.cruz.demo@example.com','$2y$10$4LNIX7FhIr8JIcINdfyjpOm/SeF4Dz0dLsjmKFNZ/3IePjgB9c52y','09171230003',NULL,'2026-10-27 18:55:57');
INSERT INTO `users` (`user_id`, `role_name`, `status_id`, `first_name`, `last_name`, `email`, `password_hash`, `phone`, `profile_photo`, `created_at`) VALUES (12,'Customer',1,'Sam','Garcia','sam.garcia.demo@example.com','$2y$10$k29QK0O4k/xnTtMNEBY5SODcLPvxoVVnJDISSMEsIhYLCMO8xdBsW','09171230004',NULL,'2026-10-27 18:55:57');
INSERT INTO `users` (`user_id`, `role_name`, `status_id`, `first_name`, `last_name`, `email`, `password_hash`, `phone`, `profile_photo`, `created_at`) VALUES (13,'Customer',1,'Taylor','Dela Cruz','taylor.delacruz.demo@example.com','$2y$10$CU3q5QUAOC3KOJ6stvISNeZabTKUBg9t4nplkIRBrmCs9wTm3Zx3y','09171230005',NULL,'2026-10-27 18:55:57');
INSERT INTO `users` (`user_id`, `role_name`, `status_id`, `first_name`, `last_name`, `email`, `password_hash`, `phone`, `profile_photo`, `created_at`) VALUES (14,'Customer',1,'Casey','Mendoza','casey.mendoza.demo@example.com','$2y$10$HKTdfdRzAYv0m5O66PqtS.pTz5piVIVWIfnIKjTOEUBvvgPacAZC2','09171230006',NULL,'2026-10-27 18:55:57');
INSERT INTO `users` (`user_id`, `role_name`, `status_id`, `first_name`, `last_name`, `email`, `password_hash`, `phone`, `profile_photo`, `created_at`) VALUES (16,'Customer',1,'Justine','Sabalza','justinesabalza0101@gmail.com','$2y$12$itKxwua2/ffxihYlg7zWh.JVdvzxm7UjfKuckurCskjJCddCLNpqe','09090909090',NULL,'2026-10-27 19:01:57');
INSERT INTO `users` (`user_id`, `role_name`, `status_id`, `first_name`, `last_name`, `email`, `password_hash`, `phone`, `profile_photo`, `created_at`) VALUES (17,'Customer',1,'John','Taneo','johntaneo@gmail.com','$2y$10$zJFyGBQHpnfIXtNJImctmuknqK8h5cVqQowx6TBTZJ8eVXaCWbW4i',NULL,'uploads/profiles/1eccd0004d15ee294ec0abdf6203956a.jpg','2026-10-29 03:17:43');
INSERT INTO `addresses` (`address_id`, `user_id`, `recipient_name`, `phone`, `address_line1`, `city`, `province`, `postal_code`, `is_default`) VALUES (8,9,'Alex Reyes','09171230001','Blk 12 Lot 4, Sampaguita St.','Taguig City','Metro Manila','1630',1);
INSERT INTO `addresses` (`address_id`, `user_id`, `recipient_name`, `phone`, `address_line1`, `city`, `province`, `postal_code`, `is_default`) VALUES (9,10,'Mika Santos','09171230002','Unit 3B, 28 Rizal Ave.','Makati City','Metro Manila','1210',1);
INSERT INTO `addresses` (`address_id`, `user_id`, `recipient_name`, `phone`, `address_line1`, `city`, `province`, `postal_code`, `is_default`) VALUES (10,11,'Jordan Cruz','09171230003','15 Narra Street','Pasig City','Metro Manila','1600',1);
INSERT INTO `addresses` (`address_id`, `user_id`, `recipient_name`, `phone`, `address_line1`, `city`, `province`, `postal_code`, `is_default`) VALUES (11,12,'Sam Garcia','09171230004','22 Mabini Road','Mandaluyong City','Metro Manila','1550',1);
INSERT INTO `addresses` (`address_id`, `user_id`, `recipient_name`, `phone`, `address_line1`, `city`, `province`, `postal_code`, `is_default`) VALUES (12,13,'Taylor Dela Cruz','09171230005','Unit 5, 8 Bonifacio St.','Taguig City','Metro Manila','1634',1);
INSERT INTO `addresses` (`address_id`, `user_id`, `recipient_name`, `phone`, `address_line1`, `city`, `province`, `postal_code`, `is_default`) VALUES (13,14,'Casey Mendoza','09171230006','9 Acacia Lane','Quezon City','Metro Manila','1104',1);
INSERT INTO `addresses` (`address_id`, `user_id`, `recipient_name`, `phone`, `address_line1`, `city`, `province`, `postal_code`, `is_default`) VALUES (20,16,'Justine Sabalza','09090909090','Blk 7 SDH','Taguig City','NCR','1632',0);
INSERT INTO `addresses` (`address_id`, `user_id`, `recipient_name`, `phone`, `address_line1`, `city`, `province`, `postal_code`, `is_default`) VALUES (21,17,'John Taneo','09121480385','Road 1 #66','Taguig City','NCR','1632',0);
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (1,1,1,'Basic T-Shirt','basic-t-shirt','Everyday cotton T-shirt with a comfortable regular fit.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (2,1,1,'Polo Shirt','polo-shirt','Classic polo shirt for casual and smart-casual outfits.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (3,1,1,'Button-Down Shirt','button-down-shirt','Versatile button-down shirt suitable for work or weekends.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (4,1,1,'Hoodie','hoodie','Soft casual hoodie for cool days and relaxed outfits.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (5,1,1,'Sweatshirt','sweatshirt','Comfortable crewneck sweatshirt with a clean silhouette.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (7,1,1,'Henley Shirt','henley-shirt','Casual Henley shirt with a buttoned neckline.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (8,1,1,'Flannel Shirt','flannel-shirt','Soft checked flannel shirt for layering.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (9,1,1,'Long-Sleeve Shirt','long-sleeve-shirt','Long-sleeve basic designed for versatile everyday styling.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (10,1,1,'Knit Sweater','knit-sweater','Textured knit sweater for a comfortable layered look.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (11,1,2,'Slim-Fit Jeans','slim-fit-jeans-4cd593','Slim-fit denim jeans with a modern everyday cut.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (12,1,2,'Straight-Leg Jeans','straight-leg-jeans','Classic straight-leg denim jeans.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (13,1,2,'Cargo Pants','cargo-pants','Utility-inspired cargo pants with practical pockets.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (14,1,2,'Chino Pants','chino-pants','Smart-casual chino pants for work and weekends.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (15,1,2,'Jogger Pants','jogger-pants','Relaxed jogger pants with an easy tapered fit.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (16,1,2,'Denim Shorts','denim-shorts','Casual denim shorts for warm-weather outfits.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (17,1,2,'Bermuda Shorts','bermuda-shorts','Versatile knee-length Bermuda shorts.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (18,1,2,'Dress Pants','dress-pants','Tailored-look dress pants for formal occasions.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (19,1,2,'Sweatpants','sweatpants','Soft sweatpants for lounging and casual wear.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (20,1,2,'Linen Trousers','linen-trousers','Breathable linen-blend trousers for warm weather.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (21,1,3,'Baseball Cap','baseball-cap','Adjustable baseball cap with a curved brim.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (22,1,3,'Bucket Hat','bucket-hat','Casual bucket hat for everyday styling.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (23,1,3,'Beanie','beanie','Soft knit beanie for a simple layered look.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (24,1,3,'Fedora Hat','fedora-hat','Classic fedora-inspired hat for a statement outfit.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (25,1,3,'Flat Cap','flat-cap','Traditional flat cap with a clean profile.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (26,1,3,'Snapback Cap','snapback-cap','Structured snapback cap with an adjustable closure.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (27,1,3,'Trucker Hat','trucker-hat','Casual trucker cap with a breathable back panel.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (28,1,3,'Beret','beret','Minimal beret for a distinctive casual look.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (29,1,3,'Panama Hat','panama-hat','Lightweight summer hat with a classic brim.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (30,1,3,'Fisherman Beanie','fisherman-beanie','Short cuffed knit beanie with a fisherman style.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (31,2,1,'Basic T-Shirt','w-basic-t-shirt','Everyday basic T-shirt with an easy, versatile fit.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (32,2,1,'Crop Top','crop-top','Casual crop top for everyday outfits.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (33,2,1,'Blouse','blouse','Versatile blouse suitable for casual or dressy styling.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (34,2,1,'Camisole','camisole','Lightweight camisole for layering or warm days.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (35,2,1,'Tank Top','w-tank-top','Simple sleeveless tank top for everyday wear.',0,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (36,2,1,'Off-Shoulder Top','off-shoulder-top','Off-shoulder top for a relaxed, dressy look.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (37,2,1,'Halter Top','halter-top','Halter-neck top with a clean, modern style.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (38,2,1,'Bodysuit','bodysuit','Streamlined bodysuit designed for easy outfit pairing.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (39,2,1,'Cardigan','cardigan','Soft cardigan for comfortable layering.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (40,2,1,'Knit Sweater','w-knit-sweater','Knit sweater with a versatile everyday silhouette.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (41,2,2,'Skinny Jeans','skinny-jeans','Skinny-fit denim jeans with a classic finish.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (42,2,2,'Wide-Leg Jeans','wide-leg-jeans','Wide-leg jeans with a relaxed contemporary fit.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (43,2,2,'Cargo Pants','w-cargo-pants','Utility-inspired cargo pants with functional pockets.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (44,2,2,'High-Waisted Trousers','high-waisted-trousers','High-waisted trousers for a polished everyday outfit.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (45,2,2,'Denim Shorts','w-denim-shorts','Casual denim shorts for warm-weather styling.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (46,2,2,'Mini Skirt','mini-skirt','Versatile mini skirt for casual outfits.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (47,2,2,'Midi Skirt','midi-skirt','Midi skirt designed for easy day-to-day styling.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (48,2,2,'Maxi Skirt','maxi-skirt','Flowing maxi skirt for relaxed, dressy outfits.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (49,2,2,'Leggings','leggings','Stretch leggings for comfortable everyday wear.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (50,2,2,'Palazzo Pants','palazzo-pants','Flowy palazzo pants with a relaxed wide-leg fit.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (51,2,3,'Baseball Cap','w-baseball-cap','Adjustable baseball cap for casual everyday outfits.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (52,2,3,'Bucket Hat','w-bucket-hat','Casual bucket hat with an easy, relaxed shape.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (53,2,3,'Beanie','w-beanie','Soft knit beanie for a simple layered look.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (54,2,3,'Beret','w-beret','Classic beret to complement casual or smart outfits.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (55,2,3,'Wide-Brim Sun Hat','wide-brim-sun-hat','Wide-brim hat for sunny-day outfits.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (56,2,3,'Fedora Hat','w-fedora-hat','Fedora-inspired hat with a versatile silhouette.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (57,2,3,'Straw Hat','straw-hat','Lightweight straw-style hat for warm-weather wear.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (58,2,3,'Visor Cap','visor-cap','Lightweight visor cap for outdoor activities.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (59,2,3,'Cloche Hat','cloche-hat','Cloche-inspired hat with a timeless rounded shape.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (60,2,3,'Newsboy Cap','newsboy-cap','Newsboy cap with a classic casual profile.',1,'2026-10-27 18:20:01');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (61,1,1,'Tank Top','tank-top-dbf378','tank top',0,'2026-10-29 03:25:59');
INSERT INTO `products` (`product_id`, `product_category_id`, `product_type_id`, `product_name`, `slug`, `description`, `is_active`, `created_at`) VALUES (62,1,1,'Tank Top','tank-top-27d2','tank top na malupet',0,'2026-11-01 16:01:19');
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (1,1,'uploads/products/basic-t-shirt-main.jpg','Basic T-Shirt product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (2,2,'uploads/products/polo-shirt-main.jpg','Polo Shirt product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (3,3,'uploads/products/button-down-shirt-main.jpg','Button-Down Shirt product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (4,4,'uploads/products/hoodie-main.jpg','Hoodie product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (5,5,'uploads/products/sweatshirt-main.jpg','Sweatshirt product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (7,7,'uploads/products/henley-shirt-main.jpg','Henley Shirt product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (8,8,'uploads/products/flannel-shirt-main.jpg','Flannel Shirt product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (9,9,'uploads/products/long-sleeve-shirt-main.jpg','Long-Sleeve Shirt product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (10,10,'uploads/products/knit-sweater-main.jpg','Knit Sweater product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (11,11,'uploads/products/slim-fit-jeans-main.jpg','Slim-Fit Jeans product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (12,12,'uploads/products/straight-leg-jeans-main.jpg','Straight-Leg Jeans product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (13,13,'uploads/products/cargo-pants-main.jpg','Cargo Pants product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (14,14,'uploads/products/chino-pants-main.jpg','Chino Pants product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (15,15,'uploads/products/jogger-pants-main.jpg','Jogger Pants product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (16,16,'uploads/products/denim-shorts-main.jpg','Denim Shorts product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (17,17,'uploads/products/bermuda-shorts-main.jpg','Bermuda Shorts product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (18,18,'uploads/products/dress-pants-main.jpg','Dress Pants product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (19,19,'uploads/products/sweatpants-main.jpg','Sweatpants product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (20,20,'uploads/products/linen-trousers-main.jpg','Linen Trousers product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (21,21,'uploads/products/baseball-cap-main.jpg','Baseball Cap product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (22,22,'uploads/products/bucket-hat-main.jpg','Bucket Hat product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (23,23,'uploads/products/beanie-main.jpg','Beanie product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (24,24,'uploads/products/fedora-hat-main.jpg','Fedora Hat product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (25,25,'uploads/products/flat-cap-main.jpg','Flat Cap product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (26,26,'uploads/products/snapback-cap-main.jpg','Snapback Cap product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (27,27,'uploads/products/trucker-hat-main.jpg','Trucker Hat product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (28,28,'uploads/products/beret-main.jpg','Beret product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (29,29,'uploads/products/panama-hat-main.jpg','Panama Hat product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (30,30,'uploads/products/fisherman-beanie-main.jpg','Fisherman Beanie product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (31,31,'uploads/products/w-basic-t-shirt-main.jpg','Basic T-Shirt product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (32,32,'uploads/products/crop-top-main.jpg','Crop Top product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (33,33,'uploads/products/blouse-main.jpg','Blouse product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (34,34,'uploads/products/camisole-main.jpg','Camisole product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (35,35,'uploads/products/w-tank-top-main.jpg','Tank Top product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (36,36,'uploads/products/off-shoulder-top-main.jpg','Off-Shoulder Top product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (37,37,'uploads/products/halter-top-main.jpg','Halter Top product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (38,38,'uploads/products/bodysuit-main.jpg','Bodysuit product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (39,39,'uploads/products/cardigan-main.jpg','Cardigan product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (40,40,'uploads/products/w-knit-sweater-main.jpg','Knit Sweater product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (41,41,'uploads/products/skinny-jeans-main.jpg','Skinny Jeans product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (42,42,'uploads/products/wide-leg-jeans-main.jpg','Wide-Leg Jeans product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (43,43,'uploads/products/w-cargo-pants-main.jpg','Cargo Pants product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (44,44,'uploads/products/high-waisted-trousers-main.jpg','High-Waisted Trousers product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (45,45,'uploads/products/w-denim-shorts-main.jpg','Denim Shorts product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (46,46,'uploads/products/mini-skirt-main.jpg','Mini Skirt product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (47,47,'uploads/products/midi-skirt-main.jpg','Midi Skirt product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (48,48,'uploads/products/maxi-skirt-main.jpg','Maxi Skirt product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (49,49,'uploads/products/leggings-main.jpg','Leggings product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (50,50,'uploads/products/palazzo-pants-main.jpg','Palazzo Pants product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (51,51,'uploads/products/w-baseball-cap-main.jpg','Baseball Cap product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (52,52,'uploads/products/w-bucket-hat-main.jpg','Bucket Hat product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (53,53,'uploads/products/w-beanie-main.jpg','Beanie product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (54,54,'uploads/products/w-beret-main.jpg','Beret product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (55,55,'uploads/products/wide-brim-sun-hat-main.jpg','Wide-Brim Sun Hat product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (56,56,'uploads/products/w-fedora-hat-main.jpg','Fedora Hat product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (57,57,'uploads/products/straw-hat-main.jpg','Straw Hat product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (58,58,'uploads/products/visor-cap-main.jpg','Visor Cap product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (59,59,'uploads/products/cloche-hat-main.jpg','Cloche Hat product photo',1);
INSERT INTO `product_images` (`image_id`, `product_id`, `image_path`, `alt_text`, `sort_order`) VALUES (60,60,'uploads/products/newsboy-cap-main.jpg','Newsboy Cap product photo',1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (1,1,1,1,'MC-BT-TP-1-1',299.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (2,1,2,1,'MC-BT-TP-1-2',299.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (3,1,3,1,'MC-BT-TP-1-3',299.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (4,1,4,1,'MC-BT-TP-1-4',299.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (5,1,5,1,'MC-BT-TP-1-5',299.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (6,1,1,2,'MC-BT-TP-2-1',299.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (7,1,2,2,'MC-BT-TP-2-2',299.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (8,1,3,2,'MC-BT-TP-2-3',299.00,14,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (9,1,4,2,'MC-BT-TP-2-4',299.00,15,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (10,1,5,2,'MC-BT-TP-2-5',299.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (11,1,1,4,'MC-BT-TP-4-1',319.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (12,1,2,4,'MC-BT-TP-4-2',319.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (13,1,3,4,'MC-BT-TP-4-3',319.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (14,1,4,4,'MC-BT-TP-4-4',319.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (15,1,5,4,'MC-BT-TP-4-5',319.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (16,1,1,7,'MC-BT-TP-7-1',299.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (17,1,2,7,'MC-BT-TP-7-2',299.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (18,1,3,7,'MC-BT-TP-7-3',299.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (19,1,4,7,'MC-BT-TP-7-4',299.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (20,1,5,7,'MC-BT-TP-7-5',299.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (21,2,1,1,'MC-PS-TP-1-1',449.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (22,2,2,1,'MC-PS-TP-1-2',449.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (23,2,3,1,'MC-PS-TP-1-3',449.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (24,2,4,1,'MC-PS-TP-1-4',449.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (25,2,5,1,'MC-PS-TP-1-5',449.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (26,2,1,2,'MC-PS-TP-2-1',449.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (27,2,2,2,'MC-PS-TP-2-2',449.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (28,2,3,2,'MC-PS-TP-2-3',449.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (29,2,4,2,'MC-PS-TP-2-4',449.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (30,2,5,2,'MC-PS-TP-2-5',449.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (31,2,1,4,'MC-PS-TP-4-1',469.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (32,2,2,4,'MC-PS-TP-4-2',469.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (33,2,3,4,'MC-PS-TP-4-3',469.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (34,2,4,4,'MC-PS-TP-4-4',469.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (35,2,5,4,'MC-PS-TP-4-5',469.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (36,2,1,7,'MC-PS-TP-7-1',449.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (37,2,2,7,'MC-PS-TP-7-2',449.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (38,2,3,7,'MC-PS-TP-7-3',449.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (39,2,4,7,'MC-PS-TP-7-4',449.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (40,2,5,7,'MC-PS-TP-7-5',449.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (41,3,1,1,'MC-BS-TP-1-1',599.00,9,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (42,3,2,1,'MC-BS-TP-1-2',599.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (43,3,3,1,'MC-BS-TP-1-3',599.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (44,3,4,1,'MC-BS-TP-1-4',599.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (45,3,5,1,'MC-BS-TP-1-5',599.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (46,3,1,2,'MC-BS-TP-2-1',599.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (47,3,2,2,'MC-BS-TP-2-2',599.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (48,3,3,2,'MC-BS-TP-2-3',599.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (49,3,4,2,'MC-BS-TP-2-4',599.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (50,3,5,2,'MC-BS-TP-2-5',599.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (51,3,1,4,'MC-BS-TP-4-1',619.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (52,3,2,4,'MC-BS-TP-4-2',619.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (53,3,3,4,'MC-BS-TP-4-3',619.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (54,3,4,4,'MC-BS-TP-4-4',619.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (55,3,5,4,'MC-BS-TP-4-5',619.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (56,3,1,7,'MC-BS-TP-7-1',599.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (57,3,2,7,'MC-BS-TP-7-2',599.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (58,3,3,7,'MC-BS-TP-7-3',599.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (59,3,4,7,'MC-BS-TP-7-4',599.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (60,3,5,7,'MC-BS-TP-7-5',599.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (61,4,1,1,'MC-H-TP-1-1',799.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (62,4,2,1,'MC-H-TP-1-2',799.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (63,4,3,1,'MC-H-TP-1-3',799.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (64,4,4,1,'MC-H-TP-1-4',799.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (65,4,5,1,'MC-H-TP-1-5',799.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (66,4,1,2,'MC-H-TP-2-1',799.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (67,4,2,2,'MC-H-TP-2-2',799.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (68,4,3,2,'MC-H-TP-2-3',799.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (69,4,4,2,'MC-H-TP-2-4',799.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (70,4,5,2,'MC-H-TP-2-5',799.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (71,4,1,4,'MC-H-TP-4-1',819.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (72,4,2,4,'MC-H-TP-4-2',819.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (73,4,3,4,'MC-H-TP-4-3',819.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (74,4,4,4,'MC-H-TP-4-4',819.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (75,4,5,4,'MC-H-TP-4-5',819.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (76,4,1,7,'MC-H-TP-7-1',799.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (77,4,2,7,'MC-H-TP-7-2',799.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (78,4,3,7,'MC-H-TP-7-3',799.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (79,4,4,7,'MC-H-TP-7-4',799.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (80,4,5,7,'MC-H-TP-7-5',799.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (81,5,1,1,'MC-S-TP-1-1',699.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (82,5,2,1,'MC-S-TP-1-2',699.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (83,5,3,1,'MC-S-TP-1-3',699.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (84,5,4,1,'MC-S-TP-1-4',699.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (85,5,5,1,'MC-S-TP-1-5',699.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (86,5,1,2,'MC-S-TP-2-1',699.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (87,5,2,2,'MC-S-TP-2-2',699.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (88,5,3,2,'MC-S-TP-2-3',699.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (89,5,4,2,'MC-S-TP-2-4',699.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (90,5,5,2,'MC-S-TP-2-5',699.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (91,5,1,4,'MC-S-TP-4-1',719.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (92,5,2,4,'MC-S-TP-4-2',719.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (93,5,3,4,'MC-S-TP-4-3',719.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (94,5,4,4,'MC-S-TP-4-4',719.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (95,5,5,4,'MC-S-TP-4-5',719.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (96,5,1,7,'MC-S-TP-7-1',699.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (97,5,2,7,'MC-S-TP-7-2',699.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (98,5,3,7,'MC-S-TP-7-3',699.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (99,5,4,7,'MC-S-TP-7-4',699.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (100,5,5,7,'MC-S-TP-7-5',699.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (121,7,1,1,'MC-HS-TP-1-1',399.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (122,7,2,1,'MC-HS-TP-1-2',399.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (123,7,3,1,'MC-HS-TP-1-3',399.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (124,7,4,1,'MC-HS-TP-1-4',399.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (125,7,5,1,'MC-HS-TP-1-5',399.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (126,7,1,2,'MC-HS-TP-2-1',399.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (127,7,2,2,'MC-HS-TP-2-2',399.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (128,7,3,2,'MC-HS-TP-2-3',399.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (129,7,4,2,'MC-HS-TP-2-4',399.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (130,7,5,2,'MC-HS-TP-2-5',399.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (131,7,1,4,'MC-HS-TP-4-1',419.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (132,7,2,4,'MC-HS-TP-4-2',419.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (133,7,3,4,'MC-HS-TP-4-3',419.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (134,7,4,4,'MC-HS-TP-4-4',419.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (135,7,5,4,'MC-HS-TP-4-5',419.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (136,7,1,7,'MC-HS-TP-7-1',399.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (137,7,2,7,'MC-HS-TP-7-2',399.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (138,7,3,7,'MC-HS-TP-7-3',399.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (139,7,4,7,'MC-HS-TP-7-4',399.00,11,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (140,7,5,7,'MC-HS-TP-7-5',399.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (141,8,1,1,'MC-FS-TP-1-1',649.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (142,8,2,1,'MC-FS-TP-1-2',649.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (143,8,3,1,'MC-FS-TP-1-3',649.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (144,8,4,1,'MC-FS-TP-1-4',649.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (145,8,5,1,'MC-FS-TP-1-5',649.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (146,8,1,2,'MC-FS-TP-2-1',649.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (147,8,2,2,'MC-FS-TP-2-2',649.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (148,8,3,2,'MC-FS-TP-2-3',649.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (149,8,4,2,'MC-FS-TP-2-4',649.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (150,8,5,2,'MC-FS-TP-2-5',649.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (151,8,1,4,'MC-FS-TP-4-1',669.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (152,8,2,4,'MC-FS-TP-4-2',669.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (153,8,3,4,'MC-FS-TP-4-3',669.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (154,8,4,4,'MC-FS-TP-4-4',669.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (155,8,5,4,'MC-FS-TP-4-5',669.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (156,8,1,7,'MC-FS-TP-7-1',649.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (157,8,2,7,'MC-FS-TP-7-2',649.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (158,8,3,7,'MC-FS-TP-7-3',649.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (159,8,4,7,'MC-FS-TP-7-4',649.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (160,8,5,7,'MC-FS-TP-7-5',649.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (161,9,1,1,'MC-LS-TP-1-1',399.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (162,9,2,1,'MC-LS-TP-1-2',399.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (163,9,3,1,'MC-LS-TP-1-3',399.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (164,9,4,1,'MC-LS-TP-1-4',399.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (165,9,5,1,'MC-LS-TP-1-5',399.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (166,9,1,2,'MC-LS-TP-2-1',399.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (167,9,2,2,'MC-LS-TP-2-2',399.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (168,9,3,2,'MC-LS-TP-2-3',399.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (169,9,4,2,'MC-LS-TP-2-4',399.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (170,9,5,2,'MC-LS-TP-2-5',399.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (171,9,1,4,'MC-LS-TP-4-1',419.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (172,9,2,4,'MC-LS-TP-4-2',419.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (173,9,3,4,'MC-LS-TP-4-3',419.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (174,9,4,4,'MC-LS-TP-4-4',419.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (175,9,5,4,'MC-LS-TP-4-5',419.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (176,9,1,7,'MC-LS-TP-7-1',399.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (177,9,2,7,'MC-LS-TP-7-2',399.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (178,9,3,7,'MC-LS-TP-7-3',399.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (179,9,4,7,'MC-LS-TP-7-4',399.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (180,9,5,7,'MC-LS-TP-7-5',399.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (181,10,1,1,'MC-KS-TP-1-1',799.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (182,10,2,1,'MC-KS-TP-1-2',799.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (183,10,3,1,'MC-KS-TP-1-3',799.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (184,10,4,1,'MC-KS-TP-1-4',799.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (185,10,5,1,'MC-KS-TP-1-5',799.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (186,10,1,2,'MC-KS-TP-2-1',799.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (187,10,2,2,'MC-KS-TP-2-2',799.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (188,10,3,2,'MC-KS-TP-2-3',799.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (189,10,4,2,'MC-KS-TP-2-4',799.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (190,10,5,2,'MC-KS-TP-2-5',799.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (191,10,1,4,'MC-KS-TP-4-1',819.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (192,10,2,4,'MC-KS-TP-4-2',819.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (193,10,3,4,'MC-KS-TP-4-3',819.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (194,10,4,4,'MC-KS-TP-4-4',819.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (195,10,5,4,'MC-KS-TP-4-5',819.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (196,10,1,7,'MC-KS-TP-7-1',799.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (197,10,2,7,'MC-KS-TP-7-2',799.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (198,10,3,7,'MC-KS-TP-7-3',799.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (199,10,4,7,'MC-KS-TP-7-4',799.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (200,10,5,7,'MC-KS-TP-7-5',799.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (201,11,2,1,'MC-SJ-BTM-1-2-11',899.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (202,11,3,1,'MC-SJ-BTM-1-3-11',899.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (203,11,4,1,'MC-SJ-BTM-1-4-11',899.00,19,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (204,11,5,1,'MC-SJ-BTM-1-5-11',899.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (205,11,2,2,'MC-SJ-BTM-2-2-11',899.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (206,11,3,2,'MC-SJ-BTM-2-3-11',899.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (207,11,4,2,'MC-SJ-BTM-2-4-11',899.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (208,11,5,2,'MC-SJ-BTM-2-5-11',899.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (209,11,2,4,'MC-SJ-BTM-4-2-11',919.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (210,11,3,4,'MC-SJ-BTM-4-3-11',919.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (211,11,4,4,'MC-SJ-BTM-4-4-11',919.00,15,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (212,11,5,4,'MC-SJ-BTM-4-5-11',919.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (213,11,2,7,'MC-SJ-BTM-7-2-11',899.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (214,11,3,7,'MC-SJ-BTM-7-3-11',899.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (215,11,4,7,'MC-SJ-BTM-7-4-11',899.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (216,11,5,7,'MC-SJ-BTM-7-5-11',899.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (217,12,2,1,'MC-SJ-BTM-1-2-12',899.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (218,12,3,1,'MC-SJ-BTM-1-3-12',899.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (219,12,4,1,'MC-SJ-BTM-1-4-12',899.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (220,12,5,1,'MC-SJ-BTM-1-5-12',899.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (221,12,2,2,'MC-SJ-BTM-2-2-12',899.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (222,12,3,2,'MC-SJ-BTM-2-3-12',899.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (223,12,4,2,'MC-SJ-BTM-2-4-12',899.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (224,12,5,2,'MC-SJ-BTM-2-5-12',899.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (225,12,2,4,'MC-SJ-BTM-4-2-12',919.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (226,12,3,4,'MC-SJ-BTM-4-3-12',919.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (227,12,4,4,'MC-SJ-BTM-4-4-12',919.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (228,12,5,4,'MC-SJ-BTM-4-5-12',919.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (229,12,2,7,'MC-SJ-BTM-7-2-12',899.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (230,12,3,7,'MC-SJ-BTM-7-3-12',899.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (231,12,4,7,'MC-SJ-BTM-7-4-12',899.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (232,12,5,7,'MC-SJ-BTM-7-5-12',899.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (233,13,2,1,'MC-CP-BTM-1-2-13',799.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (234,13,3,1,'MC-CP-BTM-1-3-13',799.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (235,13,4,1,'MC-CP-BTM-1-4-13',799.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (236,13,5,1,'MC-CP-BTM-1-5-13',799.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (237,13,2,2,'MC-CP-BTM-2-2-13',799.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (238,13,3,2,'MC-CP-BTM-2-3-13',799.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (239,13,4,2,'MC-CP-BTM-2-4-13',799.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (240,13,5,2,'MC-CP-BTM-2-5-13',799.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (241,13,2,4,'MC-CP-BTM-4-2-13',819.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (242,13,3,4,'MC-CP-BTM-4-3-13',819.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (243,13,4,4,'MC-CP-BTM-4-4-13',819.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (244,13,5,4,'MC-CP-BTM-4-5-13',819.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (245,13,2,7,'MC-CP-BTM-7-2-13',799.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (246,13,3,7,'MC-CP-BTM-7-3-13',799.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (247,13,4,7,'MC-CP-BTM-7-4-13',799.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (248,13,5,7,'MC-CP-BTM-7-5-13',799.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (249,14,2,1,'MC-CP-BTM-1-2-14',749.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (250,14,3,1,'MC-CP-BTM-1-3-14',749.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (251,14,4,1,'MC-CP-BTM-1-4-14',749.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (252,14,5,1,'MC-CP-BTM-1-5-14',749.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (253,14,2,2,'MC-CP-BTM-2-2-14',749.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (254,14,3,2,'MC-CP-BTM-2-3-14',749.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (255,14,4,2,'MC-CP-BTM-2-4-14',749.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (256,14,5,2,'MC-CP-BTM-2-5-14',749.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (257,14,2,4,'MC-CP-BTM-4-2-14',769.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (258,14,3,4,'MC-CP-BTM-4-3-14',769.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (259,14,4,4,'MC-CP-BTM-4-4-14',769.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (260,14,5,4,'MC-CP-BTM-4-5-14',769.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (261,14,2,7,'MC-CP-BTM-7-2-14',749.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (262,14,3,7,'MC-CP-BTM-7-3-14',749.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (263,14,4,7,'MC-CP-BTM-7-4-14',749.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (264,14,5,7,'MC-CP-BTM-7-5-14',749.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (265,15,2,1,'MC-JP-BTM-1-2',599.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (266,15,3,1,'MC-JP-BTM-1-3',599.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (267,15,4,1,'MC-JP-BTM-1-4',599.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (268,15,5,1,'MC-JP-BTM-1-5',599.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (269,15,2,2,'MC-JP-BTM-2-2',599.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (270,15,3,2,'MC-JP-BTM-2-3',599.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (271,15,4,2,'MC-JP-BTM-2-4',599.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (272,15,5,2,'MC-JP-BTM-2-5',599.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (273,15,2,4,'MC-JP-BTM-4-2',619.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (274,15,3,4,'MC-JP-BTM-4-3',619.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (275,15,4,4,'MC-JP-BTM-4-4',619.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (276,15,5,4,'MC-JP-BTM-4-5',619.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (277,15,2,7,'MC-JP-BTM-7-2',599.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (278,15,3,7,'MC-JP-BTM-7-3',599.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (279,15,4,7,'MC-JP-BTM-7-4',599.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (280,15,5,7,'MC-JP-BTM-7-5',599.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (281,16,2,1,'MC-DS-BTM-1-2',499.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (282,16,3,1,'MC-DS-BTM-1-3',499.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (283,16,4,1,'MC-DS-BTM-1-4',499.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (284,16,5,1,'MC-DS-BTM-1-5',499.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (285,16,2,2,'MC-DS-BTM-2-2',499.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (286,16,3,2,'MC-DS-BTM-2-3',499.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (287,16,4,2,'MC-DS-BTM-2-4',499.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (288,16,5,2,'MC-DS-BTM-2-5',499.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (289,16,2,4,'MC-DS-BTM-4-2',519.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (290,16,3,4,'MC-DS-BTM-4-3',519.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (291,16,4,4,'MC-DS-BTM-4-4',519.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (292,16,5,4,'MC-DS-BTM-4-5',519.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (293,16,2,7,'MC-DS-BTM-7-2',499.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (294,16,3,7,'MC-DS-BTM-7-3',499.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (295,16,4,7,'MC-DS-BTM-7-4',499.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (296,16,5,7,'MC-DS-BTM-7-5',499.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (297,17,2,1,'MC-BS-BTM-1-2',449.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (298,17,3,1,'MC-BS-BTM-1-3',449.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (299,17,4,1,'MC-BS-BTM-1-4',449.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (300,17,5,1,'MC-BS-BTM-1-5',449.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (301,17,2,2,'MC-BS-BTM-2-2',449.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (302,17,3,2,'MC-BS-BTM-2-3',449.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (303,17,4,2,'MC-BS-BTM-2-4',449.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (304,17,5,2,'MC-BS-BTM-2-5',449.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (305,17,2,4,'MC-BS-BTM-4-2',469.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (306,17,3,4,'MC-BS-BTM-4-3',469.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (307,17,4,4,'MC-BS-BTM-4-4',469.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (308,17,5,4,'MC-BS-BTM-4-5',469.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (309,17,2,7,'MC-BS-BTM-7-2',449.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (310,17,3,7,'MC-BS-BTM-7-3',449.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (311,17,4,7,'MC-BS-BTM-7-4',449.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (312,17,5,7,'MC-BS-BTM-7-5',449.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (313,18,2,1,'MC-DP-BTM-1-2',899.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (314,18,3,1,'MC-DP-BTM-1-3',899.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (315,18,4,1,'MC-DP-BTM-1-4',899.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (316,18,5,1,'MC-DP-BTM-1-5',899.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (317,18,2,2,'MC-DP-BTM-2-2',899.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (318,18,3,2,'MC-DP-BTM-2-3',899.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (319,18,4,2,'MC-DP-BTM-2-4',899.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (320,18,5,2,'MC-DP-BTM-2-5',899.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (321,18,2,4,'MC-DP-BTM-4-2',919.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (322,18,3,4,'MC-DP-BTM-4-3',919.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (323,18,4,4,'MC-DP-BTM-4-4',919.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (324,18,5,4,'MC-DP-BTM-4-5',919.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (325,18,2,7,'MC-DP-BTM-7-2',899.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (326,18,3,7,'MC-DP-BTM-7-3',899.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (327,18,4,7,'MC-DP-BTM-7-4',899.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (328,18,5,7,'MC-DP-BTM-7-5',899.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (329,19,2,1,'MC-S-BTM-1-2',549.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (330,19,3,1,'MC-S-BTM-1-3',549.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (331,19,4,1,'MC-S-BTM-1-4',549.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (332,19,5,1,'MC-S-BTM-1-5',549.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (333,19,2,2,'MC-S-BTM-2-2',549.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (334,19,3,2,'MC-S-BTM-2-3',549.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (335,19,4,2,'MC-S-BTM-2-4',549.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (336,19,5,2,'MC-S-BTM-2-5',549.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (337,19,2,4,'MC-S-BTM-4-2',569.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (338,19,3,4,'MC-S-BTM-4-3',569.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (339,19,4,4,'MC-S-BTM-4-4',569.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (340,19,5,4,'MC-S-BTM-4-5',569.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (341,19,2,7,'MC-S-BTM-7-2',549.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (342,19,3,7,'MC-S-BTM-7-3',549.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (343,19,4,7,'MC-S-BTM-7-4',549.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (344,19,5,7,'MC-S-BTM-7-5',549.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (345,20,2,1,'MC-LT-BTM-1-2',799.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (346,20,3,1,'MC-LT-BTM-1-3',799.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (347,20,4,1,'MC-LT-BTM-1-4',799.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (348,20,5,1,'MC-LT-BTM-1-5',799.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (349,20,2,2,'MC-LT-BTM-2-2',799.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (350,20,3,2,'MC-LT-BTM-2-3',799.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (351,20,4,2,'MC-LT-BTM-2-4',799.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (352,20,5,2,'MC-LT-BTM-2-5',799.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (353,20,2,4,'MC-LT-BTM-4-2',819.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (354,20,3,4,'MC-LT-BTM-4-3',819.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (355,20,4,4,'MC-LT-BTM-4-4',819.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (356,20,5,4,'MC-LT-BTM-4-5',819.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (357,20,2,7,'MC-LT-BTM-7-2',799.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (358,20,3,7,'MC-LT-BTM-7-3',799.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (359,20,4,7,'MC-LT-BTM-7-4',799.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (360,20,5,7,'MC-LT-BTM-7-5',799.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (361,21,7,1,'MC-BC-HW-1-7',299.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (362,21,7,5,'MC-BC-HW-5-7',319.00,15,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (363,21,7,4,'MC-BC-HW-4-7',319.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (364,22,7,1,'MC-BH-HW-1-7',299.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (365,22,7,5,'MC-BH-HW-5-7',319.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (366,22,7,4,'MC-BH-HW-4-7',319.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (367,23,7,1,'MC-B-HW-1-7-23',249.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (368,23,7,5,'MC-B-HW-5-7-23',269.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (369,23,7,4,'MC-B-HW-4-7-23',269.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (370,24,7,1,'MC-FH-HW-1-7',499.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (371,24,7,5,'MC-FH-HW-5-7',519.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (372,24,7,4,'MC-FH-HW-4-7',519.00,1,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (373,25,7,1,'MC-FC-HW-1-7',399.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (374,25,7,5,'MC-FC-HW-5-7',419.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (375,25,7,4,'MC-FC-HW-4-7',419.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (376,26,7,1,'MC-SC-HW-1-7',349.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (377,26,7,5,'MC-SC-HW-5-7',369.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (378,26,7,4,'MC-SC-HW-4-7',369.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (379,27,7,1,'MC-TH-HW-1-7',329.00,7,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (380,27,7,5,'MC-TH-HW-5-7',349.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (381,27,7,4,'MC-TH-HW-4-7',349.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (382,28,7,1,'MC-B-HW-1-7-28',349.00,10,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (383,28,7,5,'MC-B-HW-5-7-28',369.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (384,28,7,4,'MC-B-HW-4-7-28',369.00,7,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (385,29,7,1,'MC-PH-HW-1-7',599.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (386,29,7,5,'MC-PH-HW-5-7',619.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (387,29,7,4,'MC-PH-HW-4-7',619.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (388,30,7,1,'MC-FB-HW-1-7',279.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (389,30,7,5,'MC-FB-HW-5-7',299.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (390,30,7,4,'MC-FB-HW-4-7',299.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (391,31,1,1,'WC-BT-TP-1-1',299.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (392,31,2,1,'WC-BT-TP-1-2',299.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (393,31,3,1,'WC-BT-TP-1-3',299.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (394,31,4,1,'WC-BT-TP-1-4',299.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (395,31,5,1,'WC-BT-TP-1-5',299.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (396,31,1,2,'WC-BT-TP-2-1',299.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (397,31,2,2,'WC-BT-TP-2-2',299.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (398,31,3,2,'WC-BT-TP-2-3',299.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (399,31,4,2,'WC-BT-TP-2-4',299.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (400,31,5,2,'WC-BT-TP-2-5',299.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (401,31,1,4,'WC-BT-TP-4-1',319.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (402,31,2,4,'WC-BT-TP-4-2',319.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (403,31,3,4,'WC-BT-TP-4-3',319.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (404,31,4,4,'WC-BT-TP-4-4',319.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (405,31,5,4,'WC-BT-TP-4-5',319.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (406,31,1,7,'WC-BT-TP-7-1',299.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (407,31,2,7,'WC-BT-TP-7-2',299.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (408,31,3,7,'WC-BT-TP-7-3',299.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (409,31,4,7,'WC-BT-TP-7-4',299.00,20,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (410,31,5,7,'WC-BT-TP-7-5',299.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (411,32,1,1,'WC-CT-TP-1-1',299.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (412,32,2,1,'WC-CT-TP-1-2',299.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (413,32,3,1,'WC-CT-TP-1-3',299.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (414,32,4,1,'WC-CT-TP-1-4',299.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (415,32,5,1,'WC-CT-TP-1-5',299.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (416,32,1,2,'WC-CT-TP-2-1',299.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (417,32,2,2,'WC-CT-TP-2-2',299.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (418,32,3,2,'WC-CT-TP-2-3',299.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (419,32,4,2,'WC-CT-TP-2-4',299.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (420,32,5,2,'WC-CT-TP-2-5',299.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (421,32,1,4,'WC-CT-TP-4-1',319.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (422,32,2,4,'WC-CT-TP-4-2',319.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (423,32,3,4,'WC-CT-TP-4-3',319.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (424,32,4,4,'WC-CT-TP-4-4',319.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (425,32,5,4,'WC-CT-TP-4-5',319.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (426,32,1,7,'WC-CT-TP-7-1',299.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (427,32,2,7,'WC-CT-TP-7-2',299.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (428,32,3,7,'WC-CT-TP-7-3',299.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (429,32,4,7,'WC-CT-TP-7-4',299.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (430,32,5,7,'WC-CT-TP-7-5',299.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (431,33,1,1,'WC-B-TP-1-1-33',499.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (432,33,2,1,'WC-B-TP-1-2-33',499.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (433,33,3,1,'WC-B-TP-1-3-33',499.00,15,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (434,33,4,1,'WC-B-TP-1-4-33',499.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (435,33,5,1,'WC-B-TP-1-5-33',499.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (436,33,1,2,'WC-B-TP-2-1-33',499.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (437,33,2,2,'WC-B-TP-2-2-33',499.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (438,33,3,2,'WC-B-TP-2-3-33',499.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (439,33,4,2,'WC-B-TP-2-4-33',499.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (440,33,5,2,'WC-B-TP-2-5-33',499.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (441,33,1,4,'WC-B-TP-4-1-33',519.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (442,33,2,4,'WC-B-TP-4-2-33',519.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (443,33,3,4,'WC-B-TP-4-3-33',519.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (444,33,4,4,'WC-B-TP-4-4-33',519.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (445,33,5,4,'WC-B-TP-4-5-33',519.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (446,33,1,7,'WC-B-TP-7-1-33',499.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (447,33,2,7,'WC-B-TP-7-2-33',499.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (448,33,3,7,'WC-B-TP-7-3-33',499.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (449,33,4,7,'WC-B-TP-7-4-33',499.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (450,33,5,7,'WC-B-TP-7-5-33',499.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (451,34,1,1,'WC-C-TP-1-1-34',249.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (452,34,2,1,'WC-C-TP-1-2-34',249.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (453,34,3,1,'WC-C-TP-1-3-34',249.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (454,34,4,1,'WC-C-TP-1-4-34',249.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (455,34,5,1,'WC-C-TP-1-5-34',249.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (456,34,1,2,'WC-C-TP-2-1-34',249.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (457,34,2,2,'WC-C-TP-2-2-34',249.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (458,34,3,2,'WC-C-TP-2-3-34',249.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (459,34,4,2,'WC-C-TP-2-4-34',249.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (460,34,5,2,'WC-C-TP-2-5-34',249.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (461,34,1,4,'WC-C-TP-4-1-34',269.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (462,34,2,4,'WC-C-TP-4-2-34',269.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (463,34,3,4,'WC-C-TP-4-3-34',269.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (464,34,4,4,'WC-C-TP-4-4-34',269.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (465,34,5,4,'WC-C-TP-4-5-34',269.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (466,34,1,7,'WC-C-TP-7-1-34',249.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (467,34,2,7,'WC-C-TP-7-2-34',249.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (468,34,3,7,'WC-C-TP-7-3-34',249.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (469,34,4,7,'WC-C-TP-7-4-34',249.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (470,34,5,7,'WC-C-TP-7-5-34',249.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (471,35,1,1,'WC-TT-TP-1-1',249.00,8,0);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (472,35,2,1,'WC-TT-TP-1-2',249.00,5,0);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (473,35,3,1,'WC-TT-TP-1-3',249.00,5,0);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (474,35,4,1,'WC-TT-TP-1-4',249.00,5,0);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (475,35,5,1,'WC-TT-TP-1-5',249.00,8,0);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (476,35,1,2,'WC-TT-TP-2-1',249.00,8,0);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (477,35,2,2,'WC-TT-TP-2-2',249.00,5,0);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (478,35,3,2,'WC-TT-TP-2-3',249.00,5,0);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (479,35,4,2,'WC-TT-TP-2-4',249.00,5,0);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (480,35,5,2,'WC-TT-TP-2-5',249.00,8,0);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (481,35,1,4,'WC-TT-TP-4-1',269.00,5,0);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (482,35,2,4,'WC-TT-TP-4-2',269.00,2,0);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (483,35,3,4,'WC-TT-TP-4-3',269.00,2,0);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (484,35,4,4,'WC-TT-TP-4-4',269.00,2,0);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (485,35,5,4,'WC-TT-TP-4-5',269.00,5,0);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (486,35,1,7,'WC-TT-TP-7-1',249.00,8,0);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (487,35,2,7,'WC-TT-TP-7-2',249.00,5,0);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (488,35,3,7,'WC-TT-TP-7-3',249.00,5,0);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (489,35,4,7,'WC-TT-TP-7-4',249.00,5,0);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (490,35,5,7,'WC-TT-TP-7-5',249.00,8,0);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (491,36,1,1,'WC-OT-TP-1-1',399.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (492,36,2,1,'WC-OT-TP-1-2',399.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (493,36,3,1,'WC-OT-TP-1-3',399.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (494,36,4,1,'WC-OT-TP-1-4',399.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (495,36,5,1,'WC-OT-TP-1-5',399.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (496,36,1,2,'WC-OT-TP-2-1',399.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (497,36,2,2,'WC-OT-TP-2-2',399.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (498,36,3,2,'WC-OT-TP-2-3',399.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (499,36,4,2,'WC-OT-TP-2-4',399.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (500,36,5,2,'WC-OT-TP-2-5',399.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (501,36,1,4,'WC-OT-TP-4-1',419.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (502,36,2,4,'WC-OT-TP-4-2',419.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (503,36,3,4,'WC-OT-TP-4-3',419.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (504,36,4,4,'WC-OT-TP-4-4',419.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (505,36,5,4,'WC-OT-TP-4-5',419.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (506,36,1,7,'WC-OT-TP-7-1',399.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (507,36,2,7,'WC-OT-TP-7-2',399.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (508,36,3,7,'WC-OT-TP-7-3',399.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (509,36,4,7,'WC-OT-TP-7-4',399.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (510,36,5,7,'WC-OT-TP-7-5',399.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (511,37,1,1,'WC-HT-TP-1-1',349.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (512,37,2,1,'WC-HT-TP-1-2',349.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (513,37,3,1,'WC-HT-TP-1-3',349.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (514,37,4,1,'WC-HT-TP-1-4',349.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (515,37,5,1,'WC-HT-TP-1-5',349.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (516,37,1,2,'WC-HT-TP-2-1',349.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (517,37,2,2,'WC-HT-TP-2-2',349.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (518,37,3,2,'WC-HT-TP-2-3',349.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (519,37,4,2,'WC-HT-TP-2-4',349.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (520,37,5,2,'WC-HT-TP-2-5',349.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (521,37,1,4,'WC-HT-TP-4-1',369.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (522,37,2,4,'WC-HT-TP-4-2',369.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (523,37,3,4,'WC-HT-TP-4-3',369.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (524,37,4,4,'WC-HT-TP-4-4',369.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (525,37,5,4,'WC-HT-TP-4-5',369.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (526,37,1,7,'WC-HT-TP-7-1',349.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (527,37,2,7,'WC-HT-TP-7-2',349.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (528,37,3,7,'WC-HT-TP-7-3',349.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (529,37,4,7,'WC-HT-TP-7-4',349.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (530,37,5,7,'WC-HT-TP-7-5',349.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (531,38,1,1,'WC-B-TP-1-1-38',449.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (532,38,2,1,'WC-B-TP-1-2-38',449.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (533,38,3,1,'WC-B-TP-1-3-38',449.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (534,38,4,1,'WC-B-TP-1-4-38',449.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (535,38,5,1,'WC-B-TP-1-5-38',449.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (536,38,1,2,'WC-B-TP-2-1-38',449.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (537,38,2,2,'WC-B-TP-2-2-38',449.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (538,38,3,2,'WC-B-TP-2-3-38',449.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (539,38,4,2,'WC-B-TP-2-4-38',449.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (540,38,5,2,'WC-B-TP-2-5-38',449.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (541,38,1,4,'WC-B-TP-4-1-38',469.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (542,38,2,4,'WC-B-TP-4-2-38',469.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (543,38,3,4,'WC-B-TP-4-3-38',469.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (544,38,4,4,'WC-B-TP-4-4-38',469.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (545,38,5,4,'WC-B-TP-4-5-38',469.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (546,38,1,7,'WC-B-TP-7-1-38',449.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (547,38,2,7,'WC-B-TP-7-2-38',449.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (548,38,3,7,'WC-B-TP-7-3-38',449.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (549,38,4,7,'WC-B-TP-7-4-38',449.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (550,38,5,7,'WC-B-TP-7-5-38',449.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (551,39,1,1,'WC-C-TP-1-1-39',699.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (552,39,2,1,'WC-C-TP-1-2-39',699.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (553,39,3,1,'WC-C-TP-1-3-39',699.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (554,39,4,1,'WC-C-TP-1-4-39',699.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (555,39,5,1,'WC-C-TP-1-5-39',699.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (556,39,1,2,'WC-C-TP-2-1-39',699.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (557,39,2,2,'WC-C-TP-2-2-39',699.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (558,39,3,2,'WC-C-TP-2-3-39',699.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (559,39,4,2,'WC-C-TP-2-4-39',699.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (560,39,5,2,'WC-C-TP-2-5-39',699.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (561,39,1,4,'WC-C-TP-4-1-39',719.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (562,39,2,4,'WC-C-TP-4-2-39',719.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (563,39,3,4,'WC-C-TP-4-3-39',719.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (564,39,4,4,'WC-C-TP-4-4-39',719.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (565,39,5,4,'WC-C-TP-4-5-39',719.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (566,39,1,7,'WC-C-TP-7-1-39',699.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (567,39,2,7,'WC-C-TP-7-2-39',699.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (568,39,3,7,'WC-C-TP-7-3-39',699.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (569,39,4,7,'WC-C-TP-7-4-39',699.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (570,39,5,7,'WC-C-TP-7-5-39',699.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (571,40,1,1,'WC-KS-TP-1-1',749.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (572,40,2,1,'WC-KS-TP-1-2',749.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (573,40,3,1,'WC-KS-TP-1-3',749.00,20,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (574,40,4,1,'WC-KS-TP-1-4',749.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (575,40,5,1,'WC-KS-TP-1-5',749.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (576,40,1,2,'WC-KS-TP-2-1',749.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (577,40,2,2,'WC-KS-TP-2-2',749.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (578,40,3,2,'WC-KS-TP-2-3',749.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (579,40,4,2,'WC-KS-TP-2-4',749.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (580,40,5,2,'WC-KS-TP-2-5',749.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (581,40,1,4,'WC-KS-TP-4-1',769.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (582,40,2,4,'WC-KS-TP-4-2',769.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (583,40,3,4,'WC-KS-TP-4-3',769.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (584,40,4,4,'WC-KS-TP-4-4',769.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (585,40,5,4,'WC-KS-TP-4-5',769.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (586,40,1,7,'WC-KS-TP-7-1',749.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (587,40,2,7,'WC-KS-TP-7-2',749.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (588,40,3,7,'WC-KS-TP-7-3',749.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (589,40,4,7,'WC-KS-TP-7-4',749.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (590,40,5,7,'WC-KS-TP-7-5',749.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (591,41,2,1,'WC-SJ-BTM-1-2',899.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (592,41,3,1,'WC-SJ-BTM-1-3',899.00,11,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (593,41,4,1,'WC-SJ-BTM-1-4',899.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (594,41,5,1,'WC-SJ-BTM-1-5',899.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (595,41,2,2,'WC-SJ-BTM-2-2',899.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (596,41,3,2,'WC-SJ-BTM-2-3',899.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (597,41,4,2,'WC-SJ-BTM-2-4',899.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (598,41,5,2,'WC-SJ-BTM-2-5',899.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (599,41,2,4,'WC-SJ-BTM-4-2',919.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (600,41,3,4,'WC-SJ-BTM-4-3',919.00,7,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (601,41,4,4,'WC-SJ-BTM-4-4',919.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (602,41,5,4,'WC-SJ-BTM-4-5',919.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (603,41,2,7,'WC-SJ-BTM-7-2',899.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (604,41,3,7,'WC-SJ-BTM-7-3',899.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (605,41,4,7,'WC-SJ-BTM-7-4',899.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (606,41,5,7,'WC-SJ-BTM-7-5',899.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (607,42,2,1,'WC-WJ-BTM-1-2',949.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (608,42,3,1,'WC-WJ-BTM-1-3',949.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (609,42,4,1,'WC-WJ-BTM-1-4',949.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (610,42,5,1,'WC-WJ-BTM-1-5',949.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (611,42,2,2,'WC-WJ-BTM-2-2',949.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (612,42,3,2,'WC-WJ-BTM-2-3',949.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (613,42,4,2,'WC-WJ-BTM-2-4',949.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (614,42,5,2,'WC-WJ-BTM-2-5',949.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (615,42,2,4,'WC-WJ-BTM-4-2',969.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (616,42,3,4,'WC-WJ-BTM-4-3',969.00,15,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (617,42,4,4,'WC-WJ-BTM-4-4',969.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (618,42,5,4,'WC-WJ-BTM-4-5',969.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (619,42,2,7,'WC-WJ-BTM-7-2',949.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (620,42,3,7,'WC-WJ-BTM-7-3',949.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (621,42,4,7,'WC-WJ-BTM-7-4',949.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (622,42,5,7,'WC-WJ-BTM-7-5',949.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (623,43,2,1,'WC-CP-BTM-1-2',799.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (624,43,3,1,'WC-CP-BTM-1-3',799.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (625,43,4,1,'WC-CP-BTM-1-4',799.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (626,43,5,1,'WC-CP-BTM-1-5',799.00,20,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (627,43,2,2,'WC-CP-BTM-2-2',799.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (628,43,3,2,'WC-CP-BTM-2-3',799.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (629,43,4,2,'WC-CP-BTM-2-4',799.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (630,43,5,2,'WC-CP-BTM-2-5',799.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (631,43,2,4,'WC-CP-BTM-4-2',819.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (632,43,3,4,'WC-CP-BTM-4-3',819.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (633,43,4,4,'WC-CP-BTM-4-4',819.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (634,43,5,4,'WC-CP-BTM-4-5',819.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (635,43,2,7,'WC-CP-BTM-7-2',799.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (636,43,3,7,'WC-CP-BTM-7-3',799.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (637,43,4,7,'WC-CP-BTM-7-4',799.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (638,43,5,7,'WC-CP-BTM-7-5',799.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (639,44,2,1,'WC-HT-BTM-1-2',799.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (640,44,3,1,'WC-HT-BTM-1-3',799.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (641,44,4,1,'WC-HT-BTM-1-4',799.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (642,44,5,1,'WC-HT-BTM-1-5',799.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (643,44,2,2,'WC-HT-BTM-2-2',799.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (644,44,3,2,'WC-HT-BTM-2-3',799.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (645,44,4,2,'WC-HT-BTM-2-4',799.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (646,44,5,2,'WC-HT-BTM-2-5',799.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (647,44,2,4,'WC-HT-BTM-4-2',819.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (648,44,3,4,'WC-HT-BTM-4-3',819.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (649,44,4,4,'WC-HT-BTM-4-4',819.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (650,44,5,4,'WC-HT-BTM-4-5',819.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (651,44,2,7,'WC-HT-BTM-7-2',799.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (652,44,3,7,'WC-HT-BTM-7-3',799.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (653,44,4,7,'WC-HT-BTM-7-4',799.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (654,44,5,7,'WC-HT-BTM-7-5',799.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (655,45,2,1,'WC-DS-BTM-1-2',499.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (656,45,3,1,'WC-DS-BTM-1-3',499.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (657,45,4,1,'WC-DS-BTM-1-4',499.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (658,45,5,1,'WC-DS-BTM-1-5',499.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (659,45,2,2,'WC-DS-BTM-2-2',499.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (660,45,3,2,'WC-DS-BTM-2-3',499.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (661,45,4,2,'WC-DS-BTM-2-4',499.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (662,45,5,2,'WC-DS-BTM-2-5',499.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (663,45,2,4,'WC-DS-BTM-4-2',519.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (664,45,3,4,'WC-DS-BTM-4-3',519.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (665,45,4,4,'WC-DS-BTM-4-4',519.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (666,45,5,4,'WC-DS-BTM-4-5',519.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (667,45,2,7,'WC-DS-BTM-7-2',499.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (668,45,3,7,'WC-DS-BTM-7-3',499.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (669,45,4,7,'WC-DS-BTM-7-4',499.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (670,45,5,7,'WC-DS-BTM-7-5',499.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (671,46,2,1,'WC-MS-BTM-1-2-46',399.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (672,46,3,1,'WC-MS-BTM-1-3-46',399.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (673,46,4,1,'WC-MS-BTM-1-4-46',399.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (674,46,5,1,'WC-MS-BTM-1-5-46',399.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (675,46,2,2,'WC-MS-BTM-2-2-46',399.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (676,46,3,2,'WC-MS-BTM-2-3-46',399.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (677,46,4,2,'WC-MS-BTM-2-4-46',399.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (678,46,5,2,'WC-MS-BTM-2-5-46',399.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (679,46,2,4,'WC-MS-BTM-4-2-46',419.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (680,46,3,4,'WC-MS-BTM-4-3-46',419.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (681,46,4,4,'WC-MS-BTM-4-4-46',419.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (682,46,5,4,'WC-MS-BTM-4-5-46',419.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (683,46,2,7,'WC-MS-BTM-7-2-46',399.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (684,46,3,7,'WC-MS-BTM-7-3-46',399.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (685,46,4,7,'WC-MS-BTM-7-4-46',399.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (686,46,5,7,'WC-MS-BTM-7-5-46',399.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (687,47,2,1,'WC-MS-BTM-1-2-47',499.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (688,47,3,1,'WC-MS-BTM-1-3-47',499.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (689,47,4,1,'WC-MS-BTM-1-4-47',499.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (690,47,5,1,'WC-MS-BTM-1-5-47',499.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (691,47,2,2,'WC-MS-BTM-2-2-47',499.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (692,47,3,2,'WC-MS-BTM-2-3-47',499.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (693,47,4,2,'WC-MS-BTM-2-4-47',499.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (694,47,5,2,'WC-MS-BTM-2-5-47',499.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (695,47,2,4,'WC-MS-BTM-4-2-47',519.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (696,47,3,4,'WC-MS-BTM-4-3-47',519.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (697,47,4,4,'WC-MS-BTM-4-4-47',519.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (698,47,5,4,'WC-MS-BTM-4-5-47',519.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (699,47,2,7,'WC-MS-BTM-7-2-47',499.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (700,47,3,7,'WC-MS-BTM-7-3-47',499.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (701,47,4,7,'WC-MS-BTM-7-4-47',499.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (702,47,5,7,'WC-MS-BTM-7-5-47',499.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (703,48,2,1,'WC-MS-BTM-1-2-48',599.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (704,48,3,1,'WC-MS-BTM-1-3-48',599.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (705,48,4,1,'WC-MS-BTM-1-4-48',599.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (706,48,5,1,'WC-MS-BTM-1-5-48',599.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (707,48,2,2,'WC-MS-BTM-2-2-48',599.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (708,48,3,2,'WC-MS-BTM-2-3-48',599.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (709,48,4,2,'WC-MS-BTM-2-4-48',599.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (710,48,5,2,'WC-MS-BTM-2-5-48',599.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (711,48,2,4,'WC-MS-BTM-4-2-48',619.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (712,48,3,4,'WC-MS-BTM-4-3-48',619.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (713,48,4,4,'WC-MS-BTM-4-4-48',619.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (714,48,5,4,'WC-MS-BTM-4-5-48',619.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (715,48,2,7,'WC-MS-BTM-7-2-48',599.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (716,48,3,7,'WC-MS-BTM-7-3-48',599.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (717,48,4,7,'WC-MS-BTM-7-4-48',599.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (718,48,5,7,'WC-MS-BTM-7-5-48',599.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (719,49,2,1,'WC-L-BTM-1-2',399.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (720,49,3,1,'WC-L-BTM-1-3',399.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (721,49,4,1,'WC-L-BTM-1-4',399.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (722,49,5,1,'WC-L-BTM-1-5',399.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (723,49,2,2,'WC-L-BTM-2-2',399.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (724,49,3,2,'WC-L-BTM-2-3',399.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (725,49,4,2,'WC-L-BTM-2-4',399.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (726,49,5,2,'WC-L-BTM-2-5',399.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (727,49,2,4,'WC-L-BTM-4-2',419.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (728,49,3,4,'WC-L-BTM-4-3',419.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (729,49,4,4,'WC-L-BTM-4-4',419.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (730,49,5,4,'WC-L-BTM-4-5',419.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (731,49,2,7,'WC-L-BTM-7-2',399.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (732,49,3,7,'WC-L-BTM-7-3',399.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (733,49,4,7,'WC-L-BTM-7-4',399.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (734,49,5,7,'WC-L-BTM-7-5',399.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (735,50,2,1,'WC-PP-BTM-1-2',699.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (736,50,3,1,'WC-PP-BTM-1-3',699.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (737,50,4,1,'WC-PP-BTM-1-4',699.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (738,50,5,1,'WC-PP-BTM-1-5',699.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (739,50,2,2,'WC-PP-BTM-2-2',699.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (740,50,3,2,'WC-PP-BTM-2-3',699.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (741,50,4,2,'WC-PP-BTM-2-4',699.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (742,50,5,2,'WC-PP-BTM-2-5',699.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (743,50,2,4,'WC-PP-BTM-4-2',719.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (744,50,3,4,'WC-PP-BTM-4-3',719.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (745,50,4,4,'WC-PP-BTM-4-4',719.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (746,50,5,4,'WC-PP-BTM-4-5',719.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (747,50,2,7,'WC-PP-BTM-7-2',699.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (748,50,3,7,'WC-PP-BTM-7-3',699.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (749,50,4,7,'WC-PP-BTM-7-4',699.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (750,50,5,7,'WC-PP-BTM-7-5',699.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (751,51,7,1,'WC-BC-HW-1-7',299.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (752,51,7,5,'WC-BC-HW-5-7',319.00,25,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (753,51,7,4,'WC-BC-HW-4-7',319.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (754,52,7,1,'WC-BH-HW-1-7',299.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (755,52,7,5,'WC-BH-HW-5-7',319.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (756,52,7,4,'WC-BH-HW-4-7',319.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (757,53,7,1,'WC-B-HW-1-7-53',249.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (758,53,7,5,'WC-B-HW-5-7-53',269.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (759,53,7,4,'WC-B-HW-4-7-53',269.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (760,54,7,1,'WC-B-HW-1-7-54',349.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (761,54,7,5,'WC-B-HW-5-7-54',369.00,21,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (762,54,7,4,'WC-B-HW-4-7-54',369.00,16,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (763,55,7,1,'WC-WSH-HW-1-7',499.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (764,55,7,5,'WC-WSH-HW-5-7',519.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (765,55,7,4,'WC-WSH-HW-4-7',519.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (766,56,7,1,'WC-FH-HW-1-7',499.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (767,56,7,5,'WC-FH-HW-5-7',519.00,12,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (768,56,7,4,'WC-FH-HW-4-7',519.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (769,57,7,1,'WC-SH-HW-1-7',449.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (770,57,7,5,'WC-SH-HW-5-7',469.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (771,57,7,4,'WC-SH-HW-4-7',469.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (772,58,7,1,'WC-VC-HW-1-7',249.00,1,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (773,58,7,5,'WC-VC-HW-5-7',269.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (774,58,7,4,'WC-VC-HW-4-7',269.00,0,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (775,59,7,1,'WC-CH-HW-1-7',449.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (776,59,7,5,'WC-CH-HW-5-7',469.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (777,59,7,4,'WC-CH-HW-4-7',469.00,2,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (778,60,7,1,'WC-NC-HW-1-7',399.00,6,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (779,60,7,5,'WC-NC-HW-5-7',419.00,8,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (780,60,7,4,'WC-NC-HW-4-7',419.00,5,1);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (781,61,4,1,'MC-TT-TP-1-4-61',300.00,30,0);
INSERT INTO `product_variants` (`variant_id`, `product_id`, `size_id`, `color_id`, `sku`, `price`, `stock_quantity`, `is_active`) VALUES (782,62,4,1,'MC-TT-TP-1-4-62',300.00,20,0);
INSERT INTO `orders` (`order_id`, `user_id`, `address_id`, `order_status_id`, `order_number`, `subtotal`, `total_amount`, `customer_note`, `placed_at`, `updated_at`) VALUES (16,9,8,5,'ORD-20261001-A1B201',299.00,299.00,'Single-item transaction','2026-10-01 02:15:00','2026-10-27 19:25:26');
INSERT INTO `orders` (`order_id`, `user_id`, `address_id`, `order_status_id`, `order_number`, `subtotal`, `total_amount`, `customer_note`, `placed_at`, `updated_at`) VALUES (17,10,9,6,'ORD-20261003-A1B202',748.00,748.00,'Multi-item transaction: 2 units across 2 items','2026-10-03 06:20:00','2026-10-27 19:25:26');
INSERT INTO `orders` (`order_id`, `user_id`, `address_id`, `order_status_id`, `order_number`, `subtotal`, `total_amount`, `customer_note`, `placed_at`, `updated_at`) VALUES (18,11,10,7,'ORD-20261005-A1B203',599.00,599.00,'Single-item transaction','2026-10-05 01:30:00','2026-10-27 19:25:26');
INSERT INTO `orders` (`order_id`, `user_id`, `address_id`, `order_status_id`, `order_number`, `subtotal`, `total_amount`, `customer_note`, `placed_at`, `updated_at`) VALUES (19,12,11,6,'ORD-20261008-A1B204',1048.00,1048.00,'Multi-item transaction: 3 units across 2 items','2026-10-08 09:45:00','2026-10-29 01:14:10');
INSERT INTO `orders` (`order_id`, `user_id`, `address_id`, `order_status_id`, `order_number`, `subtotal`, `total_amount`, `customer_note`, `placed_at`, `updated_at`) VALUES (20,13,12,2,'ORD-20261010-A1B205',449.00,449.00,'Single-item transaction','2026-10-10 03:05:00','2026-10-27 19:25:26');
INSERT INTO `orders` (`order_id`, `user_id`, `address_id`, `order_status_id`, `order_number`, `subtotal`, `total_amount`, `customer_note`, `placed_at`, `updated_at`) VALUES (21,14,13,7,'ORD-20261012-A1B206',898.00,898.00,'Multi-item transaction: 2 items','2026-10-12 05:10:00','2026-10-27 19:25:26');
INSERT INTO `orders` (`order_id`, `user_id`, `address_id`, `order_status_id`, `order_number`, `subtotal`, `total_amount`, `customer_note`, `placed_at`, `updated_at`) VALUES (22,9,8,1,'ORD-20261015-A1B207',399.00,399.00,'Single-item transaction','2026-10-15 08:00:00','2026-10-27 19:25:26');
INSERT INTO `orders` (`order_id`, `user_id`, `address_id`, `order_status_id`, `order_number`, `subtotal`, `total_amount`, `customer_note`, `placed_at`, `updated_at`) VALUES (23,10,9,6,'ORD-20261018-A1B208',1298.00,1298.00,'Multi-item transaction: 3 items','2026-10-18 04:25:00','2026-10-27 19:25:26');
INSERT INTO `orders` (`order_id`, `user_id`, `address_id`, `order_status_id`, `order_number`, `subtotal`, `total_amount`, `customer_note`, `placed_at`, `updated_at`) VALUES (24,11,10,3,'ORD-20261021-A1B209',699.00,699.00,'Single-item transaction','2026-10-21 00:40:00','2026-10-27 19:25:26');
INSERT INTO `orders` (`order_id`, `user_id`, `address_id`, `order_status_id`, `order_number`, `subtotal`, `total_amount`, `customer_note`, `placed_at`, `updated_at`) VALUES (25,12,11,6,'ORD-20261024-A1B20A',998.00,998.00,'Multi-item transaction: 2 items','2026-10-24 11:15:00','2026-10-27 19:25:26');
INSERT INTO `orders` (`order_id`, `user_id`, `address_id`, `order_status_id`, `order_number`, `subtotal`, `total_amount`, `customer_note`, `placed_at`, `updated_at`) VALUES (32,16,NULL,6,'ORD-20261027-7D6F9B',2793.00,2793.00,NULL,'2026-10-27 19:02:49','2026-10-27 19:03:27');
INSERT INTO `orders` (`order_id`, `user_id`, `address_id`, `order_status_id`, `order_number`, `subtotal`, `total_amount`, `customer_note`, `placed_at`, `updated_at`) VALUES (33,16,NULL,6,'ORD-20261027-13990B',349.00,349.00,NULL,'2026-10-27 19:10:40','2026-10-27 19:11:16');
INSERT INTO `orders` (`order_id`, `user_id`, `address_id`, `order_status_id`, `order_number`, `subtotal`, `total_amount`, `customer_note`, `placed_at`, `updated_at`) VALUES (34,16,NULL,6,'ORD-20261027-F81332',899.00,899.00,NULL,'2026-10-27 19:10:53','2026-10-27 19:11:23');
INSERT INTO `orders` (`order_id`, `user_id`, `address_id`, `order_status_id`, `order_number`, `subtotal`, `total_amount`, `customer_note`, `placed_at`, `updated_at`) VALUES (35,16,NULL,6,'ORD-20261028-4AEA62',2147.00,2147.00,NULL,'2026-10-28 07:17:43','2026-10-28 07:18:48');
INSERT INTO `orders` (`order_id`, `user_id`, `address_id`, `order_status_id`, `order_number`, `subtotal`, `total_amount`, `customer_note`, `placed_at`, `updated_at`) VALUES (36,16,NULL,6,'ORD-20261028-E12A19',519.00,519.00,NULL,'2026-10-28 07:28:07','2026-10-28 07:47:29');
INSERT INTO `orders` (`order_id`, `user_id`, `address_id`, `order_status_id`, `order_number`, `subtotal`, `total_amount`, `customer_note`, `placed_at`, `updated_at`) VALUES (37,16,20,6,'ORD-20261028-C2A808',1266.00,1266.00,NULL,'2026-10-28 07:51:20','2026-10-28 08:02:05');
INSERT INTO `orders` (`order_id`, `user_id`, `address_id`, `order_status_id`, `order_number`, `subtotal`, `total_amount`, `customer_note`, `placed_at`, `updated_at`) VALUES (40,12,11,6,'ORD-20261029-200E41',799.00,799.00,'Take good care of the product pls','2026-10-29 02:28:57','2026-10-29 02:29:41');
INSERT INTO `orders` (`order_id`, `user_id`, `address_id`, `order_status_id`, `order_number`, `subtotal`, `total_amount`, `customer_note`, `placed_at`, `updated_at`) VALUES (41,13,12,6,'ORD-20261029-A56885',1667.00,1667.00,'Ayusin niyo pag-deliver','2026-10-29 02:35:28','2026-10-29 02:35:41');
INSERT INTO `orders` (`order_id`, `user_id`, `address_id`, `order_status_id`, `order_number`, `subtotal`, `total_amount`, `customer_note`, `placed_at`, `updated_at`) VALUES (42,10,9,7,'ORD-20261029-F0F5D0',1217.00,1217.00,'28th Floor po kami','2026-10-29 02:39:51','2026-10-29 02:40:03');
INSERT INTO `orders` (`order_id`, `user_id`, `address_id`, `order_status_id`, `order_number`, `subtotal`, `total_amount`, `customer_note`, `placed_at`, `updated_at`) VALUES (43,14,13,6,'ORD-20261029-9D35C7',1718.00,1718.00,NULL,'2026-10-29 03:10:46','2026-10-29 03:11:03');
INSERT INTO `orders` (`order_id`, `user_id`, `address_id`, `order_status_id`, `order_number`, `subtotal`, `total_amount`, `customer_note`, `placed_at`, `updated_at`) VALUES (44,17,21,6,'ORD-20261029-56D7D1',1647.00,1647.00,'Take good care of my orders, Thank you.','2026-10-29 03:20:02','2026-10-29 03:20:11');
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (32,16,1,'Basic T-Shirt','BASICTSHIR-BLA-XS','XS','Black',299.00,1,299.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (33,17,21,'Polo Shirt','POLOSHIRT-BLA-XS','XS','Black',449.00,1,449.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (34,17,1,'Basic T-Shirt','BASICTSHIR-BLA-XS','XS','Black',299.00,1,299.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (35,18,41,'Button-Down Shirt','BUTTONDOWN-BLA-XS','XS','Black',599.00,1,599.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (36,19,61,'Hoodie','HOODIE-BLA-XS','XS','Black',699.00,1,699.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (37,19,1,'Basic T-Shirt','BASICTSHIR-BLA-XS','XS','Black',349.00,1,349.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (38,20,21,'Polo Shirt','POLOSHIRT-BLA-XS','XS','Black',449.00,1,449.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (39,21,201,'Slim-Fit Jeans','SLIMFITJEA-BLA-S','S','Black',599.00,1,599.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (40,21,361,'Baseball Cap','BASEBALLCA-BLA-OS','One Size','Black',299.00,1,299.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (41,22,1,'Basic T-Shirt','BASICTSHIR-BLA-XS','XS','Black',399.00,1,399.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (42,23,61,'Hoodie','HOODIE-BLA-XS','XS','Black',699.00,1,699.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (43,23,21,'Polo Shirt','POLOSHIRT-BLA-XS','XS','Black',449.00,1,449.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (44,23,361,'Baseball Cap','BASEBALLCA-BLA-OS','One Size','Black',150.00,1,150.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (45,24,201,'Slim-Fit Jeans','SLIMFITJEA-BLA-S','S','Black',699.00,1,699.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (46,25,41,'Button-Down Shirt','BUTTONDOWN-BLA-XS','XS','Black',599.00,1,599.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (47,25,1,'Basic T-Shirt','BASICTSHIR-BLA-XS','XS','Black',399.00,1,399.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (63,32,164,'Long-Sleeve Shirt','LONGSLEEVE-BLA-L','L','Black',399.00,5,1995.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (64,32,778,'Newsboy Cap','NEWSBOYCAP-BLA-OS','One Size','Black',399.00,2,798.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (65,33,382,'Beret','BERET-BLA-OS','One Size','Black',349.00,1,349.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (66,34,592,'Skinny Jeans','SKINNYJEAN-BLA-M','M','Black',899.00,1,899.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (67,35,203,'Slim-Fit Jeans','SLIMFITJEA-BLA-L','L','Black',899.00,2,1798.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (68,35,382,'Beret','BERET-BLA-OS','One Size','Black',349.00,1,349.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (69,36,372,'Fedora Hat','FEDORAHAT-NAV-OS','One Size','Navy',519.00,1,519.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (70,37,8,'Basic T-Shirt','BASICTSHIR-WHI-M','M','White',299.00,2,598.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (71,37,9,'Basic T-Shirt','BASICTSHIR-WHI-L','L','White',299.00,1,299.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (72,37,384,'Beret','BERET-NAV-OS','One Size','Navy',369.00,1,369.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (73,40,626,'Cargo Pants','WCARGOPANT-BLA-XL','XL','Black',799.00,1,799.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (74,41,433,'Blouse','BLOUSE-BLA-M','M','Black',499.00,1,499.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (75,41,772,'Visor Cap','VISORCAP-BLA-OS','One Size','Black',249.00,1,249.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (76,41,600,'Skinny Jeans','SKINNYJEAN-NAV-M','M','Navy',919.00,1,919.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (77,42,762,'Beret','WBERET-NAV-OS','One Size','Navy',369.00,1,369.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (78,42,512,'Halter Top','HALTERTOP-BLA-S','S','Black',349.00,1,349.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (79,42,688,'Midi Skirt','MIDISKIRT-BLA-M','M','Black',499.00,1,499.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (80,43,573,'Knit Sweater','WKNITSWEAT-BLA-M','M','Black',749.00,1,749.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (81,43,616,'Wide-Leg Jeans','WIDELEGJEA-NAV-M','M','Navy',969.00,1,969.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (82,44,139,'Henley Shirt','HENLEYSHIR-OLI-L','L','Olive',399.00,1,399.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (83,44,211,'Slim-Fit Jeans','SLIMFITJEA-NAV-L','L','Navy',919.00,1,919.00);
INSERT INTO `order_items` (`order_item_id`, `order_id`, `variant_id`, `product_name_snapshot`, `sku_snapshot`, `size_snapshot`, `color_snapshot`, `unit_price`, `quantity`, `line_total`) VALUES (84,44,379,'Trucker Hat','TRUCKERHAT-BLA-OS','One Size','Black',329.00,1,329.00);
INSERT INTO `payments` (`payment_id`, `order_id`, `amount`, `payment_status`, `created_at`) VALUES (16,16,299.00,'paid','2026-10-27 18:55:57');
INSERT INTO `payments` (`payment_id`, `order_id`, `amount`, `payment_status`, `created_at`) VALUES (17,17,748.00,'paid','2026-10-27 18:55:57');
INSERT INTO `payments` (`payment_id`, `order_id`, `amount`, `payment_status`, `created_at`) VALUES (18,18,599.00,'paid','2026-10-27 18:55:57');
INSERT INTO `payments` (`payment_id`, `order_id`, `amount`, `payment_status`, `created_at`) VALUES (19,19,1048.00,'pending','2026-10-27 18:55:57');
INSERT INTO `payments` (`payment_id`, `order_id`, `amount`, `payment_status`, `created_at`) VALUES (20,20,449.00,'pending','2026-10-27 18:55:57');
INSERT INTO `payments` (`payment_id`, `order_id`, `amount`, `payment_status`, `created_at`) VALUES (21,21,898.00,'refunded','2026-10-27 18:55:57');
INSERT INTO `payments` (`payment_id`, `order_id`, `amount`, `payment_status`, `created_at`) VALUES (22,22,399.00,'pending','2026-10-27 18:55:57');
INSERT INTO `payments` (`payment_id`, `order_id`, `amount`, `payment_status`, `created_at`) VALUES (23,23,1298.00,'paid','2026-10-27 18:55:57');
INSERT INTO `payments` (`payment_id`, `order_id`, `amount`, `payment_status`, `created_at`) VALUES (24,24,699.00,'pending','2026-10-27 18:55:57');
INSERT INTO `payments` (`payment_id`, `order_id`, `amount`, `payment_status`, `created_at`) VALUES (25,25,998.00,'paid','2026-10-27 18:55:57');
INSERT INTO `payments` (`payment_id`, `order_id`, `amount`, `payment_status`, `created_at`) VALUES (31,32,2793.00,'pending','2026-10-27 19:02:49');
INSERT INTO `payments` (`payment_id`, `order_id`, `amount`, `payment_status`, `created_at`) VALUES (32,33,349.00,'pending','2026-10-27 19:10:40');
INSERT INTO `payments` (`payment_id`, `order_id`, `amount`, `payment_status`, `created_at`) VALUES (33,34,899.00,'pending','2026-10-27 19:10:53');
INSERT INTO `payments` (`payment_id`, `order_id`, `amount`, `payment_status`, `created_at`) VALUES (34,35,2147.00,'pending','2026-10-28 07:17:43');
INSERT INTO `payments` (`payment_id`, `order_id`, `amount`, `payment_status`, `created_at`) VALUES (35,36,519.00,'pending','2026-10-28 07:28:07');
INSERT INTO `payments` (`payment_id`, `order_id`, `amount`, `payment_status`, `created_at`) VALUES (36,37,1266.00,'pending','2026-10-28 07:51:20');
INSERT INTO `payments` (`payment_id`, `order_id`, `amount`, `payment_status`, `created_at`) VALUES (37,40,799.00,'pending','2026-10-29 02:28:57');
INSERT INTO `payments` (`payment_id`, `order_id`, `amount`, `payment_status`, `created_at`) VALUES (38,41,1667.00,'pending','2026-10-29 02:35:28');
INSERT INTO `payments` (`payment_id`, `order_id`, `amount`, `payment_status`, `created_at`) VALUES (39,42,1217.00,'pending','2026-10-29 02:39:51');
INSERT INTO `payments` (`payment_id`, `order_id`, `amount`, `payment_status`, `created_at`) VALUES (40,43,1718.00,'pending','2026-10-29 03:10:46');
INSERT INTO `payments` (`payment_id`, `order_id`, `amount`, `payment_status`, `created_at`) VALUES (41,44,1647.00,'pending','2026-10-29 03:20:02');
INSERT INTO `sales` (`sale_id`, `order_id`, `transaction_reference`, `total_amount`, `sale_date`, `notes`) VALUES (9,17,'TXN-17-20261028025557',748.00,'2026-10-27 18:55:57','Auto-recorded when order was marked completed');
INSERT INTO `sales` (`sale_id`, `order_id`, `transaction_reference`, `total_amount`, `sale_date`, `notes`) VALUES (11,32,'TXN-32-20261028030327',2793.00,'2026-10-27 19:03:27','Auto-recorded when order was marked completed');
INSERT INTO `sales` (`sale_id`, `order_id`, `transaction_reference`, `total_amount`, `sale_date`, `notes`) VALUES (12,25,'TXN-25-20261028030348',998.00,'2026-10-27 19:03:48','Auto-recorded when order was marked completed');
INSERT INTO `sales` (`sale_id`, `order_id`, `transaction_reference`, `total_amount`, `sale_date`, `notes`) VALUES (13,23,'TXN-23-20261028030403',1298.00,'2026-10-27 19:04:03','Auto-recorded when order was marked completed');
INSERT INTO `sales` (`sale_id`, `order_id`, `transaction_reference`, `total_amount`, `sale_date`, `notes`) VALUES (14,33,'TXN-33-20261028031116',349.00,'2026-10-27 19:11:16','Auto-recorded when order was marked completed');
INSERT INTO `sales` (`sale_id`, `order_id`, `transaction_reference`, `total_amount`, `sale_date`, `notes`) VALUES (15,34,'TXN-34-20261028031123',899.00,'2026-10-27 19:11:23','Auto-recorded when order was marked completed');
INSERT INTO `sales` (`sale_id`, `order_id`, `transaction_reference`, `total_amount`, `sale_date`, `notes`) VALUES (16,35,'TXN-35-20261028151848',2147.00,'2026-10-28 07:18:48','Auto-recorded when order was marked completed');
INSERT INTO `sales` (`sale_id`, `order_id`, `transaction_reference`, `total_amount`, `sale_date`, `notes`) VALUES (17,36,'TXN-36-20261028154729',519.00,'2026-10-28 07:47:29','Auto-recorded when order was marked completed');
INSERT INTO `sales` (`sale_id`, `order_id`, `transaction_reference`, `total_amount`, `sale_date`, `notes`) VALUES (18,37,'TXN-37-20261028160205',1266.00,'2026-10-28 08:02:05','Auto-recorded when order was marked completed');
INSERT INTO `sales` (`sale_id`, `order_id`, `transaction_reference`, `total_amount`, `sale_date`, `notes`) VALUES (22,19,'TXN-19-20261029091410',1048.00,'2026-10-29 01:14:10','Auto-recorded when order was marked completed');
INSERT INTO `sales` (`sale_id`, `order_id`, `transaction_reference`, `total_amount`, `sale_date`, `notes`) VALUES (23,40,'TXN-40-20261029102941',799.00,'2026-10-29 02:29:41','Auto-recorded when order was marked completed');
INSERT INTO `sales` (`sale_id`, `order_id`, `transaction_reference`, `total_amount`, `sale_date`, `notes`) VALUES (24,41,'TXN-41-20261029103541',1667.00,'2026-10-29 02:35:41','Auto-recorded when order was marked completed');
INSERT INTO `sales` (`sale_id`, `order_id`, `transaction_reference`, `total_amount`, `sale_date`, `notes`) VALUES (25,43,'TXN-43-20261029111103',1718.00,'2026-10-29 03:11:03','Auto-recorded when order was marked completed');
INSERT INTO `sales` (`sale_id`, `order_id`, `transaction_reference`, `total_amount`, `sale_date`, `notes`) VALUES (26,44,'TXN-44-20261029112011',1647.00,'2026-10-29 03:20:11','Auto-recorded when order was marked completed');
INSERT INTO `expenses` (`expense_id`, `recorded_by`, `expense_name`, `amount`, `expense_date`, `notes`) VALUES (8,NULL,'Packaging materials',1850.00,'2026-10-02','Boxes, mailers, tape, and labels for demo orders');
INSERT INTO `expenses` (`expense_id`, `recorded_by`, `expense_name`, `amount`, `expense_date`, `notes`) VALUES (9,NULL,'Courier pickup fees',1260.00,'2026-10-06','Sample logistics expense');
INSERT INTO `expenses` (`expense_id`, `recorded_by`, `expense_name`, `amount`, `expense_date`, `notes`) VALUES (10,NULL,'Product photography',1500.00,'2026-10-09','Catalog photo shoot expense');
INSERT INTO `expenses` (`expense_id`, `recorded_by`, `expense_name`, `amount`, `expense_date`, `notes`) VALUES (11,NULL,'Store internet',1499.00,'2026-10-12','Monthly connectivity expense');
INSERT INTO `expenses` (`expense_id`, `recorded_by`, `expense_name`, `amount`, `expense_date`, `notes`) VALUES (13,NULL,'Online promotion',2200.00,'2026-10-20','Sample social media promotion expense');
INSERT INTO `expenses` (`expense_id`, `recorded_by`, `expense_name`, `amount`, `expense_date`, `notes`) VALUES (14,NULL,'Courier pickup fees',1640.00,'2026-10-25','Sample logistics expense');
INSERT INTO `expenses` (`expense_id`, `recorded_by`, `expense_name`, `amount`, `expense_date`, `notes`) VALUES (16,1,'Utilities',10000.00,'2026-10-29','Water & Electricity');
INSERT INTO `expenses` (`expense_id`, `recorded_by`, `expense_name`, `amount`, `expense_date`, `notes`) VALUES (17,1,'Product restock',807.30,'2026-10-29','restock (Baseball Cap)');
INSERT INTO `expenses` (`expense_id`, `recorded_by`, `expense_name`, `amount`, `expense_date`, `notes`) VALUES (18,1,'Product restock',538.20,'2026-10-29','restock (Baseball Cap)');
INSERT INTO `expenses` (`expense_id`, `recorded_by`, `expense_name`, `amount`, `expense_date`, `notes`) VALUES (20,1,'Adding Product',5400.00,'2026-11-01','Adding \"Tank Top\" on the store');
INSERT INTO `cart_items` (`cart_item_id`, `user_id`, `variant_id`, `quantity`, `added_at`) VALUES (21,9,364,1,'2026-10-29 03:15:08');
INSERT INTO `cart_items` (`cart_item_id`, `user_id`, `variant_id`, `quantity`, `added_at`) VALUES (22,9,13,1,'2026-10-29 03:15:23');
INSERT INTO `product_reviews` (`review_id`, `product_id`, `user_id`, `order_item_id`, `rating`, `review_text`, `created_at`, `updated_at`) VALUES (1,43,12,73,5,'The product is good','2026-10-29 02:30:18','2026-10-29 02:30:18');
INSERT INTO `product_reviews` (`review_id`, `product_id`, `user_id`, `order_item_id`, `rating`, `review_text`, `created_at`, `updated_at`) VALUES (2,33,13,74,2,'Ang dumi pagdating','2026-10-29 02:36:38','2026-10-29 02:36:38');
INSERT INTO `product_reviews` (`review_id`, `product_id`, `user_id`, `order_item_id`, `rating`, `review_text`, `created_at`, `updated_at`) VALUES (3,58,13,75,1,'\'Di naman kulay black','2026-10-29 02:37:02','2026-10-29 02:37:02');
INSERT INTO `product_reviews` (`review_id`, `product_id`, `user_id`, `order_item_id`, `rating`, `review_text`, `created_at`, `updated_at`) VALUES (4,41,13,76,2,'Ang liit','2026-10-29 02:37:42','2026-10-29 02:37:42');
INSERT INTO `product_reviews` (`review_id`, `product_id`, `user_id`, `order_item_id`, `rating`, `review_text`, `created_at`, `updated_at`) VALUES (5,40,14,80,5,'the material used is very comfortable','2026-10-29 03:11:47','2026-10-29 03:11:47');
INSERT INTO `product_reviews` (`review_id`, `product_id`, `user_id`, `order_item_id`, `rating`, `review_text`, `created_at`, `updated_at`) VALUES (6,42,14,81,5,'great product, good service','2026-10-29 03:12:15','2026-10-29 03:12:15');
-- Normalize order item and order totals from the line-item snapshots.
UPDATE order_items
SET line_total = ROUND(unit_price * quantity, 2)
WHERE line_total <> ROUND(unit_price * quantity, 2);

UPDATE orders o
LEFT JOIN (
    SELECT order_id, ROUND(SUM(line_total), 2) AS corrected_subtotal
    FROM order_items
    GROUP BY order_id
) item_totals ON item_totals.order_id = o.order_id
SET o.subtotal = COALESCE(item_totals.corrected_subtotal, 0),
    o.total_amount = COALESCE(item_totals.corrected_subtotal, 0)
WHERE o.subtotal <> COALESCE(item_totals.corrected_subtotal, 0)
   OR o.total_amount <> COALESCE(item_totals.corrected_subtotal, 0);

-- Keep an order address only when it belongs to that order's customer.
UPDATE orders o
LEFT JOIN addresses a ON a.address_id = o.address_id AND a.user_id = o.user_id
SET o.address_id = NULL
WHERE o.address_id IS NOT NULL AND a.address_id IS NULL;

-- Enforce product/variant active-state consistency and remove invalid image rows.
UPDATE product_variants v
INNER JOIN products p ON p.product_id = v.product_id
SET v.is_active = 0
WHERE p.is_active = 0 AND v.is_active <> 0;

DELETE i
FROM product_images i
LEFT JOIN products p ON p.product_id = i.product_id
WHERE p.product_id IS NULL;

UPDATE product_images AS image_row
INNER JOIN (
    SELECT image_id,
           ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY sort_order, image_id) - 1 AS corrected_sort_order
    FROM product_images
) AS ranked_images ON ranked_images.image_id = image_row.image_id
SET image_row.sort_order = ranked_images.corrected_sort_order;

-- Keep only the newest payment per order and make its amount/status consistent.
DELETE older
FROM payments older
INNER JOIN payments newer ON newer.order_id = older.order_id
    AND (newer.created_at > older.created_at
         OR (newer.created_at = older.created_at AND newer.payment_id > older.payment_id));

UPDATE payments p
INNER JOIN orders o ON o.order_id = p.order_id
INNER JOIN order_statuses os ON os.order_status_id = o.order_status_id
SET p.amount = o.total_amount,
    p.payment_status = CASE
        WHEN os.status_name = 'Completed' THEN 'paid'
        WHEN os.status_name = 'Cancelled' AND p.payment_status = 'paid' THEN 'refunded'
        ELSE p.payment_status
    END;

-- Ensure completed orders alone have one correctly-valued sale row.
DELETE s
FROM sales s
INNER JOIN orders o ON o.order_id = s.order_id
INNER JOIN order_statuses os ON os.order_status_id = o.order_status_id
WHERE os.status_name <> 'Completed';

UPDATE sales s
INNER JOIN orders o ON o.order_id = s.order_id
INNER JOIN order_statuses os ON os.order_status_id = o.order_status_id
SET s.total_amount = o.total_amount,
    s.transaction_reference = CONCAT('TXN-', o.order_id, '-', DATE_FORMAT(s.sale_date, '%Y%m%d%H%i%s'))
WHERE os.status_name = 'Completed'
  AND (s.total_amount <> o.total_amount
       OR s.transaction_reference NOT REGEXP CONCAT('^TXN-', o.order_id, '-[0-9]{14}$'));

INSERT INTO sales (order_id, transaction_reference, total_amount, sale_date, notes)
SELECT o.order_id,
       CONCAT('TXN-', o.order_id, '-', DATE_FORMAT(o.placed_at, '%Y%m%d%H%i%s')),
       o.total_amount,
       o.placed_at,
       'Auto-recorded when order was marked completed'
FROM orders o
INNER JOIN order_statuses os ON os.order_status_id = o.order_status_id
LEFT JOIN sales s ON s.order_id = o.order_id
WHERE os.status_name = 'Completed' AND s.sale_id IS NULL;

-- Remove reviews that are not tied to an eligible purchase and keep the newest
-- review per user/product pair. The product-level unique key is declared above.
DELETE pr
FROM product_reviews pr
LEFT JOIN order_items oi ON oi.order_item_id = pr.order_item_id
LEFT JOIN orders o ON o.order_id = oi.order_id AND o.user_id = pr.user_id
LEFT JOIN order_statuses os ON os.order_status_id = o.order_status_id
LEFT JOIN product_variants v ON v.variant_id = oi.variant_id
WHERE o.order_id IS NULL
   OR v.product_id IS NULL
   OR v.product_id <> pr.product_id
   OR os.status_name NOT IN ('Processing', 'Packed', 'Shipped', 'Delivered', 'Completed');

DELETE older
FROM product_reviews older
INNER JOIN product_reviews newer ON newer.user_id = older.user_id
    AND newer.product_id = older.product_id
    AND (newer.created_at > older.created_at
         OR (newer.created_at = older.created_at AND newer.review_id > older.review_id));

-- Keep cart quantities within current stock; remove carts for out-of-stock variants.
DELETE ci
FROM cart_items ci
INNER JOIN product_variants v ON v.variant_id = ci.variant_id
WHERE v.stock_quantity = 0;

UPDATE cart_items ci
INNER JOIN product_variants v ON v.variant_id = ci.variant_id
SET ci.quantity = v.stock_quantity
WHERE ci.quantity > v.stock_quantity;

-- No profanity was present in the imported review text.
ALTER TABLE account_statuses AUTO_INCREMENT=3;
ALTER TABLE users AUTO_INCREMENT=18;
ALTER TABLE addresses AUTO_INCREMENT=22;
ALTER TABLE product_categories AUTO_INCREMENT=3;
ALTER TABLE product_types AUTO_INCREMENT=4;
ALTER TABLE products AUTO_INCREMENT=63;
ALTER TABLE product_images AUTO_INCREMENT=61;
ALTER TABLE sizes AUTO_INCREMENT=8;
ALTER TABLE colors AUTO_INCREMENT=10;
ALTER TABLE product_variants AUTO_INCREMENT=783;
ALTER TABLE cart_items AUTO_INCREMENT=23;
ALTER TABLE order_statuses AUTO_INCREMENT=8;
ALTER TABLE orders AUTO_INCREMENT=45;
ALTER TABLE order_items AUTO_INCREMENT=85;
ALTER TABLE payments AUTO_INCREMENT=42;
ALTER TABLE sales AUTO_INCREMENT=27;
ALTER TABLE expenses AUTO_INCREMENT=21;
ALTER TABLE product_reviews AUTO_INCREMENT=7;

SET FOREIGN_KEY_CHECKS=1;
DELIMITER $$
CREATE TRIGGER trg_orders_insert_completed_sale
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
    IF NEW.order_status_id = (
        SELECT order_status_id FROM order_statuses WHERE status_name = 'Completed'
    )
    THEN
        INSERT INTO sales (
            order_id,
            transaction_reference,
            total_amount,
            sale_date,
            notes
        )
        VALUES (
            NEW.order_id,
            CONCAT('TXN-', NEW.order_id, '-', DATE_FORMAT(NEW.placed_at, '%Y%m%d%H%i%s')),
            NEW.total_amount,
            NEW.placed_at,
            'Auto-recorded when order was created as completed'
        )
        ON DUPLICATE KEY UPDATE
            transaction_reference = VALUES(transaction_reference),
            total_amount = VALUES(total_amount),
            sale_date = VALUES(sale_date),
            notes = VALUES(notes);
    END IF;
END$$
CREATE TRIGGER trg_orders_completed_to_sale
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    IF NEW.order_status_id = (
        SELECT order_status_id FROM order_statuses WHERE status_name = 'Completed'
    )
       AND (OLD.order_status_id IS NULL OR OLD.order_status_id <> NEW.order_status_id)
    THEN
        INSERT INTO sales (
            order_id,
            transaction_reference,
            total_amount,
            notes,
            sale_date
        )
        VALUES (
            NEW.order_id,
            CONCAT('TXN-', NEW.order_id, '-', DATE_FORMAT(NOW(), '%Y%m%d%H%i%s')),
            NEW.total_amount,
            'Auto-recorded when order was marked completed',
            CURRENT_TIMESTAMP
        )
        ON DUPLICATE KEY UPDATE
            transaction_reference = VALUES(transaction_reference),
            total_amount = VALUES(total_amount),
            notes = VALUES(notes),
            sale_date = VALUES(sale_date);
    END IF;
END$$
DELIMITER ;

-- Verification queries (run after import)
SELECT 'account_statuses' AS table_name, COUNT(*) AS row_count FROM account_statuses
UNION ALL SELECT 'users', COUNT(*) FROM users
UNION ALL SELECT 'addresses', COUNT(*) FROM addresses
UNION ALL SELECT 'product_categories', COUNT(*) FROM product_categories
UNION ALL SELECT 'product_types', COUNT(*) FROM product_types
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'product_images', COUNT(*) FROM product_images
UNION ALL SELECT 'sizes', COUNT(*) FROM sizes
UNION ALL SELECT 'colors', COUNT(*) FROM colors
UNION ALL SELECT 'product_variants', COUNT(*) FROM product_variants
UNION ALL SELECT 'cart_items', COUNT(*) FROM cart_items
UNION ALL SELECT 'order_statuses', COUNT(*) FROM order_statuses
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'payments', COUNT(*) FROM payments
UNION ALL SELECT 'sales', COUNT(*) FROM sales
UNION ALL SELECT 'expenses', COUNT(*) FROM expenses
UNION ALL SELECT 'product_reviews', COUNT(*) FROM product_reviews;

SELECT 'orders_total_equals_subtotal_mismatches' AS check_name, COUNT(*) AS mismatch_count
FROM orders WHERE total_amount <> subtotal
UNION ALL
SELECT 'orders_subtotal_vs_line_sum_mismatches', COUNT(*)
FROM (
    SELECT o.order_id
    FROM orders o
    LEFT JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY o.order_id, o.subtotal
    HAVING o.subtotal <> COALESCE(ROUND(SUM(oi.line_total), 2), 0)
) mismatched_orders
UNION ALL
SELECT 'order_item_line_math_mismatches', COUNT(*)
FROM order_items
WHERE line_total <> ROUND(unit_price * quantity, 2)
UNION ALL
SELECT 'sales_amount_mismatches', COUNT(*)
FROM sales s
INNER JOIN orders o ON o.order_id = s.order_id
WHERE s.total_amount <> o.total_amount
UNION ALL
SELECT 'payment_amount_mismatches', COUNT(*)
FROM payments p
INNER JOIN orders o ON o.order_id = p.order_id
WHERE p.amount <> o.total_amount
UNION ALL
SELECT 'sales_status_mismatches', COUNT(*)
FROM (
    SELECT o.order_id, os.status_name, COUNT(s.sale_id) AS sale_count
    FROM orders o
    INNER JOIN order_statuses os ON os.order_status_id = o.order_status_id
    LEFT JOIN sales s ON s.order_id = o.order_id
    GROUP BY o.order_id, os.status_name
    HAVING (os.status_name = 'Completed' AND COUNT(s.sale_id) <> 1)
        OR (os.status_name <> 'Completed' AND COUNT(s.sale_id) <> 0)
) invalid_sales
UNION ALL
SELECT 'duplicate_transaction_references', COUNT(*)
FROM (
    SELECT transaction_reference
    FROM sales
    GROUP BY transaction_reference
    HAVING COUNT(*) > 1
) duplicate_references
UNION ALL
SELECT 'duplicate_reviews_per_user_product', COUNT(*)
FROM (
    SELECT user_id, product_id
    FROM product_reviews
    GROUP BY user_id, product_id
    HAVING COUNT(*) > 1
) duplicate_reviews
UNION ALL
SELECT 'review_order_item_owner_product_mismatches', COUNT(*)
FROM product_reviews r
INNER JOIN order_items oi ON oi.order_item_id = r.order_item_id
INNER JOIN orders o ON o.order_id = oi.order_id
LEFT JOIN product_variants v ON v.variant_id = oi.variant_id
WHERE r.user_id <> o.user_id
   OR v.variant_id IS NULL
   OR r.product_id <> v.product_id;

SELECT 'vw_order_transaction_details_rows' AS check_name, COUNT(*) AS result_count
FROM vw_order_transaction_details;
SELECT 'vw_order_transaction_details_exists' AS check_name, COUNT(*) AS result_count
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'vw_order_transaction_details';
SELECT 'completed_sale_insert_trigger_exists' AS check_name, COUNT(*) AS result_count
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = DATABASE()
  AND TRIGGER_NAME = 'trg_orders_insert_completed_sale';
SELECT 'completed_sale_update_trigger_exists' AS check_name, COUNT(*) AS result_count
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = DATABASE()
  AND TRIGGER_NAME = 'trg_orders_completed_to_sale';
SELECT 'uq_review_user_product_exists' AS check_name, COUNT(DISTINCT INDEX_NAME) AS result_count
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'product_reviews'
  AND INDEX_NAME = 'uq_review_user_product'
  AND NON_UNIQUE = 0;
