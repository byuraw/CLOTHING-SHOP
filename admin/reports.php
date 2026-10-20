<?php
require_once __DIR__ . '/../includes/functions.php';
require_admin();
$from = $_GET['from'] ?? date('Y-m-01');
$to = $_GET['to'] ?? date('Y-m-d');
$args = [$from . ' 00:00:00', $to . ' 23:59:59'];
$q = $pdo->prepare(
    "SELECT COUNT(*) orders_count,COALESCE(SUM(o.total_amount),0) sales FROM orders o JOIN order_statuses s ON s.order_status_id=o.order_status_id WHERE o.placed_at BETWEEN ? AND ? AND s.status_name NOT IN ('Cancelled')",
);
$q->execute($args);
$summary = $q->fetch();
$q = $pdo->prepare(
    'SELECT COALESCE(SUM(amount),0) FROM expenses WHERE expense_date BETWEEN ? AND ?',
);
$q->execute([$from, $to]);
$expenses = (float) $q->fetchColumn();
$q = $pdo->prepare(
    "SELECT oi.product_name_snapshot,SUM(oi.quantity) units FROM order_items oi JOIN orders o ON o.order_id=oi.order_id JOIN order_statuses s ON s.order_status_id=o.order_status_id WHERE o.placed_at BETWEEN ? AND ? AND s.status_name<>'Cancelled' GROUP BY oi.product_name_snapshot ORDER BY units DESC LIMIT 10",
);
$q->execute($args);
$best = $q->fetchAll();
$q = $pdo->prepare(
    'SELECT p.product_name,v.sku,v.stock_quantity FROM product_variants v JOIN products p ON p.product_id=v.product_id WHERE v.stock_quantity<=5 ORDER BY v.stock_quantity,p.product_name',
);
$q->execute();
$low = $q->fetchAll();
$pageTitle = 'Reports';
require __DIR__ . '/../includes/admin_header.php';
?>

<h1 class="page-title">Reports</h1>
<form class="row" method="get">
  <label>From<input type="date" name="from" value="<?= e(
    $from,
) ?>" /></label><label>To<input type="date" name="to" value="<?= e(
    $to,
) ?>" /></label><button>Apply</button>
</form>
<div class="grid">
  <div class="stat">Orders<strong><?= (int) $summary[
    'orders_count'
] ?></strong></div>
  <div class="stat">Sales<strong>₱<?= number_format(
    (float) $summary['sales'],
    2,
) ?></strong></div>
  <div class="stat">Expenses<strong>₱<?= number_format(
    $expenses,
    2,
) ?></strong></div>
  <div class="stat">Sales less expenses<strong>₱<?= number_format(
    (float) $summary['sales'] - $expenses,
    2,
) ?></strong><small class="muted">Estimate; excludes product cost and other overhead.</small></div>
</div>
<h2>Best sellers</h2>
<div class="table-wrap">
  <table>
    <thead>
      <tr>
        <th>Product</th>
        <th>Units sold</th>
      </tr>
    </thead>
    <tbody>
      <?php foreach (
    $best
    as $x
): ?>

      <tr>
        <td><?= e($x['product_name_snapshot']) ?></td>
        <td><?= (int) $x[
    'units'
] ?></td>
      </tr>
      <?php endforeach; ?>
      <?php if (!$best): ?>
      <tr><td colspan="2" class="empty-note">No sales in this date range.</td></tr>
      <?php endif; ?>

    </tbody>
  </table>
</div>
<h2>Low stock (5 or fewer)</h2>
<div class="table-wrap">
  <table>
    <thead>
      <tr>
        <th>Product</th>
        <th>SKU</th>
        <th>Stock</th>
      </tr>
    </thead>
    <tbody>
      <?php foreach (
    $low
    as $x
): ?>

      <tr>
        <td><?= e($x['product_name']) ?></td>
        <td><?= e($x['sku']) ?></td>
        <td><?= (int) $x[
    'stock_quantity'
] ?></td>
      </tr>
      <?php endforeach; ?>
      <?php if (!$low): ?>
      <tr><td colspan="3" class="empty-note">No low-stock variants found.</td></tr>
      <?php endif; ?>

    </tbody>
  </table>
</div>
<?php require __DIR__ . '/../includes/admin_footer.php'; ?>
