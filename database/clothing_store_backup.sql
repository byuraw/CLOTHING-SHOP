/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.19  Distrib 10.11.16-MariaDB, for Win64 (AMD64)
--
-- Host: 127.0.0.1    Database: clothing_store_fixed
-- ------------------------------------------------------
-- Server version	10.11.16-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `clothing_store_fixed`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `clothing_store_fixed` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */;

USE `clothing_store_fixed`;

--
-- Table structure for table `account_statuses`
--

DROP TABLE IF EXISTS `account_statuses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `account_statuses` (
  `status_id` tinyint(3) unsigned NOT NULL AUTO_INCREMENT,
  `status_name` varchar(30) NOT NULL,
  PRIMARY KEY (`status_id`),
  UNIQUE KEY `status_name` (`status_name`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `account_statuses`
--

LOCK TABLES `account_statuses` WRITE;
/*!40000 ALTER TABLE `account_statuses` DISABLE KEYS */;
INSERT INTO `account_statuses` VALUES
(1,'Active'),
(2,'Disabled');
/*!40000 ALTER TABLE `account_statuses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `addresses`
--

DROP TABLE IF EXISTS `addresses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `addresses` (
  `address_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) unsigned NOT NULL,
  `recipient_name` varchar(160) NOT NULL,
  `phone` varchar(30) NOT NULL,
  `address_line1` varchar(190) NOT NULL,
  `city` varchar(100) NOT NULL,
  `province` varchar(100) NOT NULL,
  `postal_code` varchar(20) NOT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`address_id`),
  KEY `idx_addresses_user_default` (`user_id`,`is_default`),
  CONSTRAINT `addresses_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `addresses`
--

LOCK TABLES `addresses` WRITE;
/*!40000 ALTER TABLE `addresses` DISABLE KEYS */;
INSERT INTO `addresses` VALUES
(8,9,'Alex Reyes','09171230001','Blk 12 Lot 4, Sampaguita St.','Taguig City','Metro Manila','1630',1,'2026-10-27 18:55:57'),
(9,10,'Mika Santos','09171230002','Unit 3B, 28 Rizal Ave.','Makati City','Metro Manila','1210',1,'2026-10-27 18:55:57'),
(10,11,'Jordan Cruz','09171230003','15 Narra Street','Pasig City','Metro Manila','1600',1,'2026-10-27 18:55:57'),
(11,12,'Sam Garcia','09171230004','22 Mabini Road','Mandaluyong City','Metro Manila','1550',1,'2026-10-27 18:55:57'),
(12,13,'Taylor Dela Cruz','09171230005','Unit 5, 8 Bonifacio St.','Taguig City','Metro Manila','1634',1,'2026-10-27 18:55:57'),
(13,14,'Casey Mendoza','09171230006','9 Acacia Lane','Quezon City','Metro Manila','1104',1,'2026-10-27 18:55:57'),
(20,16,'Justine Sabalza','09090909090','Blk 7 SDH','Taguig City','NCR','1632',0,'2026-10-28 07:29:51');
/*!40000 ALTER TABLE `addresses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cart_items`
--

DROP TABLE IF EXISTS `cart_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `cart_items` (
  `cart_item_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) unsigned NOT NULL,
  `variant_id` bigint(20) unsigned NOT NULL,
  `quantity` int(10) unsigned NOT NULL,
  `added_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`cart_item_id`),
  UNIQUE KEY `uq_cart_user_variant` (`user_id`,`variant_id`),
  KEY `variant_id` (`variant_id`),
  CONSTRAINT `cart_items_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `cart_items_ibfk_2` FOREIGN KEY (`variant_id`) REFERENCES `product_variants` (`variant_id`),
  CONSTRAINT `CONSTRAINT_1` CHECK (`quantity` > 0)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cart_items`
--

LOCK TABLES `cart_items` WRITE;
/*!40000 ALTER TABLE `cart_items` DISABLE KEYS */;
/*!40000 ALTER TABLE `cart_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `colors`
--

DROP TABLE IF EXISTS `colors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `colors` (
  `color_id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `color_name` varchar(50) NOT NULL,
  PRIMARY KEY (`color_id`),
  UNIQUE KEY `color_name` (`color_name`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `colors`
--

LOCK TABLES `colors` WRITE;
/*!40000 ALTER TABLE `colors` DISABLE KEYS */;
INSERT INTO `colors` VALUES
(5,'Beige'),
(1,'Black'),
(3,'Blue'),
(9,'Brown'),
(6,'Gray'),
(4,'Navy'),
(7,'Olive'),
(8,'Pink'),
(2,'White');
/*!40000 ALTER TABLE `colors` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `expenses`
--

DROP TABLE IF EXISTS `expenses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `expenses` (
  `expense_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `recorded_by` bigint(20) unsigned DEFAULT NULL,
  `expense_name` varchar(180) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `expense_date` date NOT NULL,
  `notes` varchar(500) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`expense_id`),
  KEY `recorded_by` (`recorded_by`),
  KEY `idx_expenses_date` (`expense_date`),
  CONSTRAINT `expenses_ibfk_1` FOREIGN KEY (`recorded_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  CONSTRAINT `CONSTRAINT_1` CHECK (`amount` >= 0)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `expenses`
--

LOCK TABLES `expenses` WRITE;
/*!40000 ALTER TABLE `expenses` DISABLE KEYS */;
INSERT INTO `expenses` VALUES
(8,NULL,'Packaging materials',1850.00,'2026-10-02','Boxes, mailers, tape, and labels for demo orders','2026-10-27 18:55:57'),
(9,NULL,'Courier pickup fees',1260.00,'2026-10-06','Sample logistics expense','2026-10-27 18:55:57'),
(10,NULL,'Product photography',3500.00,'2026-10-09','Catalog photo shoot expense','2026-10-27 18:55:57'),
(11,NULL,'Store internet',1499.00,'2026-10-12','Monthly connectivity expense','2026-10-27 18:55:57'),
(12,NULL,'Packaging materials',980.00,'2026-10-16','Restock of packaging supplies','2026-10-27 18:55:57'),
(13,NULL,'Online promotion',2200.00,'2026-10-20','Sample social media promotion expense','2026-10-27 18:55:57'),
(14,NULL,'Courier pickup fees',1640.00,'2026-10-25','Sample logistics expense','2026-10-27 18:55:57');
/*!40000 ALTER TABLE `expenses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `inventory_transactions`
--

DROP TABLE IF EXISTS `inventory_transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `inventory_transactions` (
  `inventory_transaction_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `variant_id` bigint(20) unsigned NOT NULL,
  `changed_by` bigint(20) unsigned DEFAULT NULL,
  `quantity_change` int(11) NOT NULL,
  `reason` varchar(100) NOT NULL,
  `reference_text` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`inventory_transaction_id`),
  KEY `changed_by` (`changed_by`),
  KEY `idx_inventory_variant_time` (`variant_id`,`created_at`),
  CONSTRAINT `inventory_transactions_ibfk_1` FOREIGN KEY (`variant_id`) REFERENCES `product_variants` (`variant_id`),
  CONSTRAINT `inventory_transactions_ibfk_2` FOREIGN KEY (`changed_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inventory_transactions`
--

LOCK TABLES `inventory_transactions` WRITE;
/*!40000 ALTER TABLE `inventory_transactions` DISABLE KEYS */;
INSERT INTO `inventory_transactions` VALUES
(12,1,NULL,5,'INITIAL_STOCK','DEMO-STOCK-RECEIPT-001','2026-10-01 01:00:00'),
(13,21,NULL,-1,'SALE','DEMO-STOCK-SALE-002','2026-10-03 06:20:00'),
(14,61,NULL,-1,'SALE','DEMO-STOCK-SALE-004','2026-10-08 09:45:00'),
(15,201,NULL,-1,'SALE','DEMO-STOCK-SALE-006','2026-10-12 05:10:00'),
(16,361,NULL,10,'RESTOCK','DEMO-STOCK-RECEIPT-002','2026-10-15 02:00:00'),
(19,41,1,1,'RESTOCK','DEMO-SAMPLE-ORD-003','2026-10-27 19:00:19'),
(20,164,16,-5,'SALE','ORD-20261027-7D6F9B','2026-10-27 19:02:49'),
(21,778,16,-2,'SALE','ORD-20261027-7D6F9B','2026-10-27 19:02:49'),
(22,382,16,-1,'SALE','ORD-20261027-13990B','2026-10-27 19:10:40'),
(23,592,16,-1,'SALE','ORD-20261027-F81332','2026-10-27 19:10:53'),
(24,203,16,-2,'SALE','ORD-20261028-4AEA62','2026-10-28 07:17:43'),
(25,382,16,-1,'SALE','ORD-20261028-4AEA62','2026-10-28 07:17:43'),
(26,372,16,-1,'SALE','ORD-20261028-E12A19','2026-10-28 07:28:07'),
(27,8,16,-2,'SALE','ORD-20261028-C2A808','2026-10-28 07:51:20'),
(28,9,16,-1,'SALE','ORD-20261028-C2A808','2026-10-28 07:51:20'),
(29,384,16,-1,'SALE','ORD-20261028-C2A808','2026-10-28 07:51:20');
/*!40000 ALTER TABLE `inventory_transactions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `order_items`
--

DROP TABLE IF EXISTS `order_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `order_items` (
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
) ENGINE=InnoDB AUTO_INCREMENT=73 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `order_items`
--

LOCK TABLES `order_items` WRITE;
/*!40000 ALTER TABLE `order_items` DISABLE KEYS */;
INSERT INTO `order_items` VALUES
(32,16,1,'Basic T-Shirt','BASICTSHIR-BLA-XS','XS','Black',299.00,1,299.00),
(33,17,21,'Polo Shirt','POLOSHIRT-BLA-XS','XS','Black',449.00,1,449.00),
(34,17,1,'Basic T-Shirt','BASICTSHIR-BLA-XS','XS','Black',299.00,1,299.00),
(35,18,41,'Button-Down Shirt','BUTTONDOWN-BLA-XS','XS','Black',599.00,1,599.00),
(36,19,61,'Hoodie','HOODIE-BLA-XS','XS','Black',699.00,1,699.00),
(37,19,1,'Basic T-Shirt','BASICTSHIR-BLA-XS','XS','Black',349.00,1,349.00),
(38,20,21,'Polo Shirt','POLOSHIRT-BLA-XS','XS','Black',449.00,1,449.00),
(39,21,201,'Slim-Fit Jeans','SLIMFITJEA-BLA-S','S','Black',599.00,1,599.00),
(40,21,361,'Baseball Cap','BASEBALLCA-BLA-OS','One Size','Black',299.00,1,299.00),
(41,22,1,'Basic T-Shirt','BASICTSHIR-BLA-XS','XS','Black',399.00,1,399.00),
(42,23,61,'Hoodie','HOODIE-BLA-XS','XS','Black',699.00,1,699.00),
(43,23,21,'Polo Shirt','POLOSHIRT-BLA-XS','XS','Black',449.00,1,449.00),
(44,23,361,'Baseball Cap','BASEBALLCA-BLA-OS','One Size','Black',150.00,1,150.00),
(45,24,201,'Slim-Fit Jeans','SLIMFITJEA-BLA-S','S','Black',699.00,1,699.00),
(46,25,41,'Button-Down Shirt','BUTTONDOWN-BLA-XS','XS','Black',599.00,1,599.00),
(47,25,1,'Basic T-Shirt','BASICTSHIR-BLA-XS','XS','Black',399.00,1,399.00),
(63,32,164,'Long-Sleeve Shirt','LONGSLEEVE-BLA-L','L','Black',399.00,5,1995.00),
(64,32,778,'Newsboy Cap','NEWSBOYCAP-BLA-OS','One Size','Black',399.00,2,798.00),
(65,33,382,'Beret','BERET-BLA-OS','One Size','Black',349.00,1,349.00),
(66,34,592,'Skinny Jeans','SKINNYJEAN-BLA-M','M','Black',899.00,1,899.00),
(67,35,203,'Slim-Fit Jeans','SLIMFITJEA-BLA-L','L','Black',899.00,2,1798.00),
(68,35,382,'Beret','BERET-BLA-OS','One Size','Black',349.00,1,349.00),
(69,36,372,'Fedora Hat','FEDORAHAT-NAV-OS','One Size','Navy',519.00,1,519.00),
(70,37,8,'Basic T-Shirt','BASICTSHIR-WHI-M','M','White',299.00,2,598.00),
(71,37,9,'Basic T-Shirt','BASICTSHIR-WHI-L','L','White',299.00,1,299.00),
(72,37,384,'Beret','BERET-NAV-OS','One Size','Navy',369.00,1,369.00);
/*!40000 ALTER TABLE `order_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `order_status_history`
--

DROP TABLE IF EXISTS `order_status_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `order_status_history` (
  `history_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` bigint(20) unsigned NOT NULL,
  `order_status_id` tinyint(3) unsigned NOT NULL,
  `changed_by` bigint(20) unsigned DEFAULT NULL,
  `note` varchar(500) DEFAULT NULL,
  `changed_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`history_id`),
  KEY `order_status_id` (`order_status_id`),
  KEY `changed_by` (`changed_by`),
  KEY `idx_history_order_time` (`order_id`,`changed_at`),
  CONSTRAINT `order_status_history_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE,
  CONSTRAINT `order_status_history_ibfk_2` FOREIGN KEY (`order_status_id`) REFERENCES `order_statuses` (`order_status_id`),
  CONSTRAINT `order_status_history_ibfk_3` FOREIGN KEY (`changed_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=48 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `order_status_history`
--

LOCK TABLES `order_status_history` WRITE;
/*!40000 ALTER TABLE `order_status_history` DISABLE KEYS */;
INSERT INTO `order_status_history` VALUES
(18,16,5,NULL,'Sample data status: Delivered','2026-10-01 02:15:00'),
(19,17,6,NULL,'Sample data status: Completed','2026-10-03 06:20:00'),
(20,18,5,NULL,'Sample data status: Delivered','2026-10-05 01:30:00'),
(21,19,4,NULL,'Sample data status: Shipped','2026-10-08 09:45:00'),
(22,20,2,NULL,'Sample data status: Processing','2026-10-10 03:05:00'),
(23,21,7,NULL,'Sample data status: Cancelled','2026-10-12 05:10:00'),
(24,22,1,NULL,'Sample data status: Pending','2026-10-15 08:00:00'),
(25,23,5,NULL,'Sample data status: Delivered','2026-10-18 04:25:00'),
(26,24,3,NULL,'Sample data status: Packed','2026-10-21 00:40:00'),
(27,25,5,NULL,'Sample data status: Delivered','2026-10-24 11:15:00'),
(33,18,7,1,'Changed from Delivered to Cancelled','2026-10-27 19:00:19'),
(34,32,1,16,'Order placed','2026-10-27 19:02:49'),
(35,32,6,1,'Changed from Pending to Completed','2026-10-27 19:03:27'),
(36,25,6,1,'Changed from Delivered to Completed','2026-10-27 19:03:48'),
(37,23,6,1,'Changed from Delivered to Completed','2026-10-27 19:04:03'),
(38,33,1,16,'Order placed','2026-10-27 19:10:40'),
(39,34,1,16,'Order placed','2026-10-27 19:10:53'),
(40,33,6,1,'Changed from Pending to Completed','2026-10-27 19:11:16'),
(41,34,6,1,'Changed from Pending to Completed','2026-10-27 19:11:23'),
(42,35,1,16,'Order placed','2026-10-28 07:17:43'),
(43,35,6,1,'Changed from Pending to Completed','2026-10-28 07:18:48'),
(44,36,1,16,'Order placed','2026-10-28 07:28:07'),
(45,36,6,1,'Changed from Pending to Completed','2026-10-28 07:47:29'),
(46,37,1,16,'Order placed','2026-10-28 07:51:20'),
(47,37,6,1,'Changed from Pending to Completed','2026-10-28 08:02:05');
/*!40000 ALTER TABLE `order_status_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `order_statuses`
--

DROP TABLE IF EXISTS `order_statuses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `order_statuses` (
  `order_status_id` tinyint(3) unsigned NOT NULL AUTO_INCREMENT,
  `status_name` varchar(30) NOT NULL,
  PRIMARY KEY (`order_status_id`),
  UNIQUE KEY `status_name` (`status_name`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `order_statuses`
--

LOCK TABLES `order_statuses` WRITE;
/*!40000 ALTER TABLE `order_statuses` DISABLE KEYS */;
INSERT INTO `order_statuses` VALUES
(7,'Cancelled'),
(6,'Completed'),
(5,'Delivered'),
(3,'Packed'),
(1,'Pending'),
(2,'Processing'),
(4,'Shipped');
/*!40000 ALTER TABLE `order_statuses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `orders`
--

DROP TABLE IF EXISTS `orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `orders` (
  `order_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) unsigned NOT NULL,
  `address_id` bigint(20) unsigned DEFAULT NULL,
  `order_status_id` tinyint(3) unsigned NOT NULL,
  `order_number` varchar(40) NOT NULL,
  `subtotal` decimal(10,2) NOT NULL,
  `shipping_fee` decimal(10,2) NOT NULL DEFAULT 0.00,
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
  CONSTRAINT `CONSTRAINT_1` CHECK (`subtotal` >= 0 and `shipping_fee` >= 0 and `total_amount` >= 0)
) ENGINE=InnoDB AUTO_INCREMENT=40 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `orders`
--

LOCK TABLES `orders` WRITE;
/*!40000 ALTER TABLE `orders` DISABLE KEYS */;
INSERT INTO `orders` VALUES
(16,9,8,5,'ORD-20261001-A1B201',299.00,79.00,378.00,'Single-item transaction','2026-10-01 02:15:00','2026-10-27 19:25:26'),
(17,10,9,6,'ORD-20261003-A1B202',748.00,79.00,827.00,'Multi-item transaction: 2 units across 2 items','2026-10-03 06:20:00','2026-10-27 19:25:26'),
(18,11,10,7,'ORD-20261005-A1B203',599.00,79.00,678.00,'Single-item transaction','2026-10-05 01:30:00','2026-10-27 19:25:26'),
(19,12,11,4,'ORD-20261008-A1B204',1048.00,79.00,1127.00,'Multi-item transaction: 3 units across 2 items','2026-10-08 09:45:00','2026-10-27 19:25:26'),
(20,13,12,2,'ORD-20261010-A1B205',449.00,79.00,528.00,'Single-item transaction','2026-10-10 03:05:00','2026-10-27 19:25:26'),
(21,14,13,7,'ORD-20261012-A1B206',898.00,79.00,977.00,'Multi-item transaction: 2 items','2026-10-12 05:10:00','2026-10-27 19:25:26'),
(22,9,8,1,'ORD-20261015-A1B207',399.00,79.00,478.00,'Single-item transaction','2026-10-15 08:00:00','2026-10-27 19:25:26'),
(23,10,9,6,'ORD-20261018-A1B208',1298.00,79.00,1377.00,'Multi-item transaction: 3 items','2026-10-18 04:25:00','2026-10-27 19:25:26'),
(24,11,10,3,'ORD-20261021-A1B209',699.00,79.00,778.00,'Single-item transaction','2026-10-21 00:40:00','2026-10-27 19:25:26'),
(25,12,11,6,'ORD-20261024-A1B20A',998.00,79.00,1077.00,'Multi-item transaction: 2 items','2026-10-24 11:15:00','2026-10-27 19:25:26'),
(32,16,NULL,6,'ORD-20261027-7D6F9B',2793.00,0.00,2793.00,NULL,'2026-10-27 19:02:49','2026-10-27 19:03:27'),
(33,16,NULL,6,'ORD-20261027-13990B',349.00,0.00,349.00,NULL,'2026-10-27 19:10:40','2026-10-27 19:11:16'),
(34,16,NULL,6,'ORD-20261027-F81332',899.00,0.00,899.00,NULL,'2026-10-27 19:10:53','2026-10-27 19:11:23'),
(35,16,NULL,6,'ORD-20261028-4AEA62',2147.00,0.00,2147.00,NULL,'2026-10-28 07:17:43','2026-10-28 07:18:48'),
(36,16,NULL,6,'ORD-20261028-E12A19',519.00,0.00,519.00,NULL,'2026-10-28 07:28:07','2026-10-28 07:47:29'),
(37,16,20,6,'ORD-20261028-C2A808',1266.00,0.00,1266.00,NULL,'2026-10-28 07:51:20','2026-10-28 08:02:05');
/*!40000 ALTER TABLE `orders` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_orders_insert_completed_sale
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'NO_ZERO_IN_DATE,NO_ZERO_DATE,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_orders_completed_to_sale
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `payments`
--

DROP TABLE IF EXISTS `payments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `payments` (
  `payment_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` bigint(20) unsigned NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `payment_status` enum('pending','paid','failed','refunded') NOT NULL DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`payment_id`),
  KEY `idx_payments_order_status` (`order_id`,`payment_status`),
  CONSTRAINT `payments_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`order_id`) ON DELETE CASCADE,
  CONSTRAINT `CONSTRAINT_1` CHECK (`amount` >= 0)
) ENGINE=InnoDB AUTO_INCREMENT=37 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `payments`
--

LOCK TABLES `payments` WRITE;
/*!40000 ALTER TABLE `payments` DISABLE KEYS */;
INSERT INTO `payments` VALUES
(16,16,378.00,'paid','2026-10-27 18:55:57'),
(17,17,827.00,'paid','2026-10-27 18:55:57'),
(18,18,678.00,'paid','2026-10-27 18:55:57'),
(19,19,1127.00,'pending','2026-10-27 18:55:57'),
(20,20,528.00,'pending','2026-10-27 18:55:57'),
(21,21,977.00,'refunded','2026-10-27 18:55:57'),
(22,22,478.00,'pending','2026-10-27 18:55:57'),
(23,23,1377.00,'paid','2026-10-27 18:55:57'),
(24,24,778.00,'pending','2026-10-27 18:55:57'),
(25,25,1077.00,'paid','2026-10-27 18:55:57'),
(31,32,2793.00,'pending','2026-10-27 19:02:49'),
(32,33,349.00,'pending','2026-10-27 19:10:40'),
(33,34,899.00,'pending','2026-10-27 19:10:53'),
(34,35,2147.00,'pending','2026-10-28 07:17:43'),
(35,36,519.00,'pending','2026-10-28 07:28:07'),
(36,37,1300.00,'pending','2026-10-28 07:51:20');
/*!40000 ALTER TABLE `payments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `product_categories`
--

DROP TABLE IF EXISTS `product_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `product_categories` (
  `product_category_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `category_name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`product_category_id`),
  UNIQUE KEY `category_name` (`category_name`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `product_categories`
--

LOCK TABLES `product_categories` WRITE;
/*!40000 ALTER TABLE `product_categories` DISABLE KEYS */;
INSERT INTO `product_categories` VALUES
(1,'Men\'s Clothing',NULL,1),
(2,'Women\'s Clothing',NULL,1);
/*!40000 ALTER TABLE `product_categories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `product_images`
--

DROP TABLE IF EXISTS `product_images`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `product_images` (
  `image_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `product_id` bigint(20) unsigned NOT NULL,
  `image_path` varchar(255) NOT NULL,
  `alt_text` varchar(190) DEFAULT NULL,
  `sort_order` smallint(5) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`image_id`),
  KEY `idx_images_product_order` (`product_id`,`sort_order`),
  CONSTRAINT `product_images_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=61 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `product_images`
--

LOCK TABLES `product_images` WRITE;
/*!40000 ALTER TABLE `product_images` DISABLE KEYS */;
INSERT INTO `product_images` VALUES
(1,1,'uploads/products/basic-t-shirt-main.jpg','Basic T-Shirt product photo',1),
(2,2,'uploads/products/polo-shirt-main.jpg','Polo Shirt product photo',1),
(3,3,'uploads/products/button-down-shirt-main.jpg','Button-Down Shirt product photo',1),
(4,4,'uploads/products/hoodie-main.jpg','Hoodie product photo',1),
(5,5,'uploads/products/sweatshirt-main.jpg','Sweatshirt product photo',1),
(6,6,'uploads/products/tank-top-main.jpg','Tank Top product photo',1),
(7,7,'uploads/products/henley-shirt-main.jpg','Henley Shirt product photo',1),
(8,8,'uploads/products/flannel-shirt-main.jpg','Flannel Shirt product photo',1),
(9,9,'uploads/products/long-sleeve-shirt-main.jpg','Long-Sleeve Shirt product photo',1),
(10,10,'uploads/products/knit-sweater-main.jpg','Knit Sweater product photo',1),
(11,11,'uploads/products/slim-fit-jeans-main.jpg','Slim-Fit Jeans product photo',1),
(12,12,'uploads/products/straight-leg-jeans-main.jpg','Straight-Leg Jeans product photo',1),
(13,13,'uploads/products/cargo-pants-main.jpg','Cargo Pants product photo',1),
(14,14,'uploads/products/chino-pants-main.jpg','Chino Pants product photo',1),
(15,15,'uploads/products/jogger-pants-main.jpg','Jogger Pants product photo',1),
(16,16,'uploads/products/denim-shorts-main.jpg','Denim Shorts product photo',1),
(17,17,'uploads/products/bermuda-shorts-main.jpg','Bermuda Shorts product photo',1),
(18,18,'uploads/products/dress-pants-main.jpg','Dress Pants product photo',1),
(19,19,'uploads/products/sweatpants-main.jpg','Sweatpants product photo',1),
(20,20,'uploads/products/linen-trousers-main.jpg','Linen Trousers product photo',1),
(21,21,'uploads/products/baseball-cap-main.jpg','Baseball Cap product photo',1),
(22,22,'uploads/products/bucket-hat-main.jpg','Bucket Hat product photo',1),
(23,23,'uploads/products/beanie-main.jpg','Beanie product photo',1),
(24,24,'uploads/products/fedora-hat-main.jpg','Fedora Hat product photo',1),
(25,25,'uploads/products/flat-cap-main.jpg','Flat Cap product photo',1),
(26,26,'uploads/products/snapback-cap-main.jpg','Snapback Cap product photo',1),
(27,27,'uploads/products/trucker-hat-main.jpg','Trucker Hat product photo',1),
(28,28,'uploads/products/beret-main.jpg','Beret product photo',1),
(29,29,'uploads/products/panama-hat-main.jpg','Panama Hat product photo',1),
(30,30,'uploads/products/fisherman-beanie-main.jpg','Fisherman Beanie product photo',1),
(31,31,'uploads/products/w-basic-t-shirt-main.jpg','Basic T-Shirt product photo',1),
(32,32,'uploads/products/crop-top-main.jpg','Crop Top product photo',1),
(33,33,'uploads/products/blouse-main.jpg','Blouse product photo',1),
(34,34,'uploads/products/camisole-main.jpg','Camisole product photo',1),
(35,35,'uploads/products/w-tank-top-main.jpg','Tank Top product photo',1),
(36,36,'uploads/products/off-shoulder-top-main.jpg','Off-Shoulder Top product photo',1),
(37,37,'uploads/products/halter-top-main.jpg','Halter Top product photo',1),
(38,38,'uploads/products/bodysuit-main.jpg','Bodysuit product photo',1),
(39,39,'uploads/products/cardigan-main.jpg','Cardigan product photo',1),
(40,40,'uploads/products/w-knit-sweater-main.jpg','Knit Sweater product photo',1),
(41,41,'uploads/products/skinny-jeans-main.jpg','Skinny Jeans product photo',1),
(42,42,'uploads/products/wide-leg-jeans-main.jpg','Wide-Leg Jeans product photo',1),
(43,43,'uploads/products/w-cargo-pants-main.jpg','Cargo Pants product photo',1),
(44,44,'uploads/products/high-waisted-trousers-main.jpg','High-Waisted Trousers product photo',1),
(45,45,'uploads/products/w-denim-shorts-main.jpg','Denim Shorts product photo',1),
(46,46,'uploads/products/mini-skirt-main.jpg','Mini Skirt product photo',1),
(47,47,'uploads/products/midi-skirt-main.jpg','Midi Skirt product photo',1),
(48,48,'uploads/products/maxi-skirt-main.jpg','Maxi Skirt product photo',1),
(49,49,'uploads/products/leggings-main.jpg','Leggings product photo',1),
(50,50,'uploads/products/palazzo-pants-main.jpg','Palazzo Pants product photo',1),
(51,51,'uploads/products/w-baseball-cap-main.jpg','Baseball Cap product photo',1),
(52,52,'uploads/products/w-bucket-hat-main.jpg','Bucket Hat product photo',1),
(53,53,'uploads/products/w-beanie-main.jpg','Beanie product photo',1),
(54,54,'uploads/products/w-beret-main.jpg','Beret product photo',1),
(55,55,'uploads/products/wide-brim-sun-hat-main.jpg','Wide-Brim Sun Hat product photo',1),
(56,56,'uploads/products/w-fedora-hat-main.jpg','Fedora Hat product photo',1),
(57,57,'uploads/products/straw-hat-main.jpg','Straw Hat product photo',1),
(58,58,'uploads/products/visor-cap-main.jpg','Visor Cap product photo',1),
(59,59,'uploads/products/cloche-hat-main.jpg','Cloche Hat product photo',1),
(60,60,'uploads/products/newsboy-cap-main.jpg','Newsboy Cap product photo',1);
/*!40000 ALTER TABLE `product_images` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `product_reviews`
--

DROP TABLE IF EXISTS `product_reviews`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `product_reviews` (
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
  KEY `order_item_id` (`order_item_id`),
  KEY `idx_reviews_product` (`product_id`,`created_at`),
  CONSTRAINT `product_reviews_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE,
  CONSTRAINT `product_reviews_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `product_reviews_ibfk_3` FOREIGN KEY (`order_item_id`) REFERENCES `order_items` (`order_item_id`) ON DELETE CASCADE,
  CONSTRAINT `CONSTRAINT_1` CHECK (`rating` between 1 and 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `product_reviews`
--

LOCK TABLES `product_reviews` WRITE;
/*!40000 ALTER TABLE `product_reviews` DISABLE KEYS */;
/*!40000 ALTER TABLE `product_reviews` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `product_types`
--

DROP TABLE IF EXISTS `product_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `product_types` (
  `product_type_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `type_name` varchar(100) NOT NULL,
  PRIMARY KEY (`product_type_id`),
  UNIQUE KEY `type_name` (`type_name`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `product_types`
--

LOCK TABLES `product_types` WRITE;
/*!40000 ALTER TABLE `product_types` DISABLE KEYS */;
INSERT INTO `product_types` VALUES
(2,'Bottom'),
(3,'Headwear'),
(1,'Top');
/*!40000 ALTER TABLE `product_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `product_variants`
--

DROP TABLE IF EXISTS `product_variants`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `product_variants` (
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
) ENGINE=InnoDB AUTO_INCREMENT=781 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `product_variants`
--

LOCK TABLES `product_variants` WRITE;
/*!40000 ALTER TABLE `product_variants` DISABLE KEYS */;
INSERT INTO `product_variants` VALUES
(1,1,1,1,'BASICTSHIR-BLA-XS',299.00,21,1),
(2,1,2,1,'BASICTSHIR-BLA-S',299.00,16,1),
(3,1,3,1,'BASICTSHIR-BLA-M',299.00,16,1),
(4,1,4,1,'BASICTSHIR-BLA-L',299.00,16,1),
(5,1,5,1,'BASICTSHIR-BLA-XL',299.00,21,1),
(6,1,1,2,'BASICTSHIR-WHI-XS',299.00,21,1),
(7,1,2,2,'BASICTSHIR-WHI-S',299.00,16,1),
(8,1,3,2,'BASICTSHIR-WHI-M',299.00,14,1),
(9,1,4,2,'BASICTSHIR-WHI-L',299.00,15,1),
(10,1,5,2,'BASICTSHIR-WHI-XL',299.00,21,1),
(11,1,1,4,'BASICTSHIR-NAV-XS',319.00,16,1),
(12,1,2,4,'BASICTSHIR-NAV-S',319.00,12,1),
(13,1,3,4,'BASICTSHIR-NAV-M',319.00,12,1),
(14,1,4,4,'BASICTSHIR-NAV-L',319.00,12,1),
(15,1,5,4,'BASICTSHIR-NAV-XL',319.00,16,1),
(16,1,1,7,'BASICTSHIR-OLI-XS',299.00,21,1),
(17,1,2,7,'BASICTSHIR-OLI-S',299.00,16,1),
(18,1,3,7,'BASICTSHIR-OLI-M',299.00,16,1),
(19,1,4,7,'BASICTSHIR-OLI-L',299.00,16,1),
(20,1,5,7,'BASICTSHIR-OLI-XL',299.00,21,1),
(21,2,1,1,'POLOSHIRT-BLA-XS',449.00,8,1),
(22,2,2,1,'POLOSHIRT-BLA-S',449.00,5,1),
(23,2,3,1,'POLOSHIRT-BLA-M',449.00,5,1),
(24,2,4,1,'POLOSHIRT-BLA-L',449.00,5,1),
(25,2,5,1,'POLOSHIRT-BLA-XL',449.00,8,1),
(26,2,1,2,'POLOSHIRT-WHI-XS',449.00,8,1),
(27,2,2,2,'POLOSHIRT-WHI-S',449.00,5,1),
(28,2,3,2,'POLOSHIRT-WHI-M',449.00,5,1),
(29,2,4,2,'POLOSHIRT-WHI-L',449.00,5,1),
(30,2,5,2,'POLOSHIRT-WHI-XL',449.00,8,1),
(31,2,1,4,'POLOSHIRT-NAV-XS',469.00,5,1),
(32,2,2,4,'POLOSHIRT-NAV-S',469.00,2,1),
(33,2,3,4,'POLOSHIRT-NAV-M',469.00,2,1),
(34,2,4,4,'POLOSHIRT-NAV-L',469.00,2,1),
(35,2,5,4,'POLOSHIRT-NAV-XL',469.00,5,1),
(36,2,1,7,'POLOSHIRT-OLI-XS',449.00,8,1),
(37,2,2,7,'POLOSHIRT-OLI-S',449.00,5,1),
(38,2,3,7,'POLOSHIRT-OLI-M',449.00,5,1),
(39,2,4,7,'POLOSHIRT-OLI-L',449.00,5,1),
(40,2,5,7,'POLOSHIRT-OLI-XL',449.00,8,1),
(41,3,1,1,'BUTTONDOWN-BLA-XS',599.00,9,1),
(42,3,2,1,'BUTTONDOWN-BLA-S',599.00,5,1),
(43,3,3,1,'BUTTONDOWN-BLA-M',599.00,5,1),
(44,3,4,1,'BUTTONDOWN-BLA-L',599.00,5,1),
(45,3,5,1,'BUTTONDOWN-BLA-XL',599.00,8,1),
(46,3,1,2,'BUTTONDOWN-WHI-XS',599.00,8,1),
(47,3,2,2,'BUTTONDOWN-WHI-S',599.00,5,1),
(48,3,3,2,'BUTTONDOWN-WHI-M',599.00,5,1),
(49,3,4,2,'BUTTONDOWN-WHI-L',599.00,5,1),
(50,3,5,2,'BUTTONDOWN-WHI-XL',599.00,8,1),
(51,3,1,4,'BUTTONDOWN-NAV-XS',619.00,5,1),
(52,3,2,4,'BUTTONDOWN-NAV-S',619.00,2,1),
(53,3,3,4,'BUTTONDOWN-NAV-M',619.00,2,1),
(54,3,4,4,'BUTTONDOWN-NAV-L',619.00,2,1),
(55,3,5,4,'BUTTONDOWN-NAV-XL',619.00,5,1),
(56,3,1,7,'BUTTONDOWN-OLI-XS',599.00,8,1),
(57,3,2,7,'BUTTONDOWN-OLI-S',599.00,5,1),
(58,3,3,7,'BUTTONDOWN-OLI-M',599.00,5,1),
(59,3,4,7,'BUTTONDOWN-OLI-L',599.00,5,1),
(60,3,5,7,'BUTTONDOWN-OLI-XL',599.00,8,1),
(61,4,1,1,'HOODIE-BLA-XS',799.00,21,1),
(62,4,2,1,'HOODIE-BLA-S',799.00,16,1),
(63,4,3,1,'HOODIE-BLA-M',799.00,16,1),
(64,4,4,1,'HOODIE-BLA-L',799.00,16,1),
(65,4,5,1,'HOODIE-BLA-XL',799.00,21,1),
(66,4,1,2,'HOODIE-WHI-XS',799.00,21,1),
(67,4,2,2,'HOODIE-WHI-S',799.00,16,1),
(68,4,3,2,'HOODIE-WHI-M',799.00,16,1),
(69,4,4,2,'HOODIE-WHI-L',799.00,16,1),
(70,4,5,2,'HOODIE-WHI-XL',799.00,21,1),
(71,4,1,4,'HOODIE-NAV-XS',819.00,16,1),
(72,4,2,4,'HOODIE-NAV-S',819.00,12,1),
(73,4,3,4,'HOODIE-NAV-M',819.00,12,1),
(74,4,4,4,'HOODIE-NAV-L',819.00,12,1),
(75,4,5,4,'HOODIE-NAV-XL',819.00,16,1),
(76,4,1,7,'HOODIE-OLI-XS',799.00,21,1),
(77,4,2,7,'HOODIE-OLI-S',799.00,16,1),
(78,4,3,7,'HOODIE-OLI-M',799.00,16,1),
(79,4,4,7,'HOODIE-OLI-L',799.00,16,1),
(80,4,5,7,'HOODIE-OLI-XL',799.00,21,1),
(81,5,1,1,'SWEATSHIRT-BLA-XS',699.00,8,1),
(82,5,2,1,'SWEATSHIRT-BLA-S',699.00,5,1),
(83,5,3,1,'SWEATSHIRT-BLA-M',699.00,5,1),
(84,5,4,1,'SWEATSHIR-BLA-L',699.00,5,1),
(85,5,5,1,'SWEATSHIRT-BLA-XL',699.00,8,1),
(86,5,1,2,'SWEATSHIRT-WHI-XS',699.00,8,1),
(87,5,2,2,'SWEATSHIRT-WHI-S',699.00,5,1),
(88,5,3,2,'SWEATSHIRT-WHI-M',699.00,5,1),
(89,5,4,2,'SWEATSHIRT-WHI-L',699.00,5,1),
(90,5,5,2,'SWEATSHIRT-WHI-XL',699.00,8,1),
(91,5,1,4,'SWEATSHIRT-NAV-XS',719.00,5,1),
(92,5,2,4,'SWEATSHIRT-NAV-S',719.00,2,1),
(93,5,3,4,'SWEATSHIRT-NAV-M',719.00,2,1),
(94,5,4,4,'SWEATSHIRT-NAV-L',719.00,2,1),
(95,5,5,4,'SWEATSHIRT-NAV-XL',719.00,5,1),
(96,5,1,7,'SWEATSHIRT-OLI-XS',699.00,8,1),
(97,5,2,7,'SWEATSHIRT-OLI-S',699.00,5,1),
(98,5,3,7,'SWEATSHIRT-OLI-M',699.00,5,1),
(99,5,4,7,'SWEATSHIRT-OLI-L',699.00,5,1),
(100,5,5,7,'SWEATSHIRT-OLI-XL',699.00,8,1),
(101,6,1,1,'TANKTOP-BLA-XS',249.00,2,1),
(102,6,2,1,'TANKTOP-BLA-S',249.00,0,1),
(103,6,3,1,'TANKTOP-BLA-M',249.00,0,1),
(104,6,4,1,'TANKTOP-BLA-L',249.00,0,1),
(105,6,5,1,'TANKTOP-BLA-XL',249.00,2,1),
(106,6,1,2,'TANKTOP-WHI-XS',249.00,2,1),
(107,6,2,2,'TANKTOP-WHI-S',249.00,0,1),
(108,6,3,2,'TANKTOP-WHI-M',249.00,0,1),
(109,6,4,2,'TANKTOP-WHI-L',249.00,0,1),
(110,6,5,2,'TANKTOP-WHI-XL',249.00,2,1),
(111,6,1,4,'TANKTOP-NAV-XS',269.00,0,1),
(112,6,2,4,'TANKTOP-NAV-S',269.00,21,1),
(113,6,3,4,'TANKTOP-NAV-M',269.00,21,1),
(114,6,4,4,'TANKTOP-NAV-L',269.00,21,1),
(115,6,5,4,'TANKTOP-NAV-XL',269.00,0,1),
(116,6,1,7,'TANKTOP-OLI-XS',249.00,2,1),
(117,6,2,7,'TANKTOP-OLI-S',249.00,0,1),
(118,6,3,7,'TANKTOP-OLI-M',249.00,0,1),
(119,6,4,7,'TANKTOP-OLI-L',249.00,0,1),
(120,6,5,7,'TANKTOP-OLI-XL',249.00,2,1),
(121,7,1,1,'HENLEYSHIR-BLA-XS',399.00,16,1),
(122,7,2,1,'HENLEYSHIR-BLA-S',399.00,12,1),
(123,7,3,1,'HENLEYSHIR-BLA-M',399.00,12,1),
(124,7,4,1,'HENLEYSHIR-BLA-L',399.00,12,1),
(125,7,5,1,'HENLEYSHIR-BLA-XL',399.00,16,1),
(126,7,1,2,'HENLEYSHIR-WHI-XS',399.00,16,1),
(127,7,2,2,'HENLEYSHIR-WHI-S',399.00,12,1),
(128,7,3,2,'HENLEYSHIR-WHI-M',399.00,12,1),
(129,7,4,2,'HENLEYSHIR-WHI-L',399.00,12,1),
(130,7,5,2,'HENLEYSHIR-WHI-XL',399.00,16,1),
(131,7,1,4,'HENLEYSHIR-NAV-XS',419.00,12,1),
(132,7,2,4,'HENLEYSHIR-NAV-S',419.00,8,1),
(133,7,3,4,'HENLEYSHIR-NAV-M',419.00,8,1),
(134,7,4,4,'HENLEYSHIR-NAV-L',419.00,8,1),
(135,7,5,4,'HENLEYSHIR-NAV-XL',419.00,12,1),
(136,7,1,7,'HENLEYSHIR-OLI-XS',399.00,16,1),
(137,7,2,7,'HENLEYSHIR-OLI-S',399.00,12,1),
(138,7,3,7,'HENLEYSHIR-OLI-M',399.00,12,1),
(139,7,4,7,'HENLEYSHIR-OLI-L',399.00,12,1),
(140,7,5,7,'HENLEYSHIR-OLI-XL',399.00,16,1),
(141,8,1,1,'FLANNELSHI-BLA-XS',649.00,21,1),
(142,8,2,1,'FLANNELSHI-BLA-S',649.00,16,1),
(143,8,3,1,'FLANNELSHI-BLA-M',649.00,16,1),
(144,8,4,1,'FLANNELSHI-BLA-L',649.00,16,1),
(145,8,5,1,'FLANNELSHI-BLA-XL',649.00,21,1),
(146,8,1,2,'FLANNELSHI-WHI-XS',649.00,21,1),
(147,8,2,2,'FLANNELSHI-WHI-S',649.00,16,1),
(148,8,3,2,'FLANNELSHI-WHI-M',649.00,16,1),
(149,8,4,2,'FLANNELSHI-WHI-L',649.00,16,1),
(150,8,5,2,'FLANNELSHI-WHI-XL',649.00,21,1),
(151,8,1,4,'FLANNELSHI-NAV-XS',669.00,16,1),
(152,8,2,4,'FLANNELSHI-NAV-S',669.00,12,1),
(153,8,3,4,'FLANNELSHI-NAV-M',669.00,12,1),
(154,8,4,4,'FLANNELSHI-NAV-L',669.00,12,1),
(155,8,5,4,'FLANNELSHI-NAV-XL',669.00,16,1),
(156,8,1,7,'FLANNELSHI-OLI-XS',649.00,21,1),
(157,8,2,7,'FLANNELSHI-OLI-S',649.00,16,1),
(158,8,3,7,'FLANNELSHI-OLI-M',649.00,16,1),
(159,8,4,7,'FLANNELSHI-OLI-L',649.00,16,1),
(160,8,5,7,'FLANNELSHI-OLI-XL',649.00,21,1),
(161,9,1,1,'LONGSLEEVE-BLA-XS',399.00,8,1),
(162,9,2,1,'LONGSLEEVE-BLA-S',399.00,5,1),
(163,9,3,1,'LONGSLEEVE-BLA-M',399.00,5,1),
(164,9,4,1,'LONGSLEEVE-BLA-L',399.00,0,1),
(165,9,5,1,'LONGSLEEVE-BLA-XL',399.00,8,1),
(166,9,1,2,'LONGSLEEVE-WHI-XS',399.00,8,1),
(167,9,2,2,'LONGSLEEVE-WHI-S',399.00,5,1),
(168,9,3,2,'LONGSLEEVE-WHI-M',399.00,5,1),
(169,9,4,2,'LONGSLEEVE-WHI-L',399.00,5,1),
(170,9,5,2,'LONGSLEEVE-WHI-XL',399.00,8,1),
(171,9,1,4,'LONGSLEEVE-NAV-XS',419.00,5,1),
(172,9,2,4,'LONGSLEEVE-NAV-S',419.00,2,1),
(173,9,3,4,'LONGSLEEVE-NAV-M',419.00,2,1),
(174,9,4,4,'LONGSLEEVE-NAV-L',419.00,2,1),
(175,9,5,4,'LONGSLEEVE-NAV-XL',419.00,5,1),
(176,9,1,7,'LONGSLEEVE-OLI-XS',399.00,8,1),
(177,9,2,7,'LONGSLEEVE-OLI-S',399.00,5,1),
(178,9,3,7,'LONGSLEEVE-OLI-M',399.00,5,1),
(179,9,4,7,'LONGSLEEVE-OLI-L',399.00,5,1),
(180,9,5,7,'LONGSLEEVE-OLI-XL',399.00,8,1),
(181,10,1,1,'KNITSWEATE-BLA-XS',799.00,16,1),
(182,10,2,1,'KNITSWEATE-BLA-S',799.00,12,1),
(183,10,3,1,'KNITSWEATE-BLA-M',799.00,12,1),
(184,10,4,1,'KNITSWEATE-BLA-L',799.00,12,1),
(185,10,5,1,'KNITSWEATE-BLA-XL',799.00,16,1),
(186,10,1,2,'KNITSWEATE-WHI-XS',799.00,16,1),
(187,10,2,2,'KNITSWEATE-WHI-S',799.00,12,1),
(188,10,3,2,'KNITSWEATE-WHI-M',799.00,12,1),
(189,10,4,2,'KNITSWEATE-WHI-L',799.00,12,1),
(190,10,5,2,'KNITSWEATE-WHI-XL',799.00,16,1),
(191,10,1,4,'KNITSWEATE-NAV-XS',819.00,12,1),
(192,10,2,4,'KNITSWEATE-NAV-S',819.00,8,1),
(193,10,3,4,'KNITSWEATE-NAV-M',819.00,8,1),
(194,10,4,4,'KNITSWEATE-NAV-L',819.00,8,1),
(195,10,5,4,'KNITSWEATE-NAV-XL',819.00,12,1),
(196,10,1,7,'KNITSWEATE-OLI-XS',799.00,16,1),
(197,10,2,7,'KNITSWEATE-OLI-S',799.00,12,1),
(198,10,3,7,'KNITSWEATE-OLI-M',799.00,12,1),
(199,10,4,7,'KNITSWEATE-OLI-L',799.00,12,1),
(200,10,5,7,'KNITSWEATE-OLI-XL',799.00,16,1),
(201,11,2,1,'SLIMFITJEA-BLA-S',899.00,21,1),
(202,11,3,1,'SLIMFITJEA-BLA-M',899.00,21,1),
(203,11,4,1,'SLIMFITJEA-BLA-L',899.00,19,1),
(204,11,5,1,'SLIMFITJEA-BLA-XL',899.00,0,1),
(205,11,2,2,'SLIMFITJEA-WHI-S',899.00,21,1),
(206,11,3,2,'SLIMFITJEA-WHI-M',899.00,21,1),
(207,11,4,2,'SLIMFITJEA-WHI-L',899.00,21,1),
(208,11,5,2,'SLIMFITJEA-WHI-XL',899.00,0,1),
(209,11,2,4,'SLIMFITJEA-NAV-S',919.00,16,1),
(210,11,3,4,'SLIMFITJEA-NAV-M',919.00,16,1),
(211,11,4,4,'SLIMFITJEA-NAV-L',919.00,16,1),
(212,11,5,4,'SLIMFITJEA-NAV-XL',919.00,21,1),
(213,11,2,7,'SLIMFITJEA-OLI-S',899.00,21,1),
(214,11,3,7,'SLIMFITJEA-OLI-M',899.00,21,1),
(215,11,4,7,'SLIMFITJEA-OLI-L',899.00,21,1),
(216,11,5,7,'SLIMFITJEA-OLI-XL',899.00,0,1),
(217,12,2,1,'STRAIGHTLE-BLA-S',899.00,8,1),
(218,12,3,1,'STRAIGHTLE-BLA-M',899.00,8,1),
(219,12,4,1,'STRAIGHTLE-BLA-L',899.00,8,1),
(220,12,5,1,'STRAIGHTLE-BLA-XL',899.00,12,1),
(221,12,2,2,'STRAIGHTLE-WHI-S',899.00,8,1),
(222,12,3,2,'STRAIGHTLE-WHI-M',899.00,8,1),
(223,12,4,2,'STRAIGHTLE-WHI-L',899.00,8,1),
(224,12,5,2,'STRAIGHTLE-WHI-XL',899.00,12,1),
(225,12,2,4,'STRAIGHTLE-NAV-S',919.00,5,1),
(226,12,3,4,'STRAIGHTLE-NAV-M',919.00,5,1),
(227,12,4,4,'STRAIGHTLE-NAV-L',919.00,5,1),
(228,12,5,4,'STRAIGHTLE-NAV-XL',919.00,8,1),
(229,12,2,7,'STRAIGHTLE-OLI-S',899.00,8,1),
(230,12,3,7,'STRAIGHTLE-OLI-M',899.00,8,1),
(231,12,4,7,'STRAIGHTLE-OLI-L',899.00,8,1),
(232,12,5,7,'STRAIGHTLE-OLI-XL',899.00,12,1),
(233,13,2,1,'CARGOPANTS-BLA-S',799.00,8,1),
(234,13,3,1,'CARGOPANTS-BLA-M',799.00,8,1),
(235,13,4,1,'CARGOPANTS-BLA-L',799.00,8,1),
(236,13,5,1,'CARGOPANTS-BLA-XL',799.00,12,1),
(237,13,2,2,'CARGOPANTS-WHI-S',799.00,8,1),
(238,13,3,2,'CARGOPANTS-WHI-M',799.00,8,1),
(239,13,4,2,'CARGOPANTS-WHI-L',799.00,8,1),
(240,13,5,2,'CARGOPANTS-WHI-XL',799.00,12,1),
(241,13,2,4,'CARGOPANTS-NAV-S',819.00,5,1),
(242,13,3,4,'CARGOPANTS-NAV-M',819.00,5,1),
(243,13,4,4,'CARGOPANTS-NAV-L',819.00,5,1),
(244,13,5,4,'CARGOPANTS-NAV-XL',819.00,8,1),
(245,13,2,7,'CARGOPANTS-OLI-S',799.00,8,1),
(246,13,3,7,'CARGOPANTS-OLI-M',799.00,8,1),
(247,13,4,7,'CARGOPANTS-OLI-L',799.00,8,1),
(248,13,5,7,'CARGOPANTS-OLI-XL',799.00,12,1),
(249,14,2,1,'CHINOPANTS-BLA-S',749.00,8,1),
(250,14,3,1,'CHINOPANTS-BLA-M',749.00,8,1),
(251,14,4,1,'CHINOPANTS-BLA-L',749.00,8,1),
(252,14,5,1,'CHINOPANTS-BLA-XL',749.00,12,1),
(253,14,2,2,'CHINOPANTS-WHI-S',749.00,8,1),
(254,14,3,2,'CHINOPANTS-WHI-M',749.00,8,1),
(255,14,4,2,'CHINOPANTS-WHI-L',749.00,8,1),
(256,14,5,2,'CHINOPANTS-WHI-XL',749.00,12,1),
(257,14,2,4,'CHINOPANTS-NAV-S',769.00,5,1),
(258,14,3,4,'CHINOPANTS-NAV-M',769.00,5,1),
(259,14,4,4,'CHINOPANTS-NAV-L',769.00,5,1),
(260,14,5,4,'CHINOPANTS-NAV-XL',769.00,8,1),
(261,14,2,7,'CHINOPANTS-OLI-S',749.00,8,1),
(262,14,3,7,'CHINOPANTS-OLI-M',749.00,8,1),
(263,14,4,7,'CHINOPANTS-OLI-L',749.00,8,1),
(264,14,5,7,'CHINOPANTS-OLI-XL',749.00,12,1),
(265,15,2,1,'JOGGERPANT-BLA-S',599.00,12,1),
(266,15,3,1,'JOGGERPANT-BLA-M',599.00,12,1),
(267,15,4,1,'JOGGERPANT-BLA-L',599.00,12,1),
(268,15,5,1,'JOGGERPANT-BLA-XL',599.00,16,1),
(269,15,2,2,'JOGGERPANT-WHI-S',599.00,12,1),
(270,15,3,2,'JOGGERPANT-WHI-M',599.00,12,1),
(271,15,4,2,'JOGGERPANT-WHI-L',599.00,12,1),
(272,15,5,2,'JOGGERPANT-WHI-XL',599.00,16,1),
(273,15,2,4,'JOGGERPANT-NAV-S',619.00,8,1),
(274,15,3,4,'JOGGERPANT-NAV-M',619.00,8,1),
(275,15,4,4,'JOGGERPANT-NAV-L',619.00,8,1),
(276,15,5,4,'JOGGERPANT-NAV-XL',619.00,12,1),
(277,15,2,7,'JOGGERPANT-OLI-S',599.00,12,1),
(278,15,3,7,'JOGGERPANT-OLI-M',599.00,12,1),
(279,15,4,7,'JOGGERPANT-OLI-L',599.00,12,1),
(280,15,5,7,'JOGGERPANT-OLI-XL',599.00,16,1),
(281,16,2,1,'DENIMSHORT-BLA-S',499.00,12,1),
(282,16,3,1,'DENIMSHORT-BLA-M',499.00,12,1),
(283,16,4,1,'DENIMSHORT-BLA-L',499.00,12,1),
(284,16,5,1,'DENIMSHORT-BLA-XL',499.00,16,1),
(285,16,2,2,'DENIMSHORT-WHI-S',499.00,12,1),
(286,16,3,2,'DENIMSHORT-WHI-M',499.00,12,1),
(287,16,4,2,'DENIMSHORT-WHI-L',499.00,12,1),
(288,16,5,2,'DENIMSHORT-WHI-XL',499.00,16,1),
(289,16,2,4,'DENIMSHORT-NAV-S',519.00,8,1),
(290,16,3,4,'DENIMSHORT-NAV-M',519.00,8,1),
(291,16,4,4,'DENIMSHORT-NAV-L',519.00,8,1),
(292,16,5,4,'DENIMSHORT-NAV-XL',519.00,12,1),
(293,16,2,7,'DENIMSHORT-OLI-S',499.00,12,1),
(294,16,3,7,'DENIMSHORT-OLI-M',499.00,12,1),
(295,16,4,7,'DENIMSHORT-OLI-L',499.00,12,1),
(296,16,5,7,'DENIMSHORT-OLI-XL',499.00,16,1),
(297,17,2,1,'BERMUDASHO-BLA-S',449.00,21,1),
(298,17,3,1,'BERMUDASHO-BLA-M',449.00,21,1),
(299,17,4,1,'BERMUDASHO-BLA-L',449.00,21,1),
(300,17,5,1,'BERMUDASHO-BLA-XL',449.00,0,1),
(301,17,2,2,'BERMUDASHO-WHI-S',449.00,21,1),
(302,17,3,2,'BERMUDASHO-WHI-M',449.00,21,1),
(303,17,4,2,'BERMUDASHO-WHI-L',449.00,21,1),
(304,17,5,2,'BERMUDASHO-WHI-XL',449.00,0,1),
(305,17,2,4,'BERMUDASHO-NAV-S',469.00,16,1),
(306,17,3,4,'BERMUDASHO-NAV-M',469.00,16,1),
(307,17,4,4,'BERMUDASHO-NAV-L',469.00,16,1),
(308,17,5,4,'BERMUDASHO-NAV-XL',469.00,21,1),
(309,17,2,7,'BERMUDASHO-OLI-S',449.00,21,1),
(310,17,3,7,'BERMUDASHO-OLI-M',449.00,21,1),
(311,17,4,7,'BERMUDASHO-OLI-L',449.00,21,1),
(312,17,5,7,'BERMUDASHO-OLI-XL',449.00,0,1),
(313,18,2,1,'DRESSPANTS-BLA-S',899.00,8,1),
(314,18,3,1,'DRESSPANTS-BLA-M',899.00,8,1),
(315,18,4,1,'DRESSPANTS-BLA-L',899.00,8,1),
(316,18,5,1,'DRESSPANTS-BLA-XL',899.00,12,1),
(317,18,2,2,'DRESSPANTS-WHI-S',899.00,8,1),
(318,18,3,2,'DRESSPANTS-WHI-M',899.00,8,1),
(319,18,4,2,'DRESSPANTS-WHI-L',899.00,8,1),
(320,18,5,2,'DRESSPANTS-WHI-XL',899.00,12,1),
(321,18,2,4,'DRESSPANTS-NAV-S',919.00,5,1),
(322,18,3,4,'DRESSPANTS-NAV-M',919.00,5,1),
(323,18,4,4,'DRESSPANTS-NAV-L',919.00,5,1),
(324,18,5,4,'DRESSPANTS-NAV-XL',919.00,8,1),
(325,18,2,7,'DRESSPANTS-OLI-S',899.00,8,1),
(326,18,3,7,'DRESSPANTS-OLI-M',899.00,8,1),
(327,18,4,7,'DRESSPANTS-OLI-L',899.00,8,1),
(328,18,5,7,'DRESSPANTS-OLI-XL',899.00,12,1),
(329,19,2,1,'SWEATPANTS-BLA-S',549.00,5,1),
(330,19,3,1,'SWEATPANTS-BLA-M',549.00,5,1),
(331,19,4,1,'SWEATPANTS-BLA-L',549.00,5,1),
(332,19,5,1,'SWEATPANTS-BLA-XL',549.00,8,1),
(333,19,2,2,'SWEATPANTS-WHI-S',549.00,5,1),
(334,19,3,2,'SWEATPANTS-WHI-M',549.00,5,1),
(335,19,4,2,'SWEATPANTS-WHI-L',549.00,5,1),
(336,19,5,2,'SWEATPANTS-WHI-XL',549.00,8,1),
(337,19,2,4,'SWEATPANTS-NAV-S',569.00,2,1),
(338,19,3,4,'SWEATPANTS-NAV-M',569.00,2,1),
(339,19,4,4,'SWEATPANTS-NAV-L',569.00,2,1),
(340,19,5,4,'SWEATPANTS-NAV-XL',569.00,5,1),
(341,19,2,7,'SWEATPANTS-OLI-S',549.00,5,1),
(342,19,3,7,'SWEATPANTS-OLI-M',549.00,5,1),
(343,19,4,7,'SWEATPANTS-OLI-L',549.00,5,1),
(344,19,5,7,'SWEATPANTS-OLI-XL',549.00,8,1),
(345,20,2,1,'LINENTROUS-BLA-S',799.00,21,1),
(346,20,3,1,'LINENTROUS-BLA-M',799.00,21,1),
(347,20,4,1,'LINENTROUS-BLA-L',799.00,21,1),
(348,20,5,1,'LINENTROUS-BLA-XL',799.00,0,1),
(349,20,2,2,'LINENTROUS-WHI-S',799.00,21,1),
(350,20,3,2,'LINENTROUS-WHI-M',799.00,21,1),
(351,20,4,2,'LINENTROUS-WHI-L',799.00,21,1),
(352,20,5,2,'LINENTROUS-WHI-XL',799.00,0,1),
(353,20,2,4,'LINENTROUS-NAV-S',819.00,16,1),
(354,20,3,4,'LINENTROUS-NAV-M',819.00,16,1),
(355,20,4,4,'LINENTROUS-NAV-L',819.00,16,1),
(356,20,5,4,'LINENTROUS-NAV-XL',819.00,21,1),
(357,20,2,7,'LINENTROUS-OLI-S',799.00,21,1),
(358,20,3,7,'LINENTROUS-OLI-M',799.00,21,1),
(359,20,4,7,'LINENTROUS-OLI-L',799.00,21,1),
(360,20,5,7,'LINENTROUS-OLI-XL',799.00,0,1),
(361,21,7,1,'BASEBALLCA-BLA-OS',299.00,12,1),
(362,21,7,5,'BASEBALLCA-BEI-OS',319.00,12,1),
(363,21,7,4,'BASEBALLCA-NAV-OS',319.00,8,1),
(364,22,7,1,'BUCKETHAT-BLA-OS',299.00,5,1),
(365,22,7,5,'BUCKETHAT-BEI-OS',319.00,5,1),
(366,22,7,4,'BUCKETHAT-NAV-OS',319.00,2,1),
(367,23,7,1,'BEANIE-BLA-OS',249.00,16,1),
(368,23,7,5,'BEANIE-BEI-OS',269.00,16,1),
(369,23,7,4,'BEANIE-NAV-OS',269.00,12,1),
(370,24,7,1,'FEDORAHAT-BLA-OS',499.00,5,1),
(371,24,7,5,'FEDORAHAT-BEI-OS',519.00,5,1),
(372,24,7,4,'FEDORAHAT-NAV-OS',519.00,1,1),
(373,25,7,1,'FLATCAP-BLA-OS',399.00,0,1),
(374,25,7,5,'FLATCAP-BEI-OS',419.00,0,1),
(375,25,7,4,'FLATCAP-NAV-OS',419.00,21,1),
(376,26,7,1,'SNAPBACKCA-BLA-OS',349.00,12,1),
(377,26,7,5,'SNAPBACKCA-BEI-OS',369.00,12,1),
(378,26,7,4,'SNAPBACKCA-NAV-OS',369.00,8,1),
(379,27,7,1,'TRUCKERHAT-BLA-OS',329.00,8,1),
(380,27,7,5,'TRUCKERHAT-BEI-OS',349.00,8,1),
(381,27,7,4,'TRUCKERHAT-NAV-OS',349.00,5,1),
(382,28,7,1,'BERET-BLA-OS',349.00,10,1),
(383,28,7,5,'BERET-BEI-OS',369.00,12,1),
(384,28,7,4,'BERET-NAV-OS',369.00,7,1),
(385,29,7,1,'PANAMAHAT-BLA-OS',599.00,5,1),
(386,29,7,5,'PANAMAHAT-BEI-OS',619.00,5,1),
(387,29,7,4,'PANAMAHAT-NAV-OS',619.00,2,1),
(388,30,7,1,'FISHERMANB-BLA-OS',279.00,2,1),
(389,30,7,5,'FISHERMANB-BEI-OS',299.00,2,1),
(390,30,7,4,'FISHERMANB-NAV-OS',299.00,0,1),
(391,31,1,1,'WBASICTSHI-BLA-XS',299.00,2,1),
(392,31,2,1,'WBASICTSHI-BLA-S',299.00,0,1),
(393,31,3,1,'WBASICTSHI-BLA-M',299.00,0,1),
(394,31,4,1,'WBASICTSHI-BLA-L',299.00,21,1),
(395,31,5,1,'WBASICTSHI-BLA-XL',299.00,2,1),
(396,31,1,2,'WBASICTSHI-WHI-XS',299.00,2,1),
(397,31,2,2,'WBASICTSHI-WHI-S',299.00,0,1),
(398,31,3,2,'WBASICTSHI-WHI-M',299.00,0,1),
(399,31,4,2,'WBASICTSHI-WHI-L',299.00,12,1),
(400,31,5,2,'WBASICTSHI-WHI-XL',299.00,2,1),
(401,31,1,4,'WBASICTSHI-NAV-XS',319.00,0,1),
(402,31,2,4,'WBASICTSHI-NAV-S',319.00,21,1),
(403,31,3,4,'WBASICTSHI-NAV-M',319.00,21,1),
(404,31,4,4,'WBASICTSHI-NAV-L',319.00,21,1),
(405,31,5,4,'WBASICTSHI-NAV-XL',319.00,0,1),
(406,31,1,7,'WBASICTSHI-OLI-XS',299.00,2,1),
(407,31,2,7,'WBASICTSHI-OLI-S',299.00,0,1),
(408,31,3,7,'WBASICTSHI-OLI-M',299.00,12,1),
(409,31,4,7,'WBASICTSHI-OLI-L',299.00,20,1),
(410,31,5,7,'WBASICTSHI-OLI-XL',299.00,2,1),
(411,32,1,1,'CROPTOP-BLA-XS',299.00,2,1),
(412,32,2,1,'CROPTOP-BLA-S',299.00,0,1),
(413,32,3,1,'CROPTOP-BLA-M',299.00,0,1),
(414,32,4,1,'CROPTOP-BLA-L',299.00,0,1),
(415,32,5,1,'CROPTOP-BLA-XL',299.00,2,1),
(416,32,1,2,'CROPTOP-WHI-XS',299.00,2,1),
(417,32,2,2,'CROPTOP-WHI-S',299.00,0,1),
(418,32,3,2,'CROPTOP-WHI-M',299.00,0,1),
(419,32,4,2,'CROPTOP-WHI-L',299.00,0,1),
(420,32,5,2,'CROPTOP-WHI-XL',299.00,2,1),
(421,32,1,4,'CROPTOP-NAV-XS',319.00,0,1),
(422,32,2,4,'CROPTOP-NAV-S',319.00,21,1),
(423,32,3,4,'CROPTOP-NAV-M',319.00,21,1),
(424,32,4,4,'CROPTOP-NAV-L',319.00,21,1),
(425,32,5,4,'CROPTOP-NAV-XL',319.00,0,1),
(426,32,1,7,'CROPTOP-OLI-XS',299.00,2,1),
(427,32,2,7,'CROPTOP-OLI-S',299.00,0,1),
(428,32,3,7,'CROPTOP-OLI-M',299.00,0,1),
(429,32,4,7,'CROPTOP-OLI-L',299.00,0,1),
(430,32,5,7,'CROPTOP-OLI-XL',299.00,2,1),
(431,33,1,1,'BLOUSE-BLA-XS',499.00,21,1),
(432,33,2,1,'BLOUSE-BLA-S',499.00,16,1),
(433,33,3,1,'BLOUSE-BLA-M',499.00,16,1),
(434,33,4,1,'BLOUSE-BLA-L',499.00,16,1),
(435,33,5,1,'BLOUSE-BLA-XL',499.00,21,1),
(436,33,1,2,'BLOUSE-WHI-XS',499.00,21,1),
(437,33,2,2,'BLOUSE-WHI-S',499.00,16,1),
(438,33,3,2,'BLOUSE-WHI-M',499.00,16,1),
(439,33,4,2,'BLOUSE-WHI-L',499.00,16,1),
(440,33,5,2,'BLOUSE-WHI-XL',499.00,21,1),
(441,33,1,4,'BLOUSE-NAV-XS',519.00,16,1),
(442,33,2,4,'BLOUSE-NAV-S',519.00,12,1),
(443,33,3,4,'BLOUSE-NAV-M',519.00,12,1),
(444,33,4,4,'BLOUSE-NAV-L',519.00,12,1),
(445,33,5,4,'BLOUSE-NAV-XL',519.00,16,1),
(446,33,1,7,'BLOUSE-OLI-XS',499.00,21,1),
(447,33,2,7,'BLOUSE-OLI-S',499.00,16,1),
(448,33,3,7,'BLOUSE-OLI-M',499.00,16,1),
(449,33,4,7,'BLOUSE-OLI-L',499.00,16,1),
(450,33,5,7,'BLOUSE-OLI-XL',499.00,21,1),
(451,34,1,1,'CAMISOLE-BLA-XS',249.00,2,1),
(452,34,2,1,'CAMISOLE-BLA-S',249.00,0,1),
(453,34,3,1,'CAMISOLE-BLA-M',249.00,0,1),
(454,34,4,1,'CAMISOLE-BLA-L',249.00,0,1),
(455,34,5,1,'CAMISOLE-BLA-XL',249.00,2,1),
(456,34,1,2,'CAMISOLE-WHI-XS',249.00,2,1),
(457,34,2,2,'CAMISOLE-WHI-S',249.00,0,1),
(458,34,3,2,'CAMISOLE-WHI-M',249.00,0,1),
(459,34,4,2,'CAMISOLE-WHI-L',249.00,0,1),
(460,34,5,2,'CAMISOLE-WHI-XL',249.00,2,1),
(461,34,1,4,'CAMISOLE-NAV-XS',269.00,0,1),
(462,34,2,4,'CAMISOLE-NAV-S',269.00,21,1),
(463,34,3,4,'CAMISOLE-NAV-M',269.00,21,1),
(464,34,4,4,'CAMISOLE-NAV-L',269.00,21,1),
(465,34,5,4,'CAMISOLE-NAV-XL',269.00,0,1),
(466,34,1,7,'CAMISOLE-OLI-XS',249.00,2,1),
(467,34,2,7,'CAMISOLE-OLI-S',249.00,0,1),
(468,34,3,7,'CAMISOLE-OLI-M',249.00,0,1),
(469,34,4,7,'CAMISOLE-OLI-L',249.00,0,1),
(470,34,5,7,'CAMISOLE-OLI-XL',249.00,2,1),
(471,35,1,1,'WTANKTOP-BLA-XS',249.00,8,1),
(472,35,2,1,'WTANKTOP-BLA-S',249.00,5,1),
(473,35,3,1,'WTANKTOP-BLA-M',249.00,5,1),
(474,35,4,1,'WTANKTOP-BLA-L',249.00,5,1),
(475,35,5,1,'WTANKTOP-BLA-XL',249.00,8,1),
(476,35,1,2,'WTANKTOP-WHI-XS',249.00,8,1),
(477,35,2,2,'WTANKTOP-WHI-S',249.00,5,1),
(478,35,3,2,'WTANKTOP-WHI-M',249.00,5,1),
(479,35,4,2,'WTANKTOP-WHI-L',249.00,5,1),
(480,35,5,2,'WTANKTOP-WHI-XL',249.00,8,1),
(481,35,1,4,'WTANKTOP-NAV-XS',269.00,5,1),
(482,35,2,4,'WTANKTOP-NAV-S',269.00,2,1),
(483,35,3,4,'WTANKTOP-NAV-M',269.00,2,1),
(484,35,4,4,'WTANKTOP-NAV-L',269.00,2,1),
(485,35,5,4,'WTANKTOP-NAV-XL',269.00,5,1),
(486,35,1,7,'WTANKTOP-OLI-XS',249.00,8,1),
(487,35,2,7,'WTANKTOP-OLI-S',249.00,5,1),
(488,35,3,7,'WTANKTOP-OLI-M',249.00,5,1),
(489,35,4,7,'WTANKTOP-OLI-L',249.00,5,1),
(490,35,5,7,'WTANKTOP-OLI-XL',249.00,8,1),
(491,36,1,1,'OFFSHOULDE-BLA-XS',399.00,5,1),
(492,36,2,1,'OFFSHOULDE-BLA-S',399.00,2,1),
(493,36,3,1,'OFFSHOULDE-BLA-M',399.00,2,1),
(494,36,4,1,'OFFSHOULDE-BLA-L',399.00,2,1),
(495,36,5,1,'OFFSHOULDE-BLA-XL',399.00,5,1),
(496,36,1,2,'OFFSHOULDE-WHI-XS',399.00,5,1),
(497,36,2,2,'OFFSHOULDE-WHI-S',399.00,2,1),
(498,36,3,2,'OFFSHOULDE-WHI-M',399.00,2,1),
(499,36,4,2,'OFFSHOULDE-WHI-L',399.00,2,1),
(500,36,5,2,'OFFSHOULDE-WHI-XL',399.00,5,1),
(501,36,1,4,'OFFSHOULDE-NAV-XS',419.00,2,1),
(502,36,2,4,'OFFSHOULDE-NAV-S',419.00,0,1),
(503,36,3,4,'OFFSHOULDE-NAV-M',419.00,0,1),
(504,36,4,4,'OFFSHOULDE-NAV-L',419.00,0,1),
(505,36,5,4,'OFFSHOULDE-NAV-XL',419.00,2,1),
(506,36,1,7,'OFFSHOULDE-OLI-XS',399.00,5,1),
(507,36,2,7,'OFFSHOULDE-OLI-S',399.00,2,1),
(508,36,3,7,'OFFSHOULDE-OLI-M',399.00,2,1),
(509,36,4,7,'OFFSHOULDE-OLI-L',399.00,2,1),
(510,36,5,7,'OFFSHOULDE-OLI-XL',399.00,5,1),
(511,37,1,1,'HALTERTOP-BLA-XS',349.00,8,1),
(512,37,2,1,'HALTERTOP-BLA-S',349.00,5,1),
(513,37,3,1,'HALTERTOP-BLA-M',349.00,5,1),
(514,37,4,1,'HALTERTOP-BLA-L',349.00,5,1),
(515,37,5,1,'HALTERTOP-BLA-XL',349.00,8,1),
(516,37,1,2,'HALTERTOP-WHI-XS',349.00,8,1),
(517,37,2,2,'HALTERTOP-WHI-S',349.00,5,1),
(518,37,3,2,'HALTERTOP-WHI-M',349.00,5,1),
(519,37,4,2,'HALTERTOP-WHI-L',349.00,5,1),
(520,37,5,2,'HALTERTOP-WHI-XL',349.00,8,1),
(521,37,1,4,'HALTERTOP-NAV-XS',369.00,5,1),
(522,37,2,4,'HALTERTOP-NAV-S',369.00,2,1),
(523,37,3,4,'HALTERTOP-NAV-M',369.00,2,1),
(524,37,4,4,'HALTERTOP-NAV-L',369.00,2,1),
(525,37,5,4,'HALTERTOP-NAV-XL',369.00,5,1),
(526,37,1,7,'HALTERTOP-OLI-XS',349.00,8,1),
(527,37,2,7,'HALTERTOP-OLI-S',349.00,5,1),
(528,37,3,7,'HALTERTOP-OLI-M',349.00,5,1),
(529,37,4,7,'HALTERTOP-OLI-L',349.00,5,1),
(530,37,5,7,'HALTERTOP-OLI-XL',349.00,8,1),
(531,38,1,1,'BODYSUIT-BLA-XS',449.00,2,1),
(532,38,2,1,'BODYSUIT-BLA-S',449.00,0,1),
(533,38,3,1,'BODYSUIT-BLA-M',449.00,0,1),
(534,38,4,1,'BODYSUIT-BLA-L',449.00,0,1),
(535,38,5,1,'BODYSUIT-BLA-XL',449.00,2,1),
(536,38,1,2,'BODYSUIT-WHI-XS',449.00,2,1),
(537,38,2,2,'BODYSUIT-WHI-S',449.00,0,1),
(538,38,3,2,'BODYSUIT-WHI-M',449.00,0,1),
(539,38,4,2,'BODYSUIT-WHI-L',449.00,0,1),
(540,38,5,2,'BODYSUIT-WHI-XL',449.00,2,1),
(541,38,1,4,'BODYSUIT-NAV-XS',469.00,0,1),
(542,38,2,4,'BODYSUIT-NAV-S',469.00,21,1),
(543,38,3,4,'BODYSUIT-NAV-M',469.00,21,1),
(544,38,4,4,'BODYSUIT-NAV-L',469.00,21,1),
(545,38,5,4,'BODYSUIT-NAV-XL',469.00,0,1),
(546,38,1,7,'BODYSUIT-OLI-XS',449.00,2,1),
(547,38,2,7,'BODYSUIT-OLI-S',449.00,0,1),
(548,38,3,7,'BODYSUIT-OLI-M',449.00,0,1),
(549,38,4,7,'BODYSUIT-OLI-L',449.00,0,1),
(550,38,5,7,'BODYSUIT-OLI-XL',449.00,2,1),
(551,39,1,1,'CARDIGAN-BLA-XS',699.00,2,1),
(552,39,2,1,'CARDIGAN-BLA-S',699.00,0,1),
(553,39,3,1,'CARDIGAN-BLA-M',699.00,0,1),
(554,39,4,1,'CARDIGAN-BLA-L',699.00,0,1),
(555,39,5,1,'CARDIGAN-BLA-XL',699.00,2,1),
(556,39,1,2,'CARDIGAN-WHI-XS',699.00,2,1),
(557,39,2,2,'CARDIGAN-WHI-S',699.00,0,1),
(558,39,3,2,'CARDIGAN-WHI-M',699.00,0,1),
(559,39,4,2,'CARDIGAN-WHI-L',699.00,0,1),
(560,39,5,2,'CARDIGAN-WHI-XL',699.00,2,1),
(561,39,1,4,'CARDIGAN-NAV-XS',719.00,0,1),
(562,39,2,4,'CARDIGAN-NAV-S',719.00,21,1),
(563,39,3,4,'CARDIGAN-NAV-M',719.00,21,1),
(564,39,4,4,'CARDIGAN-NAV-L',719.00,21,1),
(565,39,5,4,'CARDIGAN-NAV-XL',719.00,0,1),
(566,39,1,7,'CARDIGAN-OLI-XS',699.00,2,1),
(567,39,2,7,'CARDIGAN-OLI-S',699.00,0,1),
(568,39,3,7,'CARDIGAN-OLI-M',699.00,0,1),
(569,39,4,7,'CARDIGAN-OLI-L',699.00,0,1),
(570,39,5,7,'CARDIGAN-OLI-XL',699.00,2,1),
(571,40,1,1,'WKNITSWEAT-BLA-XS',749.00,0,1),
(572,40,2,1,'WKNITSWEAT-BLA-S',749.00,21,1),
(573,40,3,1,'WKNITSWEAT-BLA-M',749.00,21,1),
(574,40,4,1,'WKNITSWEAT-BLA-L',749.00,21,1),
(575,40,5,1,'WKNITSWEAT-BLA-XL',749.00,0,1),
(576,40,1,2,'WKNITSWEAT-WHI-XS',749.00,0,1),
(577,40,2,2,'WKNITSWEAT-WHI-S',749.00,21,1),
(578,40,3,2,'WKNITSWEAT-WHI-M',749.00,21,1),
(579,40,4,2,'WKNITSWEAT-WHI-L',749.00,21,1),
(580,40,5,2,'WKNITSWEAT-WHI-XL',749.00,0,1),
(581,40,1,4,'WKNITSWEAT-NAV-XS',769.00,21,1),
(582,40,2,4,'WKNITSWEAT-NAV-S',769.00,16,1),
(583,40,3,4,'WKNITSWEAT-NAV-M',769.00,16,1),
(584,40,4,4,'WKNITSWEAT-NAV-L',769.00,16,1),
(585,40,5,4,'WKNITSWEAT-NAV-XL',769.00,21,1),
(586,40,1,7,'WKNITSWEAT-OLI-XS',749.00,0,1),
(587,40,2,7,'WKNITSWEAT-OLI-S',749.00,21,1),
(588,40,3,7,'WKNITSWEAT-OLI-M',749.00,21,1),
(589,40,4,7,'WKNITSWEAT-OLI-L',749.00,21,1),
(590,40,5,7,'WKNITSWEAT-OLI-XL',749.00,0,1),
(591,41,2,1,'SKINNYJEAN-BLA-S',899.00,12,1),
(592,41,3,1,'SKINNYJEAN-BLA-M',899.00,11,1),
(593,41,4,1,'SKINNYJEAN-BLA-L',899.00,12,1),
(594,41,5,1,'SKINNYJEAN-BLA-XL',899.00,16,1),
(595,41,2,2,'SKINNYJEAN-WHI-S',899.00,12,1),
(596,41,3,2,'SKINNYJEAN-WHI-M',899.00,12,1),
(597,41,4,2,'SKINNYJEAN-WHI-L',899.00,12,1),
(598,41,5,2,'SKINNYJEAN-WHI-XL',899.00,16,1),
(599,41,2,4,'SKINNYJEAN-NAV-S',919.00,8,1),
(600,41,3,4,'SKINNYJEAN-NAV-M',919.00,8,1),
(601,41,4,4,'SKINNYJEAN-NAV-L',919.00,8,1),
(602,41,5,4,'SKINNYJEAN-NAV-XL',919.00,12,1),
(603,41,2,7,'SKINNYJEAN-OLI-S',899.00,12,1),
(604,41,3,7,'SKINNYJEAN-OLI-M',899.00,12,1),
(605,41,4,7,'SKINNYJEAN-OLI-L',899.00,12,1),
(606,41,5,7,'SKINNYJEAN-OLI-XL',899.00,16,1),
(607,42,2,1,'WIDELEGJEA-BLA-S',949.00,21,1),
(608,42,3,1,'WIDELEGJEA-BLA-M',949.00,21,1),
(609,42,4,1,'WIDELEGJEA-BLA-L',949.00,21,1),
(610,42,5,1,'WIDELEGJEA-BLA-XL',949.00,0,1),
(611,42,2,2,'WIDELEGJEA-WHI-S',949.00,21,1),
(612,42,3,2,'WIDELEGJEA-WHI-M',949.00,21,1),
(613,42,4,2,'WIDELEGJEA-WHI-L',949.00,21,1),
(614,42,5,2,'WIDELEGJEA-WHI-XL',949.00,0,1),
(615,42,2,4,'WIDELEGJEA-NAV-S',969.00,16,1),
(616,42,3,4,'WIDELEGJEA-NAV-M',969.00,16,1),
(617,42,4,4,'WIDELEGJEA-NAV-L',969.00,16,1),
(618,42,5,4,'WIDELEGJEA-NAV-XL',969.00,21,1),
(619,42,2,7,'WIDELEGJEA-OLI-S',949.00,21,1),
(620,42,3,7,'WIDELEGJEA-OLI-M',949.00,21,1),
(621,42,4,7,'WIDELEGJEA-OLI-L',949.00,21,1),
(622,42,5,7,'WIDELEGJEA-OLI-XL',949.00,0,1),
(623,43,2,1,'WCARGOPANT-BLA-S',799.00,16,1),
(624,43,3,1,'WCARGOPANT-BLA-M',799.00,16,1),
(625,43,4,1,'WCARGOPANT-BLA-L',799.00,16,1),
(626,43,5,1,'WCARGOPANT-BLA-XL',799.00,21,1),
(627,43,2,2,'WCARGOPANT-WHI-S',799.00,16,1),
(628,43,3,2,'WCARGOPANT-WHI-M',799.00,16,1),
(629,43,4,2,'WCARGOPANT-WHI-L',799.00,16,1),
(630,43,5,2,'WCARGOPANT-WHI-XL',799.00,21,1),
(631,43,2,4,'WCARGOPANT-NAV-S',819.00,12,1),
(632,43,3,4,'WCARGOPANT-NAV-M',819.00,12,1),
(633,43,4,4,'WCARGOPANT-NAV-L',819.00,12,1),
(634,43,5,4,'WCARGOPANT-NAV-XL',819.00,16,1),
(635,43,2,7,'WCARGOPANT-OLI-S',799.00,16,1),
(636,43,3,7,'WCARGOPANT-OLI-M',799.00,16,1),
(637,43,4,7,'WCARGOPANT-OLI-L',799.00,16,1),
(638,43,5,7,'WCARGOPANT-OLI-XL',799.00,21,1),
(639,44,2,1,'HIGHWAISTE-BLA-S',799.00,21,1),
(640,44,3,1,'HIGHWAISTE-BLA-M',799.00,21,1),
(641,44,4,1,'HIGHWAISTE-BLA-L',799.00,21,1),
(642,44,5,1,'HIGHWAISTE-BLA-XL',799.00,0,1),
(643,44,2,2,'HIGHWAISTE-WHI-S',799.00,21,1),
(644,44,3,2,'HIGHWAISTE-WHI-M',799.00,21,1),
(645,44,4,2,'HIGHWAISTE-WHI-L',799.00,21,1),
(646,44,5,2,'HIGHWAISTE-WHI-XL',799.00,0,1),
(647,44,2,4,'HIGHWAISTE-NAV-S',819.00,16,1),
(648,44,3,4,'HIGHWAISTE-NAV-M',819.00,16,1),
(649,44,4,4,'HIGHWAISTE-NAV-L',819.00,16,1),
(650,44,5,4,'HIGHWAISTE-NAV-XL',819.00,21,1),
(651,44,2,7,'HIGHWAISTE-OLI-S',799.00,21,1),
(652,44,3,7,'HIGHWAISTE-OLI-M',799.00,21,1),
(653,44,4,7,'HIGHWAISTE-OLI-L',799.00,21,1),
(654,44,5,7,'HIGHWAISTE-OLI-XL',799.00,0,1),
(655,45,2,1,'WDENIMSHOR-BLA-S',499.00,21,1),
(656,45,3,1,'WDENIMSHOR-BLA-M',499.00,21,1),
(657,45,4,1,'WDENIMSHOR-BLA-L',499.00,21,1),
(658,45,5,1,'WDENIMSHOR-BLA-XL',499.00,0,1),
(659,45,2,2,'WDENIMSHOR-WHI-S',499.00,21,1),
(660,45,3,2,'WDENIMSHOR-WHI-M',499.00,21,1),
(661,45,4,2,'WDENIMSHOR-WHI-L',499.00,21,1),
(662,45,5,2,'WDENIMSHOR-WHI-XL',499.00,0,1),
(663,45,2,4,'WDENIMSHOR-NAV-S',519.00,16,1),
(664,45,3,4,'WDENIMSHOR-NAV-M',519.00,16,1),
(665,45,4,4,'WDENIMSHOR-NAV-L',519.00,16,1),
(666,45,5,4,'WDENIMSHOR-NAV-XL',519.00,21,1),
(667,45,2,7,'WDENIMSHOR-OLI-S',499.00,21,1),
(668,45,3,7,'WDENIMSHOR-OLI-M',499.00,21,1),
(669,45,4,7,'WDENIMSHOR-OLI-L',499.00,21,1),
(670,45,5,7,'WDENIMSHOR-OLI-XL',499.00,0,1),
(671,46,2,1,'MINISKIRT-BLA-S',399.00,5,1),
(672,46,3,1,'MINISKIRT-BLA-M',399.00,5,1),
(673,46,4,1,'MINISKIRT-BLA-L',399.00,5,1),
(674,46,5,1,'MINISKIRT-BLA-XL',399.00,8,1),
(675,46,2,2,'MINISKIRT-WHI-S',399.00,5,1),
(676,46,3,2,'MINISKIRT-WHI-M',399.00,5,1),
(677,46,4,2,'MINISKIRT-WHI-L',399.00,5,1),
(678,46,5,2,'MINISKIRT-WHI-XL',399.00,8,1),
(679,46,2,4,'MINISKIRT-NAV-S',419.00,2,1),
(680,46,3,4,'MINISKIRT-NAV-M',419.00,2,1),
(681,46,4,4,'MINISKIRT-NAV-L',419.00,2,1),
(682,46,5,4,'MINISKIRT-NAV-XL',419.00,5,1),
(683,46,2,7,'MINISKIRT-OLI-S',399.00,5,1),
(684,46,3,7,'MINISKIRT-OLI-M',399.00,5,1),
(685,46,4,7,'MINISKIRT-OLI-L',399.00,5,1),
(686,46,5,7,'MINISKIRT-OLI-XL',399.00,8,1),
(687,47,2,1,'MIDISKIRT-BLA-S',499.00,5,1),
(688,47,3,1,'MIDISKIRT-BLA-M',499.00,5,1),
(689,47,4,1,'MIDISKIRT-BLA-L',499.00,5,1),
(690,47,5,1,'MIDISKIRT-BLA-XL',499.00,8,1),
(691,47,2,2,'MIDISKIRT-WHI-S',499.00,5,1),
(692,47,3,2,'MIDISKIRT-WHI-M',499.00,5,1),
(693,47,4,2,'MIDISKIRT-WHI-L',499.00,5,1),
(694,47,5,2,'MIDISKIRT-WHI-XL',499.00,8,1),
(695,47,2,4,'MIDISKIRT-NAV-S',519.00,2,1),
(696,47,3,4,'MIDISKIRT-NAV-M',519.00,2,1),
(697,47,4,4,'MIDISKIRT-NAV-L',519.00,2,1),
(698,47,5,4,'MIDISKIRT-NAV-XL',519.00,5,1),
(699,47,2,7,'MIDISKIRT-OLI-S',499.00,5,1),
(700,47,3,7,'MIDISKIRT-OLI-M',499.00,5,1),
(701,47,4,7,'MIDISKIRT-OLI-L',499.00,5,1),
(702,47,5,7,'MIDISKIRT-OLI-XL',499.00,8,1),
(703,48,2,1,'MAXISKIRT-BLA-S',599.00,5,1),
(704,48,3,1,'MAXISKIRT-BLA-M',599.00,5,1),
(705,48,4,1,'MAXISKIRT-BLA-L',599.00,5,1),
(706,48,5,1,'MAXISKIRT-BLA-XL',599.00,8,1),
(707,48,2,2,'MAXISKIRT-WHI-S',599.00,5,1),
(708,48,3,2,'MAXISKIRT-WHI-M',599.00,5,1),
(709,48,4,2,'MAXISKIRT-WHI-L',599.00,5,1),
(710,48,5,2,'MAXISKIRT-WHI-XL',599.00,8,1),
(711,48,2,4,'MAXISKIRT-NAV-S',619.00,2,1),
(712,48,3,4,'MAXISKIRT-NAV-M',619.00,2,1),
(713,48,4,4,'MAXISKIRT-NAV-L',619.00,2,1),
(714,48,5,4,'MAXISKIRT-NAV-XL',619.00,5,1),
(715,48,2,7,'MAXISKIRT-OLI-S',599.00,5,1),
(716,48,3,7,'MAXISKIRT-OLI-M',599.00,5,1),
(717,48,4,7,'MAXISKIRT-OLI-L',599.00,5,1),
(718,48,5,7,'MAXISKIRT-OLI-XL',599.00,8,1),
(719,49,2,1,'LEGGINGS-BLA-S',399.00,0,1),
(720,49,3,1,'LEGGINGS-BLA-M',399.00,0,1),
(721,49,4,1,'LEGGINGS-BLA-L',399.00,0,1),
(722,49,5,1,'LEGGINGS-BLA-XL',399.00,2,1),
(723,49,2,2,'LEGGINGS-WHI-S',399.00,0,1),
(724,49,3,2,'LEGGINGS-WHI-M',399.00,0,1),
(725,49,4,2,'LEGGINGS-WHI-L',399.00,0,1),
(726,49,5,2,'LEGGINGS-WHI-XL',399.00,2,1),
(727,49,2,4,'LEGGINGS-NAV-S',419.00,21,1),
(728,49,3,4,'LEGGINGS-NAV-M',419.00,21,1),
(729,49,4,4,'LEGGINGS-NAV-L',419.00,21,1),
(730,49,5,4,'LEGGINGS-NAV-XL',419.00,0,1),
(731,49,2,7,'LEGGINGS-OLI-S',399.00,0,1),
(732,49,3,7,'LEGGINGS-OLI-M',399.00,0,1),
(733,49,4,7,'LEGGINGS-OLI-L',399.00,0,1),
(734,49,5,7,'LEGGINGS-OLI-XL',399.00,2,1),
(735,50,2,1,'PALAZZOPAN-BLA-S',699.00,16,1),
(736,50,3,1,'PALAZZOPAN-BLA-M',699.00,16,1),
(737,50,4,1,'PALAZZOPAN-BLA-L',699.00,16,1),
(738,50,5,1,'PALAZZOPAN-BLA-XL',699.00,21,1),
(739,50,2,2,'PALAZZOPAN-WHI-S',699.00,16,1),
(740,50,3,2,'PALAZZOPAN-WHI-M',699.00,16,1),
(741,50,4,2,'PALAZZOPAN-WHI-L',699.00,16,1),
(742,50,5,2,'PALAZZOPAN-WHI-XL',699.00,21,1),
(743,50,2,4,'PALAZZOPAN-NAV-S',719.00,12,1),
(744,50,3,4,'PALAZZOPAN-NAV-M',719.00,12,1),
(745,50,4,4,'PALAZZOPAN-NAV-L',719.00,12,1),
(746,50,5,4,'PALAZZOPAN-NAV-XL',719.00,16,1),
(747,50,2,7,'PALAZZOPAN-OLI-S',699.00,16,1),
(748,50,3,7,'PALAZZOPAN-OLI-M',699.00,16,1),
(749,50,4,7,'PALAZZOPAN-OLI-L',699.00,16,1),
(750,50,5,7,'PALAZZOPAN-OLI-XL',699.00,21,1),
(751,51,7,1,'WBASEBALLC-BLA-OS',299.00,21,1),
(752,51,7,5,'WBASEBALLC-BEI-OS',319.00,21,1),
(753,51,7,4,'WBASEBALLC-NAV-OS',319.00,16,1),
(754,52,7,1,'WBUCKETHAT-BLA-OS',299.00,12,1),
(755,52,7,5,'WBUCKETHAT-BEI-OS',319.00,12,1),
(756,52,7,4,'WBUCKETHAT-NAV-OS',319.00,8,1),
(757,53,7,1,'WBEANIE-BLA-OS',249.00,0,1),
(758,53,7,5,'WBEANIE-BEI-OS',269.00,0,1),
(759,53,7,4,'WBEANIE-NAV-OS',269.00,21,1),
(760,54,7,1,'WBERET-BLA-OS',349.00,21,1),
(761,54,7,5,'WBERET-BEI-OS',369.00,21,1),
(762,54,7,4,'WBERET-NAV-OS',369.00,16,1),
(763,55,7,1,'WIDEBRIMSU-BLA-OS',499.00,5,1),
(764,55,7,5,'WIDEBRIMSU-BEI-OS',519.00,5,1),
(765,55,7,4,'WIDEBRIMSU-NAV-OS',519.00,2,1),
(766,56,7,1,'WFEDORAHAT-BLA-OS',499.00,12,1),
(767,56,7,5,'WFEDORAHAT-BEI-OS',519.00,12,1),
(768,56,7,4,'WFEDORAHAT-NAV-OS',519.00,8,1),
(769,57,7,1,'STRAWHAT-BLA-OS',449.00,2,1),
(770,57,7,5,'STRAWHAT-BEI-OS',469.00,2,1),
(771,57,7,4,'STRAWHAT-NAV-OS',469.00,0,1),
(772,58,7,1,'VISORCAP-BLA-OS',249.00,2,1),
(773,58,7,5,'VISORCAP-BEI-OS',269.00,2,1),
(774,58,7,4,'VISORCAP-NAV-OS',269.00,0,1),
(775,59,7,1,'CLOCHEHAT-BLA-OS',449.00,5,1),
(776,59,7,5,'CLOCHEHAT-BEI-OS',469.00,5,1),
(777,59,7,4,'CLOCHEHAT-NAV-OS',469.00,2,1),
(778,60,7,1,'NEWSBOYCAP-BLA-OS',399.00,6,1),
(779,60,7,5,'NEWSBOYCAP-BEI-OS',419.00,8,1),
(780,60,7,4,'NEWSBOYCAP-NAV-OS',419.00,5,1);
/*!40000 ALTER TABLE `product_variants` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `products`
--

DROP TABLE IF EXISTS `products`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `products` (
  `product_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `product_category_id` int(10) unsigned NOT NULL,
  `product_type_id` int(10) unsigned NOT NULL,
  `product_name` varchar(180) NOT NULL,
  `slug` varchar(200) NOT NULL,
  `description` text DEFAULT NULL,
  `base_price` decimal(10,2) NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`product_id`),
  UNIQUE KEY `slug` (`slug`),
  KEY `product_category_id` (`product_category_id`),
  KEY `product_type_id` (`product_type_id`),
  KEY `idx_products_active_category` (`is_active`,`product_category_id`),
  CONSTRAINT `products_ibfk_1` FOREIGN KEY (`product_category_id`) REFERENCES `product_categories` (`product_category_id`),
  CONSTRAINT `products_ibfk_2` FOREIGN KEY (`product_type_id`) REFERENCES `product_types` (`product_type_id`),
  CONSTRAINT `chk_products_price` CHECK (`base_price` >= 0)
) ENGINE=InnoDB AUTO_INCREMENT=61 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `products`
--

LOCK TABLES `products` WRITE;
/*!40000 ALTER TABLE `products` DISABLE KEYS */;
INSERT INTO `products` VALUES
(1,1,1,'Basic T-Shirt','basic-t-shirt','Everyday cotton T-shirt with a comfortable regular fit.',299.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(2,1,1,'Polo Shirt','polo-shirt','Classic polo shirt for casual and smart-casual outfits.',449.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(3,1,1,'Button-Down Shirt','button-down-shirt','Versatile button-down shirt suitable for work or weekends.',599.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(4,1,1,'Hoodie','hoodie','Soft casual hoodie for cool days and relaxed outfits.',799.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(5,1,1,'Sweatshirt','sweatshirt','Comfortable crewneck sweatshirt with a clean silhouette.',699.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(6,1,1,'Tank Top','tank-top','Lightweight sleeveless top for everyday wear.',249.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(7,1,1,'Henley Shirt','henley-shirt','Casual Henley shirt with a buttoned neckline.',399.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(8,1,1,'Flannel Shirt','flannel-shirt','Soft checked flannel shirt for layering.',649.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(9,1,1,'Long-Sleeve Shirt','long-sleeve-shirt','Long-sleeve basic designed for versatile everyday styling.',399.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(10,1,1,'Knit Sweater','knit-sweater','Textured knit sweater for a comfortable layered look.',799.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(11,1,2,'Slim-Fit Jeans','slim-fit-jeans','Slim-fit denim jeans with a modern everyday cut.',899.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(12,1,2,'Straight-Leg Jeans','straight-leg-jeans','Classic straight-leg denim jeans.',899.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(13,1,2,'Cargo Pants','cargo-pants','Utility-inspired cargo pants with practical pockets.',799.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(14,1,2,'Chino Pants','chino-pants','Smart-casual chino pants for work and weekends.',749.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(15,1,2,'Jogger Pants','jogger-pants','Relaxed jogger pants with an easy tapered fit.',599.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(16,1,2,'Denim Shorts','denim-shorts','Casual denim shorts for warm-weather outfits.',499.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(17,1,2,'Bermuda Shorts','bermuda-shorts','Versatile knee-length Bermuda shorts.',449.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(18,1,2,'Dress Pants','dress-pants','Tailored-look dress pants for formal occasions.',899.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(19,1,2,'Sweatpants','sweatpants','Soft sweatpants for lounging and casual wear.',549.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(20,1,2,'Linen Trousers','linen-trousers','Breathable linen-blend trousers for warm weather.',799.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(21,1,3,'Baseball Cap','baseball-cap','Adjustable baseball cap with a curved brim.',299.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(22,1,3,'Bucket Hat','bucket-hat','Casual bucket hat for everyday styling.',299.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(23,1,3,'Beanie','beanie','Soft knit beanie for a simple layered look.',249.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(24,1,3,'Fedora Hat','fedora-hat','Classic fedora-inspired hat for a statement outfit.',499.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(25,1,3,'Flat Cap','flat-cap','Traditional flat cap with a clean profile.',399.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(26,1,3,'Snapback Cap','snapback-cap','Structured snapback cap with an adjustable closure.',349.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(27,1,3,'Trucker Hat','trucker-hat','Casual trucker cap with a breathable back panel.',329.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(28,1,3,'Beret','beret','Minimal beret for a distinctive casual look.',349.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(29,1,3,'Panama Hat','panama-hat','Lightweight summer hat with a classic brim.',599.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(30,1,3,'Fisherman Beanie','fisherman-beanie','Short cuffed knit beanie with a fisherman style.',279.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(31,2,1,'Basic T-Shirt','w-basic-t-shirt','Everyday basic T-shirt with an easy, versatile fit.',299.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(32,2,1,'Crop Top','crop-top','Casual crop top for everyday outfits.',299.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(33,2,1,'Blouse','blouse','Versatile blouse suitable for casual or dressy styling.',499.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(34,2,1,'Camisole','camisole','Lightweight camisole for layering or warm days.',249.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(35,2,1,'Tank Top','w-tank-top','Simple sleeveless tank top for everyday wear.',249.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(36,2,1,'Off-Shoulder Top','off-shoulder-top','Off-shoulder top for a relaxed, dressy look.',399.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(37,2,1,'Halter Top','halter-top','Halter-neck top with a clean, modern style.',349.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(38,2,1,'Bodysuit','bodysuit','Streamlined bodysuit designed for easy outfit pairing.',449.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(39,2,1,'Cardigan','cardigan','Soft cardigan for comfortable layering.',699.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(40,2,1,'Knit Sweater','w-knit-sweater','Knit sweater with a versatile everyday silhouette.',749.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(41,2,2,'Skinny Jeans','skinny-jeans','Skinny-fit denim jeans with a classic finish.',899.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(42,2,2,'Wide-Leg Jeans','wide-leg-jeans','Wide-leg jeans with a relaxed contemporary fit.',949.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(43,2,2,'Cargo Pants','w-cargo-pants','Utility-inspired cargo pants with functional pockets.',799.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(44,2,2,'High-Waisted Trousers','high-waisted-trousers','High-waisted trousers for a polished everyday outfit.',799.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(45,2,2,'Denim Shorts','w-denim-shorts','Casual denim shorts for warm-weather styling.',499.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(46,2,2,'Mini Skirt','mini-skirt','Versatile mini skirt for casual outfits.',399.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(47,2,2,'Midi Skirt','midi-skirt','Midi skirt designed for easy day-to-day styling.',499.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(48,2,2,'Maxi Skirt','maxi-skirt','Flowing maxi skirt for relaxed, dressy outfits.',599.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(49,2,2,'Leggings','leggings','Stretch leggings for comfortable everyday wear.',399.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(50,2,2,'Palazzo Pants','palazzo-pants','Flowy palazzo pants with a relaxed wide-leg fit.',699.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(51,2,3,'Baseball Cap','w-baseball-cap','Adjustable baseball cap for casual everyday outfits.',299.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(52,2,3,'Bucket Hat','w-bucket-hat','Casual bucket hat with an easy, relaxed shape.',299.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(53,2,3,'Beanie','w-beanie','Soft knit beanie for a simple layered look.',249.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(54,2,3,'Beret','w-beret','Classic beret to complement casual or smart outfits.',349.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(55,2,3,'Wide-Brim Sun Hat','wide-brim-sun-hat','Wide-brim hat for sunny-day outfits.',499.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(56,2,3,'Fedora Hat','w-fedora-hat','Fedora-inspired hat with a versatile silhouette.',499.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(57,2,3,'Straw Hat','straw-hat','Lightweight straw-style hat for warm-weather wear.',449.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(58,2,3,'Visor Cap','visor-cap','Lightweight visor cap for outdoor activities.',249.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(59,2,3,'Cloche Hat','cloche-hat','Cloche-inspired hat with a timeless rounded shape.',449.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01'),
(60,2,3,'Newsboy Cap','newsboy-cap','Newsboy cap with a classic casual profile.',399.00,1,'2026-10-27 18:20:01','2026-10-27 18:20:01');
/*!40000 ALTER TABLE `products` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sales`
--

DROP TABLE IF EXISTS `sales`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sales` (
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
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sales`
--

LOCK TABLES `sales` WRITE;
/*!40000 ALTER TABLE `sales` DISABLE KEYS */;
INSERT INTO `sales` VALUES
(9,17,'TXN-17-20261028025557',827.00,'2026-10-27 18:55:57','Auto-recorded when order was marked completed'),
(11,32,'TXN-32-20261028030327',2793.00,'2026-10-27 19:03:27','Auto-recorded when order was marked completed'),
(12,25,'TXN-25-20261028030348',1077.00,'2026-10-27 19:03:48','Auto-recorded when order was marked completed'),
(13,23,'TXN-23-20261028030403',1377.00,'2026-10-27 19:04:03','Auto-recorded when order was marked completed'),
(14,33,'TXN-33-20261028031116',349.00,'2026-10-27 19:11:16','Auto-recorded when order was marked completed'),
(15,34,'TXN-34-20261028031123',899.00,'2026-10-27 19:11:23','Auto-recorded when order was marked completed'),
(16,35,'TXN-35-20261028151848',2147.00,'2026-10-28 07:18:48','Auto-recorded when order was marked completed'),
(17,36,'TXN-36-20261028154729',519.00,'2026-10-28 07:47:29','Auto-recorded when order was marked completed'),
(18,37,'TXN-37-20261028160205',1266.00,'2026-10-28 08:02:05','Auto-recorded when order was marked completed');
/*!40000 ALTER TABLE `sales` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sizes`
--

DROP TABLE IF EXISTS `sizes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sizes` (
  `size_id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `size_name` varchar(30) NOT NULL,
  PRIMARY KEY (`size_id`),
  UNIQUE KEY `size_name` (`size_name`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sizes`
--

LOCK TABLES `sizes` WRITE;
/*!40000 ALTER TABLE `sizes` DISABLE KEYS */;
INSERT INTO `sizes` VALUES
(4,'L'),
(3,'M'),
(7,'One Size'),
(2,'S'),
(5,'XL'),
(1,'XS'),
(6,'XXL');
/*!40000 ALTER TABLE `sizes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
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
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `email` (`email`),
  KEY `fk_users_status` (`status_id`),
  CONSTRAINT `fk_users_status` FOREIGN KEY (`status_id`) REFERENCES `account_statuses` (`status_id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES
(1,'Admin',1,'Admin','Account','admin@example.com','$2y$10$.swgQnJFoU16vz1MuG5R5uAFsDRhHdNiqSsm9JfgbZza8ZCOUklhm',NULL,NULL,'2026-10-27 18:15:18','2026-10-27 18:15:18'),
(9,'Customer',1,'Alex','Reyes','alex.reyes.demo@example.com','$2y$12$uBlixeb3S0LgJGB8jRQIa.HJymihGgicZ5bFI6OveOZD5SgqNyggi','09171230001',NULL,'2026-10-27 18:55:57','2026-10-27 18:55:57'),
(10,'Customer',1,'Mika','Santos','mika.santos.demo@example.com','$2y$12$uBlixeb3S0LgJGB8jRQIa.HJymihGgicZ5bFI6OveOZD5SgqNyggi','09171230002',NULL,'2026-10-27 18:55:57','2026-10-27 18:55:57'),
(11,'Customer',1,'Jordan','Cruz','jordan.cruz.demo@example.com','$2y$12$uBlixeb3S0LgJGB8jRQIa.HJymihGgicZ5bFI6OveOZD5SgqNyggi','09171230003',NULL,'2026-10-27 18:55:57','2026-10-27 18:55:57'),
(12,'Customer',1,'Sam','Garcia','sam.garcia.demo@example.com','$2y$12$uBlixeb3S0LgJGB8jRQIa.HJymihGgicZ5bFI6OveOZD5SgqNyggi','09171230004',NULL,'2026-10-27 18:55:57','2026-10-27 18:55:57'),
(13,'Customer',1,'Taylor','Dela Cruz','taylor.delacruz.demo@example.com','$2y$12$uBlixeb3S0LgJGB8jRQIa.HJymihGgicZ5bFI6OveOZD5SgqNyggi','09171230005',NULL,'2026-10-27 18:55:57','2026-10-27 18:55:57'),
(14,'Customer',1,'Casey','Mendoza','casey.mendoza.demo@example.com','$2y$12$uBlixeb3S0LgJGB8jRQIa.HJymihGgicZ5bFI6OveOZD5SgqNyggi','09171230006',NULL,'2026-10-27 18:55:57','2026-10-27 18:55:57'),
(16,'Customer',1,'Justine','Sabalza','justinesabalza0101@gmail.com','$2y$12$itKxwua2/ffxihYlg7zWh.JVdvzxm7UjfKuckurCskjJCddCLNpqe','09090909090',NULL,'2026-10-27 19:01:57','2026-10-27 19:01:57');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping events for database 'clothing_store_fixed'
--

--
-- Dumping routines for database 'clothing_store_fixed'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-29  2:21:26
