<?php
require_once __DIR__ . "/../includes/functions.php";
require_admin();
$today = $pdo->query("SELECT CURRENT_DATE")->fetchColumn();
$from = $_GET["from"] ?? substr($today, 0, 7) . "-01";
$to = $_GET["to"] ?? $today;
$transactionType = $_GET["transaction_type"] ?? "all";
if (!in_array($transactionType, ["all", "single", "multi"], true)) {
    $transactionType = "all";
}
$args = [$from, $to];
$q = $pdo->prepare(
    "SELECT COUNT(*) orders_count,COALESCE(SUM(s.total_amount),0) sales
    FROM sales s
    WHERE s.sale_date >= ?
      AND s.sale_date < DATE_ADD(?, INTERVAL 1 DAY)",
);
$q->execute($args);

$summary = $q->fetch();
$transactionQuery = $pdo->prepare(
    "SELECT
        s.transaction_reference,
        s.sale_date,
        o.order_number,
        CONCAT(u.first_name, ' ', u.last_name) AS customer_name,
        COALESCE(items.item_count, 0) AS item_count,
        COALESCE(items.total_quantity, 0) AS total_quantity,
        s.total_amount,
        (
            SELECT p.amount
            FROM payments p
            WHERE p.order_id = s.order_id
            ORDER BY p.created_at DESC, p.payment_id DESC
            LIMIT 1
        ) AS payment_amount
    FROM sales s
    JOIN orders o ON o.order_id = s.order_id
    JOIN users u ON u.user_id = o.user_id
    LEFT JOIN (
        SELECT order_id, COUNT(*) AS item_count, SUM(quantity) AS total_quantity
        FROM order_items
        GROUP BY order_id
    ) items ON items.order_id = s.order_id
    WHERE s.sale_date >= ?
      AND s.sale_date < DATE_ADD(?, INTERVAL 1 DAY)
      AND (
        ? = 'all'
        OR (? = 'single' AND COALESCE(items.item_count, 0) = 1)
        OR (? = 'multi' AND COALESCE(items.item_count, 0) > 1)
      )
    ORDER BY s.sale_date DESC, s.sale_id DESC",
);
$transactionQuery->execute([
    $from,
    $to,
    $transactionType,
    $transactionType,
    $transactionType,
]);
$transactions = $transactionQuery->fetchAll();
$q = $pdo->prepare(
    "SELECT COALESCE(SUM(amount),0) FROM expenses WHERE expense_date BETWEEN ? AND ?",
);
$q->execute([$from, $to]);
$expenses = (float) $q->fetchColumn();
$q = $pdo->prepare(
    "SELECT oi.product_name_snapshot,SUM(oi.quantity) units
    FROM sales s
    JOIN order_items oi ON oi.order_id=s.order_id
    WHERE s.sale_date >= ?
      AND s.sale_date < DATE_ADD(?, INTERVAL 1 DAY)
    GROUP BY oi.product_name_snapshot
    ORDER BY units DESC
    LIMIT 10",
);
$q->execute($args);
$best = $q->fetchAll();
$q = $pdo->prepare(
    "SELECT p.product_name,v.sku,v.stock_quantity FROM product_variants v JOIN products p ON p.product_id=v.product_id WHERE v.stock_quantity<=5 ORDER BY v.stock_quantity,p.product_name",
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

<form class="transaction-filter" method="get">
  <input type="hidden" name="from" value="<?= e($from) ?>" />
  <input type="hidden" name="to" value="<?= e($to) ?>" />
  <label>Transaction type
    <select name="transaction_type">
      <option value="all" <?= $transactionType === "all" ? "selected" : "" ?>>All transactions</option>
      <option value="single" <?= $transactionType === "single" ? "selected" : "" ?>>Single-item</option>
      <option value="multi" <?= $transactionType === "multi" ? "selected" : "" ?>>Multi-item</option>
    </select>
  </label>
  <button>Filter transactions</button>
</form>

<div class="table-wrap">
  <table>
    <thead>
      <tr>
        <th>Date</th>
        <th>Transaction</th>
        <th>Order</th>
        <th>Customer</th>
        <th>Item lines</th>
        <th>Units</th>
        <th>Type</th>
        <th>Total</th>
        <th>Payment amount</th>
      </tr>
    </thead>
    <tbody>
      <?php foreach ($transactions as $transaction): ?>
      <tr>
        <td><?= e($transaction["sale_date"]) ?></td>
        <td><?= e($transaction["transaction_reference"]) ?></td>
        <td><?= e($transaction["order_number"]) ?></td>
        <td><?= e($transaction["customer_name"]) ?></td>
        <td><?= (int) $transaction["item_count"] ?></td>
        <td><?= (int) $transaction["total_quantity"] ?></td>
        <td><?= (int) $transaction["item_count"] === 1
            ? "Single-item"
            : ((int) $transaction["item_count"] > 1
                ? "Multi-item"
                : "No items") ?></td>
        <td>₱<?= number_format((float) $transaction["total_amount"], 2) ?></td>
        <td><?= $transaction["payment_amount"] === null
            ? "—"
            : "₱" . number_format((float) $transaction["payment_amount"], 2) ?></td>
      </tr>
      <?php endforeach; ?>
      <?php if (!$transactions): ?>
      <tr><td colspan="9" class="empty-note">No transactions match these filters.</td></tr>
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
