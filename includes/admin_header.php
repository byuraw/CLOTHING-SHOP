<?php
require_once __DIR__ . "/functions.php";

$pageTitle = $pageTitle ?? "Dashboard";
$notice = $_SESSION["flash"] ?? null;
unset($_SESSION["flash"]);
$here = basename($_SERVER["SCRIPT_NAME"] ?? "index.php");
$searchPlaceholder =
    $here === "orders.php"
        ? "Search orders…"
        : ($here === "users.php"
            ? "Search customers…"
            : "Search this page…");
$initial = strtoupper(substr(current_user()["name"] ?? "A", 0, 1));

$icons = [
    "dashboard" =>
        '<rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/>',
    "catalog" =>
        '<path d="M4 7l8-4 8 4-8 4-8-4z"/><path d="M4 7v10l8 4 8-4V7"/>',
    "products" =>
        '<path d="M6 2l1 5h10l1-5"/><path d="M4 7h16l-1.5 13a2 2 0 0 1-2 2H7.5a2 2 0 0 1-2-2L4 7z"/>',
    "orders" =>
        '<circle cx="9" cy="20" r="1.4"/><circle cx="18" cy="20" r="1.4"/><path d="M2 3h2l2.6 13.2a2 2 0 0 0 2 1.6h8.8a2 2 0 0 0 2-1.6L21 7H6"/>',
    "users" =>
        '<circle cx="12" cy="8" r="3.4"/><path d="M4.5 20a7.5 7.5 0 0 1 15 0"/>',
    "expenses" => '<path d="M3 20h18"/><path d="M6 20V10M12 20V4M18 20V14"/>',
    "reports" =>
        '<path d="M4 19V5"/><path d="M4 19h16"/><path d="M8 19v-6M13 19v-9M18 19v-4"/>',
    "store" => '<path d="M3 10l9-7 9 7v10a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1z"/>',
    "out" =>
        '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="M16 17l5-5-5-5M21 12H9"/>',
];

$links = [
    "index.php" => ["Dashboard", "dashboard"],
    "catalog.php" => ["Catalog", "catalog"],
    "products.php" => ["Products", "products"],
    "orders.php" => ["Orders", "orders"],
    "users.php" => ["Customers", "users"],
    "expenses.php" => ["Expenses", "expenses"],
    "reports.php" => ["Reports", "reports"],
];
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= e($pageTitle) ?> | Wearwell Admin</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link
        href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700&display=swap"
        rel="stylesheet"
    >
    <link
        rel="stylesheet"
        href="<?= APP_BASE ?>/assets/css/admin.css?v=<?= filemtime(
            __DIR__ . "/../assets/css/admin.css",
        ) ?>"
    >
</head>
<body>
<div class="wrap">
    <aside class="side">
        <div class="brand">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
                <path d="M3 7l9-4 9 4-9 4-9-4z"/>
                <path d="M3 12l9 4 9-4"/>
                <path d="M3 17l9 4 9-4"/>
            </svg>
            Wearwell Admin
        </div>
        <nav aria-label="Primary">
            <?php foreach ($links as $file => [$label, $icon]): ?>
                <a
                    href="<?= APP_BASE ?>/admin/<?= e($file) ?>"
                    <?= $here === $file
                        ? 'class="active" aria-current="page"'
                        : "" ?>
                >
                    <svg viewBox="0 0 24 24" aria-hidden="true"><?= $icons[
                        $icon
                    ] ?></svg>
                    <?= e($label) ?>
                </a>
            <?php endforeach; ?>
        </nav>
        <div class="spacer"></div>
        <nav aria-label="Account">
            <a href="<?= APP_BASE ?>/index.php">
                <svg viewBox="0 0 24 24" aria-hidden="true"><?= $icons[
                    "store"
                ] ?></svg>
                View store
            </a>
            <a href="<?= APP_BASE ?>/user/logout.php">
                <svg viewBox="0 0 24 24" aria-hidden="true"><?= $icons[
                    "out"
                ] ?></svg>
                Sign out
            </a>
        </nav>
    </aside>
    <div class="main">
        <header class="topbar">
            <h1><?= e($pageTitle) ?></h1>
            <?php if ($here !== "products.php"): ?>
                <div class="search">
                    <svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/></svg>
                    <label for="q" class="sr-only">Search this page</label>
                    <input
                        id="q"
                        type="search"
                        placeholder="<?= e($searchPlaceholder) ?>"
                        data-table-filter
                    >
                </div>
            <?php endif; ?>
            <div class="top-actions">
                <button type="button" class="icon-btn" aria-label="Notifications">
                    <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M18 8a6 6 0 1 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.7 21a2 2 0 0 1-3.4 0"/></svg>
                </button>
                <button type="button" class="icon-btn" aria-label="Messages">
                    <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
                </button>
                <div class="avatar" title="<?= e(
                    current_user()["name"] ?? "",
                ) ?>"><?= e($initial) ?></div>
            </div>
        </header>
        <div class="content">
            <div class="crumb">
                <a href="<?= APP_BASE ?>/index.php">Home</a> /
                <?php if ($here === "index.php"): ?>
                    Dashboard
                <?php else: ?>
                    <a href="<?= APP_BASE ?>/admin/index.php">Dashboard</a> / <?= e(
    $pageTitle,
) ?>
                <?php endif; ?>
            </div>
            <?php if ($notice): ?>
                <div class="notice <?= e($notice[1]) ?>"><?= e(
    $notice[0],
) ?></div>
            <?php endif; ?>
