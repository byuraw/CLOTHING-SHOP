<?php
declare(strict_types=1);

/* PDO connection for clothing_store_backup. Optional overrides:
   CLOTHING_DB_HOST, CLOTHING_DB_NAME, CLOTHING_DB_USER, CLOTHING_DB_PASS. */
$host = getenv('CLOTHING_DB_HOST') ?: '127.0.0.1';
$dbname = getenv('CLOTHING_DB_NAME') ?: 'clothing_store_fixed';
$username = getenv('CLOTHING_DB_USER') ?: 'root';
$password = getenv('CLOTHING_DB_PASS') !== false ? getenv('CLOTHING_DB_PASS') : '';
$dsn = "mysql:host={$host};dbname={$dbname};charset=utf8mb4";

try {
    $pdo = new PDO($dsn, $username, $password, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
} catch (PDOException $exception) {
    error_log('Clothing store database connection failed: ' . $exception->getMessage());
    http_response_code(500);
    exit('Database connection failed. Check the database settings and make sure MySQL is running.');
}