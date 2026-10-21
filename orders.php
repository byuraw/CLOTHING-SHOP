<?php
require_once __DIR__ . "/includes/functions.php";
require_login();

$s = $pdo->prepare(
    'SELECT o.order_id,o.order_number,o.total_amount,o.placed_at,os.status_name
    FROM orders o
    JOIN order_statuses os ON os.order_status_id=o.order_status_id
    WHERE o.user_id=?
    ORDER BY o.placed_at DESC',
);
$s->execute([current_user()["id"]]);
$orders = $s->fetchAll();
$pageTitle = "My orders";
require __DIR__ . "/includes/header.php";
?>

<h1 class="page-title">My orders</h1>
<?php if (!$orders): ?>
    <div class="empty">
        You have not placed an order yet.
        <a href="/clothing-store-backup/shop.php">Start shopping</a>.
    </div>
<?php else: ?>
    <div class="table-wrap">
        <table>
            <thead>
                <tr>
                    <th>Order</th>
                    <th>Date</th>
                    <th>Status</th>
                    <th>Total</th>
                    <th></th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($orders as $o): ?>
                    <tr>
                        <td><?= e($o["order_number"]) ?></td>
                        <td><?= e($o["placed_at"]) ?></td>
                        <td><?= e($o["status_name"]) ?></td>
                        <td>₱<?= number_format(
                            (float) $o["total_amount"],
                            2,
                        ) ?></td>
                        <td>
                            <a href="/clothing-store-backup/order-details.php?id=<?= (int) $o[
                                "order_id"
                            ] ?>">
                                Details
                            </a>
                        </td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>
<?php endif; ?>

<?php require __DIR__ . "/includes/footer.php"; ?>
