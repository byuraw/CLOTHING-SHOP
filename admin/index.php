<?php
require_once __DIR__ . "/../includes/functions.php";
require_admin();

$paidStatuses = "('Processing','Packed','Shipped','Delivered','Completed')";

$newOrders = (int) $pdo
    ->query(
        "SELECT COUNT(*)
        FROM orders o
        JOIN order_statuses s ON s.order_status_id=o.order_status_id
        WHERE s.status_name='Pending'",
    )
    ->fetchColumn();
$products = (int) $pdo
    ->query("SELECT COUNT(*) FROM products WHERE is_active=1")
    ->fetchColumn();
$customers = (int) $pdo
    ->query(
        "SELECT COUNT(*)
        FROM users u
        WHERE u.role_name='Customer'",
    )
    ->fetchColumn();

$firstMonth = new DateTimeImmutable("first day of this month");
$from = $firstMonth->modify("-6 months")->format("Y-m-01");
$salesQuery = $pdo->prepare(
    "SELECT s.sale_date AS placed_at,s.total_amount
    FROM sales s
    WHERE s.sale_date>=?",
);
$salesQuery->execute([$from . " 00:00:00"]);
$months = [];

for ($i = 6; $i >= 0; $i--) {
    $month = $firstMonth->modify("-$i months");
    $months[$month->format("Y-m")] = 0.0;
}

foreach ($salesQuery->fetchAll() as $sale) {
    $key = substr((string) $sale["placed_at"], 0, 7);
    if (array_key_exists($key, $months)) {
        $months[$key] += (float) $sale["total_amount"];
    }
}

$salesThisMonth = $months[date("Y-m")] ?? 0.0;
$maxSales = max($months);
$pointCount = count($months);
$points = [];

foreach ($months as $month => $amount) {
    $index = count($points);
    $x = round($index * (560 / ($pointCount - 1)), 1);
    $y = $maxSales > 0 ? round(160 - ($amount / $maxSales) * 130, 1) : 160;
    $points[] = [
        "x" => $x,
        "y" => $y,
        "label" => date("M", strtotime($month . "-01")),
    ];
}

$linePoints = implode(
    " ",
    array_map(static fn($point) => $point["x"] . "," . $point["y"], $points),
);

$lowStock = $pdo
    ->query(
        'SELECT p.product_name,pv.stock_quantity,sz.size_name,co.color_name
        FROM product_variants pv
        JOIN products p ON p.product_id=pv.product_id
        LEFT JOIN sizes sz ON sz.size_id=pv.size_id
        LEFT JOIN colors co ON co.color_id=pv.color_id
        WHERE pv.is_active=1 AND p.is_active=1 AND pv.stock_quantity<=5
        ORDER BY pv.stock_quantity ASC,p.product_name
        LIMIT 4',
    )
    ->fetchAll();
$recentOrders = $pdo
    ->query(
        'SELECT o.order_number,o.total_amount,os.status_name,u.first_name,u.last_name
        FROM orders o
        JOIN order_statuses os ON os.order_status_id=o.order_status_id
        JOIN users u ON u.user_id=o.user_id
        ORDER BY o.placed_at DESC
        LIMIT 6',
    )
    ->fetchAll();

$pageTitle = "Dashboard";
require __DIR__ . "/../includes/admin_header.php";

$cards = [
    [
        $newOrders,
        "New orders",
        "#3a6794",
        '<circle cx="9" cy="20" r="1.4"/><circle cx="18" cy="20" r="1.4"/><path d="M2 3h2l2.6 13.2a2 2 0 0 0 2 1.6h8.8a2 2 0 0 0 2-1.6L21 7H6"/>',
    ],
    [
        "₱" . number_format($salesThisMonth),
        "Sales this month",
        "#2b5079",
        '<path d="M3 17l6-6 4 4 7-8"/>',
    ],
    [
        $products,
        "Active products",
        "#7a7d82",
        '<path d="M6 2l1 5h10l1-5"/><path d="M4 7h16l-1.5 13a2 2 0 0 1-2 2H7.5a2 2 0 0 1-2-2L4 7z"/>',
    ],
    [
        $customers,
        "Customers",
        "#a33a2f",
        '<circle cx="12" cy="8" r="3.4"/><path d="M4.5 20a7.5 7.5 0 0 1 15 0"/>',
    ],
];
?>

<div class="stats">
    <?php foreach ($cards as [$value, $label, $background, $icon]): ?>
        <article class="stat-card">
            <div class="stat-top">
                <div class="stat-ico" style="background:<?= e($background) ?>">
                    <svg viewBox="0 0 24 24" aria-hidden="true"><?= $icon ?></svg>
                </div>
            </div>
            <div class="stat-val">
                <?= is_int($value) ? number_format($value) : e($value) ?>
            </div>
            <div class="stat-lbl"><?= e($label) ?></div>
        </article>
    <?php endforeach; ?>
</div>

<div class="panels">
    <article class="card">
        <h2>Sales value</h2>
        <svg
            class="admin-sales-chart"
            viewBox="0 0 560 190"
            preserveAspectRatio="none"
            role="img"
            aria-label="Line chart of monthly sales value over the last seven months"
        >
            <polyline
                points="<?= e($linePoints) ?>"
                fill="none"
                stroke="#3a6794"
                stroke-width="2.5"
                vector-effect="non-scaling-stroke"
            />
        </svg>
        <div style="display:flex;justify-content:space-between;font-size:10.5px;color:#7a7d82;margin-top:6px">
            <?php foreach ($points as $point): ?>
                <span><?= e($point["label"]) ?></span>
            <?php endforeach; ?>
        </div>
    </article>

    <article class="card">
        <h2>Low stock</h2>
        <?php if (!$lowStock): ?>
            <p class="empty-note">Every active item has more than 5 in stock.</p>
        <?php endif; ?>
        <?php foreach ($lowStock as $item): ?>
            <?php $quantity = (int) $item["stock_quantity"]; ?>
            <div class="chat-msg">
                <div class="chat-av"<?= $quantity === 0
                    ? ' style="background:#f6e3e1;color:#a33a2f"'
                    : "" ?>>
                    <?= $quantity ?>
                </div>
                <div>
                    <div class="chat-name"><?= e($item["product_name"]) ?></div>
                    <div class="chat-txt">
                        <?= e(
                            ($item["size_name"] ?? "One size") .
                                " / " .
                                ($item["color_name"] ?? "Default"),
                        ) ?>
                        &middot;
                        <?= $quantity === 0
                            ? "Out of stock"
                            : $quantity . " left" ?>
                    </div>
                </div>
            </div>
        <?php endforeach; ?>
    </article>
</div>

<section class="card">
    <h2>Recent orders</h2>
    <?php if (!$recentOrders): ?>
        <p class="empty-note">No orders yet.</p>
    <?php else: ?>
        <table>
            <thead>
                <tr>
                    <th>Order</th>
                    <th>Customer</th>
                    <th>Total</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($recentOrders as $order): ?>
                    <?php
                    $status = $order["status_name"];
                    $statusClass = in_array(
                        $status,
                        ["Delivered", "Completed"],
                        true,
                    )
                        ? "b-done"
                        : ($status === "Cancelled"
                            ? "b-cancel"
                            : "b-pend");
                    ?>
                    <tr>
                        <td><?= e($order["order_number"]) ?></td>
                        <td><?= e(
                            $order["first_name"] . " " . $order["last_name"],
                        ) ?></td>
                        <td>₱<?= number_format(
                            (float) $order["total_amount"],
                            2,
                        ) ?></td>
                        <td><span class="badge <?= e($statusClass) ?>"><?= e(
    $status,
) ?></span></td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    <?php endif; ?>
</section>

<?php require __DIR__ . "/../includes/admin_footer.php"; ?>
