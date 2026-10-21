<?php
require_once __DIR__ . "/functions.php";

$pageTitle = $pageTitle ?? "Wearwell Clothing";
$notice = $_SESSION["flash"] ?? null;
unset($_SESSION["flash"]);
$fullWidth = $fullWidth ?? false; // home page sets this to draw the hero edge to edge
$bodyClass = $bodyClass ?? "";
$isAdmin = (current_user()["role"] ?? "") === "Admin";
$currentAdminPage = basename($_SERVER["SCRIPT_NAME"] ?? "");
$isAdminPage =
    $isAdmin &&
    strpos($_SERVER["SCRIPT_NAME"] ?? "", "/admin/") !== false &&
    $currentAdminPage !== "index.php";
?>
<!doctype html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title><?= e($pageTitle) ?> | Wearwell</title>
        <link rel="preconnect" href="https://fonts.googleapis.com">
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
        <link
            href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600&family=Playfair+Display:wght@700&display=swap"
            rel="stylesheet"
        >
        <link rel="stylesheet" href="/clothing-store-backup/assets/css/style.css">
    </head>
    <body class="<?= e(
        trim($bodyClass . ($isAdminPage ? " admin-body" : "")),
    ) ?>">
        <?php if ($isAdminPage): ?>
            <div class="admin-shell">
                <aside class="admin-sidebar">
                    <a class="admin-brand" href="/clothing-store-backup/admin/index.php">
                        <svg viewBox="0 0 24 24" aria-hidden="true">
                            <path d="m3 7 9-4 9 4-9 4-9-4zM3 12l9 4 9-4M3 17l9 4 9-4"/>
                        </svg>
                        <span>Wearwell Admin</span>
                    </a>
                    <nav class="admin-nav" aria-label="Admin navigation">
                        <?php
                        $adminNav = [
                            [
                                "index.php",
                                "Dashboard",
                                "M3 3h7v7H3zM14 3h7v7h-7zM14 14h7v7h-7zM3 14h7v7H3z",
                            ],
                            [
                                "catalog.php",
                                "Catalog",
                                "M4 4h16v16H4zM8 8h8M8 12h8M8 16h5",
                            ],
                            [
                                "products.php",
                                "Products",
                                "M4 7h16l-1 13H5L4 7zM9 7a3 3 0 0 1 6 0",
                            ],
                            [
                                "inventory.php",
                                "Inventory",
                                "M3 7h18v13H3zM3 7l2-4h14l2 4M8 11h8",
                            ],
                            [
                                "orders.php",
                                "Orders",
                                "M5 4h14v17H5zM8 8h8M8 12h8M8 16h5",
                            ],
                            [
                                "users.php",
                                "Customers",
                                "M16 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2M10 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8M20 8v6M17 11h6",
                            ],
                            [
                                "expenses.php",
                                "Expenses",
                                "M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6",
                            ],
                            [
                                "reports.php",
                                "Reports",
                                "M4 19V5M4 19h17M8 15l4-4 3 2 5-6",
                            ],
                        ];
                        foreach ($adminNav as [$file, $label, $icon]):
                            $active = $currentAdminPage === $file; ?>
                            <a
                                class="admin-nav-link<?= $active
                                    ? " active"
                                    : "" ?>"
                                href="/clothing-store-backup/admin/<?= e(
                                    $file,
                                ) ?>"
                                <?= $active ? 'aria-current="page"' : "" ?>
                            >
                                <svg viewBox="0 0 24 24" aria-hidden="true">
                                    <path d="<?= e($icon) ?>"/>
                                </svg>
                                <span><?= e($label) ?></span>
                            </a>
                        <?php
                        endforeach;
                        ?>
                    </nav>
                    <div class="admin-sidebar-bottom">
                        <a class="admin-store-link" href="/clothing-store-backup/index.php">
                            <svg viewBox="0 0 24 24" aria-hidden="true">
                                <path d="M3 10h18l-2-6H5l-2 6ZM5 10v10h14V10M9 20v-6h6v6"/>
                            </svg>
                            View storefront
                        </a>
                        <a class="admin-signout" href="/clothing-store-backup/user/logout.php">
                            Sign out
                        </a>
                    </div>
                </aside>
                <div class="admin-workspace">
                    <header class="admin-topbar">
                        <?php if ($currentAdminPage === "index.php"): ?>
                            <h1><?= e($pageTitle) ?></h1>
                        <?php endif; ?>
                        <form
                            class="admin-search"
                            method="get"
                            action="/clothing-store-backup/admin/index.php"
                        >
                            <svg viewBox="0 0 24 24" aria-hidden="true">
                                <circle cx="11" cy="11" r="7"/>
                                <path d="m21 21-4.3-4.3"/>
                            </svg>
                            <input
                                type="search"
                                name="q"
                                value="<?= e($_GET["q"] ?? "") ?>"
                                placeholder="Search orders by ID or customer…"
                                aria-label="Search orders by number or customer"
                            >
                        </form>
                        <div class="admin-account">
                            <a
                                class="admin-top-action"
                                href="/clothing-store-backup/admin/orders.php"
                                aria-label="Orders"
                            >
                                <svg viewBox="0 0 24 24" aria-hidden="true">
                                    <path d="M4 5h2l2.2 10.2a2 2 0 0 0 2 1.6h7.6a2 2 0 0 0 2-1.6L21 8H7M10 21h.01M18 21h.01"/>
                                </svg>
                            </a>
                            <a
                                class="admin-top-action"
                                href="/clothing-store-backup/admin/users.php"
                                aria-label="Customers"
                            >
                                <svg viewBox="0 0 24 24" aria-hidden="true">
                                    <path d="M21 11.5a8.4 8.4 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.4 8.4 0 0 1-3.8-.9L3 21l1.9-5.7a8.4 8.4 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.4 8.4 0 0 1 3.8-.9h.5a8.5 8.5 0 0 1 8 8v.5z"/>
                                </svg>
                            </a>
                            <span class="admin-avatar" aria-hidden="true">
                                <?= e(
                                    strtoupper(
                                        substr(
                                            current_user()["name"] ?? "A",
                                            0,
                                            1,
                                        ),
                                    ),
                                ) ?>
                            </span>
                        </div>
                    </header>
                    <main class="admin-main">
        <?php else: ?>
            <header class="site-header">
                <nav aria-label="Main">
                    <a href="/clothing-store-backup/index.php">Home</a>
                    <a href="/clothing-store-backup/shop.php">Shop</a>
                    <?php if (current_user()): ?>
                        <a href="/clothing-store-backup/orders.php">My orders</a>
                    <?php endif; ?>
                    <?php if ($isAdmin): ?>
                        <a href="/clothing-store-backup/admin/index.php">Admin</a>
                    <?php endif; ?>
                </nav>
                <a class="brand" href="/clothing-store-backup/index.php">
                    Wearwell<span> Clothing</span>
                </a>
                <div class="header-tools">
                    <?php if (current_user()): ?>
                        <a
                            class="user-name"
                            href="/clothing-store-backup/user/profile.php"
                        >
                            <?= e(current_user()["name"]) ?>
                        </a>
                        <a href="/clothing-store-backup/user/logout.php">Sign out</a>
                    <?php else: ?>
                        <a href="/clothing-store-backup/user/login.php">Sign in</a>
                    <?php endif; ?>
                    <button
                        type="button"
                        class="icon-btn"
                        data-search-toggle
                        aria-label="Search products"
                    >
                        <svg viewBox="0 0 24 24">
                            <circle cx="11" cy="11" r="7"/>
                            <path d="m20 20-3.5-3.5"/>
                        </svg>
                    </button>
                    <a
                        class="icon-btn"
                        href="/clothing-store-backup/user/profile.php"
                        aria-label="Account"
                    >
                        <svg viewBox="0 0 24 24">
                            <circle cx="12" cy="8" r="4"/>
                            <path d="M4 21c0-4.4 3.6-7 8-7s8 2.6 8 7"/>
                        </svg>
                    </a>
                    <a
                        class="icon-btn"
                        href="/clothing-store-backup/cart.php"
                        aria-label="Cart, <?= cart_count($pdo) ?> items"
                    >
                        <svg viewBox="0 0 24 24">
                            <path d="M5 8h14l-1 12H6L5 8Z"/>
                            <path d="M9 8a3 3 0 0 1 6 0"/>
                        </svg>
                        <span class="cart-count"><?= cart_count($pdo) ?></span>
                    </a>
                </div>
            </header>
            <div class="search-bar" id="search-bar">
                <form method="get" action="/clothing-store-backup/index.php">
                    <input
                        name="q"
                        value="<?= e($_GET["q"] ?? "") ?>"
                        placeholder="Search clothing"
                        aria-label="Search clothing"
                    >
                    <button>Search</button>
                </form>
            </div>
            <main class="<?= $fullWidth ? "main-full" : "container" ?>">
        <?php endif; ?>
        <?php if ($notice && !$fullWidth): ?>
            <div class="notice <?= e($notice[1]) ?>"><?= e($notice[0]) ?></div>
        <?php endif; ?>
