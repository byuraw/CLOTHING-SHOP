<?php
require_once __DIR__ . '/../includes/functions.php';
require_admin();
$stats = [
    'orders' => (int) $pdo->query('SELECT COUNT(*) FROM orders')->fetchColumn(),
    'sales' => (float) $pdo
        ->query(
            "SELECT COALESCE(SUM(total_amount),0) FROM orders o JOIN order_statuses s ON s.order_status_id=o.order_status_id WHERE s.status_name IN ('Processing','Packed','Shipped','Delivered','Completed')",
        )
        ->fetchColumn(),
    'products' => (int) $pdo
        ->query('SELECT COUNT(*) FROM products WHERE is_active=1')
        ->fetchColumn(),
    'customers' => (int) $pdo
        ->query(
            "SELECT COUNT(*) FROM users u JOIN roles r ON r.role_id=u.role_id WHERE r.role_name='Customer'",
        )
        ->fetchColumn(),
];
$pageTitle = 'Admin dashboard';
require __DIR__ . '/../includes/header.php';
?>

<div class="section-head"><h1 class="page-title">Store dashboard</h1></div>
<div class="grid">
  <?php foreach (
    $stats
    as $k => $val
): ?>

  <div class="stat">
    <div class="muted"><?= e(ucfirst($k)) ?></div>
    <strong><?= $k === 'sales'
    ? '₱' . number_format($val, 2)
    : number_format(
        $val,
    ) ?></strong>
  </div>
  <?php endforeach; ?>

</div>
<h2>Management</h2>
<div class="admin-links"><?php foreach (
    [
        'catalog.php' => 'Categories and types',
        'products.php' => 'Products and variants',
        'inventory.php' => 'Inventory',
        'orders.php' => 'Orders',
        'users.php' => 'Customers and users',
        'expenses.php' => 'Expenses',
        'reports.php' => 'Reports',
    ]
    as $link => $label
): ?><a href="/clothing-store-backup/admin/<?= e($link) ?>"><?= e(
    $label,
) ?></a><?php endforeach; ?></div>
<?php require __DIR__ . '/../includes/footer.php'; ?>
