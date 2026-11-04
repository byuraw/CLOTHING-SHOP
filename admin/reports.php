<?php
require_once __DIR__ . "/../includes/functions.php";
require_admin();
$today = $pdo->query("SELECT CURRENT_DATE")->fetchColumn();
$from = $_GET["from"] ?? substr($today, 0, 7) . "-01";
$to = $_GET["to"] ?? $today;
$args = [$from, $to];
$q = $pdo->prepare(
    "SELECT COUNT(*) orders_count,COALESCE(SUM(o.subtotal),0) sales
    FROM sales s
    INNER JOIN orders o ON o.order_id=s.order_id
    WHERE s.sale_date >= ?
      AND s.sale_date < DATE_ADD(?, INTERVAL 1 DAY)",
);
$q->execute($args);

$summary = $q->fetch();
$transactionQuery = $pdo->prepare(
    "SELECT details.placed_at,details.status_name,details.user_id,
        details.customer_name,details.order_number,details.order_item_id,
        details.product_name_snapshot,details.size_snapshot,details.color_snapshot,
        details.unit_price,details.quantity,s.transaction_reference,s.sale_date,
        s.total_amount AS sale_total
    FROM vw_order_transaction_details details
    INNER JOIN sales s ON s.order_id = details.order_id
    WHERE s.sale_date >= ?
      AND s.sale_date < DATE_ADD(?, INTERVAL 1 DAY)
      AND details.status_name = 'Completed'
    ORDER BY s.sale_date DESC,s.sale_id DESC,details.order_item_id",
);
$transactionQuery->execute($args);
$transactions = $transactionQuery->fetchAll();
$q = $pdo->prepare(
    "SELECT COALESCE(SUM(amount),0) FROM expenses WHERE expense_date BETWEEN ? AND ?",
);
$q->execute([$from, $to]);
$expenses = (float) $q->fetchColumn();
$q = $pdo->prepare(
    "SELECT oi.product_name_snapshot,SUM(oi.quantity) units
    FROM sales s
    INNER JOIN order_items oi ON oi.order_id=s.order_id
    WHERE s.sale_date >= ?
      AND s.sale_date < DATE_ADD(?, INTERVAL 1 DAY)
    GROUP BY oi.product_name_snapshot
    ORDER BY units DESC
    LIMIT 10",
);
$q->execute($args);
$best = $q->fetchAll();
$q = $pdo->prepare(
    "SELECT p.product_name,v.sku,v.stock_quantity FROM product_variants v INNER JOIN products p ON p.product_id=v.product_id WHERE v.stock_quantity<=5 ORDER BY v.stock_quantity,p.product_name",
);
$q->execute();
$low = $q->fetchAll();
$pageTitle = "Reports";
require __DIR__ . "/../includes/admin_header.php";
?>

<h1 class="page-title">Reports</h1>
<form class="row" method="get">
  <label>From<input type="date" name="from" value="<?= e(
      $from,
  ) ?>" /></label><label>To<input type="date" name="to" value="<?= e(
    $to,
) ?>" /></label>
  <button>Apply</button>
</form>

<div class="grid">
  <div class="stat">Orders<strong><?= (int) $summary[
      "orders_count"
  ] ?></strong></div>
  <div class="stat">Sales<strong>₱<?= number_format(
      (float) $summary["sales"],
      2,
  ) ?></strong></div>
  <div class="stat">Expenses<strong>₱<?= number_format(
      $expenses,
      2,
  ) ?></strong></div>
  <div class="stat">Sales less expenses<strong>₱<?= number_format(
      (float) $summary["sales"] - $expenses,
      2,
  ) ?></strong><small class="muted">Estimate; excludes product cost and other overhead.</small></div>
</div>

<h2>Transactions</h2>

<div class="table-wrap">
  <table>
    <thead>
      <tr>
        <th>Sale date</th>
        <th>Transaction reference</th>
        <th>Order number</th>
        <th>Order date</th>
        <th>Status</th>
        <th>Customer ID</th>
        <th>Customer</th>
        <th>Order item ID</th>
        <th>Product</th>
        <th>Size</th>
        <th>Color</th>
        <th>Unit price</th>
        <th>Quantity</th>
        <th>Sale total</th>
      </tr>
    </thead>
    <tbody>
      <?php foreach ($transactions as $transaction): ?>
      <tr>
        <td><?= e($transaction["sale_date"]) ?></td>
        <td><?= e($transaction["transaction_reference"]) ?></td>
        <td><?= e($transaction["order_number"]) ?></td>
        <td><?= e($transaction["placed_at"]) ?></td>
        <td><?= e($transaction["status_name"]) ?></td>
        <td><?= (int) $transaction["user_id"] ?></td>
        <td><?= e($transaction["customer_name"]) ?></td>
        <td><?= (int) $transaction["order_item_id"] ?></td>
        <td><?= e($transaction["product_name_snapshot"]) ?></td>
        <td><?= e($transaction["size_snapshot"] ?? "One size") ?></td>
        <td><?= e($transaction["color_snapshot"] ?? "Default") ?></td>
        <td>₱<?= number_format((float) $transaction["unit_price"], 2) ?></td>
        <td><?= (int) $transaction["quantity"] ?></td>
        <td>₱<?= number_format((float) $transaction["sale_total"], 2) ?></td>
      </tr>
      <?php endforeach; ?>
      <?php if (!$transactions): ?>
      <tr><td colspan="14" class="empty-note">No transactions match this date range.</td></tr>
      <?php endif; ?>
    </tbody>
  </table>
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
      <?php foreach ($best as $x): ?>

      <tr>
        <td><?= e($x["product_name_snapshot"]) ?></td>
        <td><?= (int) $x["units"] ?></td>
      </tr>
      <?php endforeach; ?>
      <?php if (!$best): ?>
      <tr><td colspan="2" class="empty-note">No sales in this date range.</td></tr>
      <?php endif; ?>

    </tbody>
  </table>
</div>
<details>
  <summary>Low stock (5 or fewer)</summary>
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
      <?php foreach ($low as $x): ?>

      <tr>
        <td><?= e($x["product_name"]) ?></td>
        <td><?= e($x["sku"]) ?></td>
        <td><?= (int) $x["stock_quantity"] ?></td>
      </tr>
      <?php endforeach; ?>
      <?php if (!$low): ?>
      <tr><td colspan="3" class="empty-note">No low-stock variants found.</td></tr>
      <?php endif; ?>

    </tbody>
  </table>
</div>
</details>
<?php require __DIR__ . "/../includes/admin_footer.php"; ?>
