<?php
require_once __DIR__ . '/functions.php';
$pageTitle = $pageTitle ?? 'Wearwell Clothing';
$notice = $_SESSION['flash'] ?? null; unset($_SESSION['flash']);
$fullWidth = $fullWidth ?? false;      // home page sets this to draw the hero edge to edge
$bodyClass = $bodyClass ?? '';
$isAdmin = (current_user()['role'] ?? '') === 'Admin';
?>
<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title><?= e($pageTitle) ?> | Wearwell</title>
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600&family=Playfair+Display:wght@700&display=swap" rel="stylesheet">
<link rel="stylesheet" href="/clothing-store-backup/assets/css/style.css"></head><body class="<?= e($bodyClass) ?>">
<header class="site-header">
<nav aria-label="Main"><a href="/clothing-store-backup/index.php">Home</a><a href="/clothing-store-backup/shop.php">Shop</a>
<?php if (current_user()): ?><a href="/clothing-store-backup/orders.php">My orders</a><?php endif; ?>
<?php if ($isAdmin): ?><a href="/clothing-store-backup/admin/index.php">Admin</a><?php endif; ?></nav>
<a class="brand" href="/clothing-store-backup/index.php">Wearwell<span> Clothing</span></a>
<div class="header-tools">
<?php if (current_user()): ?>
<a class="user-name" href="/clothing-store-backup/user/profile.php"><?= e(current_user()['name']) ?></a>
<a href="/clothing-store-backup/user/logout.php">Sign out</a>
<?php else: ?><a href="/clothing-store-backup/user/login.php">Sign in</a><?php endif; ?>
<button type="button" class="icon-btn" data-search-toggle aria-label="Search products"><svg viewBox="0 0 24 24"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg></button>
<a class="icon-btn" href="/clothing-store-backup/user/profile.php" aria-label="Account"><svg viewBox="0 0 24 24"><circle cx="12" cy="8" r="4"/><path d="M4 21c0-4.4 3.6-7 8-7s8 2.6 8 7"/></svg></a>
<a class="icon-btn" href="/clothing-store-backup/cart.php" aria-label="Cart, <?= cart_count($pdo) ?> items"><svg viewBox="0 0 24 24"><path d="M5 8h14l-1 12H6L5 8Z"/><path d="M9 8a3 3 0 0 1 6 0"/></svg><span class="cart-count"><?= cart_count($pdo) ?></span></a>
</div></header>
<div class="search-bar" id="search-bar"><form method="get" action="/clothing-store-backup/index.php"><input name="q" value="<?= e($_GET['q'] ?? '') ?>" placeholder="Search clothing" aria-label="Search clothing"><button>Search</button></form></div>
<main class="<?= $fullWidth ? 'main-full' : 'container' ?>">
<?php if ($notice && !$fullWidth): ?><div class="notice <?= e($notice[1]) ?>"><?= e($notice[0]) ?></div><?php endif; ?>
