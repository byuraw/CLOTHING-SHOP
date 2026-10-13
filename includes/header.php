<?php
require_once __DIR__ . '/functions.php';
$pageTitle = $pageTitle ?? 'Wearwell Clothing';
$notice = $_SESSION['flash'] ?? null; unset($_SESSION['flash']);
?>
<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title><?= e($pageTitle) ?> | Wearwell</title><link rel="stylesheet" href="/clothing-store-backup/assets/css/style.css"></head><body>
<header class="site-header"><a class="brand" href="/clothing-store-backup/index.php">WEARWELL<span> CLOTHING</span></a>
<nav><a href="/clothing-store-backup/shop.php">Shop</a><a href="/clothing-store-backup/cart.php">Cart (<?= cart_count($pdo) ?>)</a>
<?php if (current_user()): ?><a href="/clothing-store-backup/orders.php">My orders</a><a href="/clothing-store-backup/user/profile.php"><?= e(current_user()['name']) ?></a>
<?php if ((current_user()['role'] ?? '') === 'Admin'): ?><a href="/clothing-store-backup/admin/index.php">Admin</a><?php endif; ?><a href="/clothing-store-backup/user/logout.php">Sign out</a>
<?php else: ?><a href="/clothing-store-backup/user/login.php">Sign in</a><?php endif; ?></nav></header>
<main class="container">
<?php if ($notice): ?><div class="notice <?= e($notice[1]) ?>"><?= e($notice[0]) ?></div><?php endif; ?>
