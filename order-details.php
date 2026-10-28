<?php
require_once __DIR__ . "/includes/functions.php";
require_login();

$id = (int) ($_GET["id"] ?? 0);
$s = $pdo->prepare(
    'SELECT o.*,os.status_name,a.recipient_name,a.phone,a.address_line1,a.city,a.province,a.postal_code,
        (SELECT p.amount FROM payments p WHERE p.order_id=o.order_id ORDER BY p.created_at DESC,p.payment_id DESC LIMIT 1) AS payment_amount
    FROM orders o
    JOIN order_statuses os ON os.order_status_id=o.order_status_id
    LEFT JOIN addresses a ON a.address_id=COALESCE(
        (SELECT a2.address_id FROM addresses a2 WHERE a2.address_id=o.address_id AND a2.user_id=o.user_id LIMIT 1),
        (SELECT a3.address_id FROM addresses a3 WHERE a3.user_id=o.user_id ORDER BY a3.is_default DESC,a3.address_id DESC LIMIT 1)
    )
    WHERE o.order_id=? AND o.user_id=?',
);
$s->execute([$id, current_user()["id"]]);
$o = $s->fetch();

if (!$o) {
    http_response_code(404);
    exit("Order not found.");
}

$i = $pdo->prepare(
    'SELECT product_name_snapshot,sku_snapshot,size_snapshot,color_snapshot,unit_price,quantity,line_total
    FROM order_items
    WHERE order_id=?',
);
$i->execute([$id]);
$items = $i->fetchAll();
$pageTitle = "Order details";
require __DIR__ . "/includes/header.php";
?>

<h1 class="page-title">Order <?= e($o["order_number"]) ?></h1>
<p>
    Status: <b><?= e($o["status_name"]) ?></b> · <?= e($o["placed_at"]) ?>
</p>
<div class="card">
    <h2>Delivery</h2>
    <?php if ($o["recipient_name"] !== null): ?>
    <?= e($o["recipient_name"]) ?>, <?= e($o["phone"]) ?><br />
    <?= e($o["address_line1"]) ?>, <?= e($o["city"]) ?>, <?= e(
    $o["province"],
) ?>
    <?= e($o["postal_code"]) ?>
    <?php else: ?>
    <p>No saved address is available for this order.</p>
    <?php endif; ?>
    <p>Payment amount:
        <strong><?= $o["payment_amount"] === null
            ? "Not recorded"
            : "₱" . number_format((float) $o["payment_amount"], 2) ?></strong>
    </p>
</div>
<div class="table-wrap">
    <table>
        <thead>
            <tr>
                <th>Product</th>
                <th>Unit price</th>
                <th>Qty</th>
                <th>Subtotal</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($items as $x): ?>
                <tr>
                    <td>
                        <?= e($x["product_name_snapshot"]) ?>
                        <div class="muted">
                            <?= e(
                                ($x["size_snapshot"] ?? "One size") .
                                    " / " .
                                    ($x["color_snapshot"] ?? "Default"),
                            ) ?>
                        </div>
                    </td>
                    <td>₱<?= number_format((float) $x["unit_price"], 2) ?></td>
                    <td><?= (int) $x["quantity"] ?></td>
                    <td>₱<?= number_format((float) $x["line_total"], 2) ?></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
</div>
<p>
    <b>Total: ₱<?= number_format((float) $o["total_amount"], 2) ?></b>
</p>

<?php require __DIR__ . "/includes/footer.php"; ?>
