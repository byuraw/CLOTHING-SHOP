<?php
require_once __DIR__ . "/includes/functions.php";
require_login();

if ($_SERVER["REQUEST_METHOD"] === "POST") {
    csrf_check();
    $pdo->beginTransaction();

    try {
        $uid = current_user()["id"];
        $s = $pdo->prepare(
            'SELECT ci.variant_id,ci.quantity,p.product_name,pv.sku,pv.price,pv.stock_quantity,sz.size_name,co.color_name
            FROM cart_items ci
            JOIN product_variants pv ON pv.variant_id=ci.variant_id
            JOIN products p ON p.product_id=pv.product_id
            LEFT JOIN sizes sz ON sz.size_id=pv.size_id
            LEFT JOIN colors co ON co.color_id=pv.color_id
            WHERE ci.user_id=? FOR UPDATE',
        );
        $s->execute([$uid]);
        $items = $s->fetchAll();

        if (!$items) {
            throw new RuntimeException("Your cart is empty.");
        }

        $subtotalCents = 0;
        foreach ($items as $i) {
            if (
                (int) $i["quantity"] < 1 ||
                (int) $i["quantity"] > (int) $i["stock_quantity"]
            ) {
                throw new RuntimeException(
                    "An item no longer has enough stock. Please update your cart.",
                );
            }

            $subtotalCents +=
                (int) round((float) $i["price"] * 100) *
                (int) $i["quantity"];
        }
        $subtotal = $subtotalCents / 100;

        $paymentAmountInput = trim((string) ($_POST["payment_amount"] ?? ""));
        if (!preg_match('/^\d{1,8}(?:\.\d{1,2})?$/D', $paymentAmountInput)) {
            throw new RuntimeException("Enter a valid payment amount.");
        }
        $paymentParts = explode(".", $paymentAmountInput, 2);
        $paymentAmountCents =
            (int) $paymentParts[0] * 100 +
            (int) str_pad($paymentParts[1] ?? "", 2, "0");

        if ($paymentAmountCents < $subtotalCents) {
            throw new RuntimeException(
                "Payment amount is insufficient. Enter at least ₱" .
                    number_format($subtotal, 2) .
                    ".",
            );
        }
        $paymentAmount = number_format(
            $paymentAmountCents / 100,
            2,
            ".",
            "",
        );

        $addressId = (int) ($_POST["address_id"] ?? 0);
        $savedAddress = $pdo->prepare(
            "SELECT address_id FROM addresses WHERE address_id=? AND user_id=? FOR UPDATE",
        );
        $savedAddress->execute([$addressId, $uid]);

        if (!$savedAddress->fetchColumn()) {
            throw new RuntimeException(
                "Choose one of your saved delivery addresses.",
            );
        }

        $status = (int) $pdo
            ->query(
                "SELECT order_status_id FROM order_statuses WHERE status_name='Pending'",
            )
            ->fetchColumn();
        $shipping = 0.0;
        $number =
            "ORD-" . date("Ymd") . "-" . strtoupper(bin2hex(random_bytes(3)));
        $o = $pdo->prepare(
            'INSERT INTO orders(user_id,address_id,order_status_id,order_number,subtotal,shipping_fee,total_amount,customer_note)
            VALUES(?,?,?,?,?,?,?,?)',
        );
        $o->execute([
            $uid,
            $addressId,
            $status,
            $number,
            $subtotal,
            $shipping,
            $subtotal + $shipping,
            trim($_POST["customer_note"] ?? "") ?: null,
        ]);
        $orderId = (int) $pdo->lastInsertId();
        $oi = $pdo->prepare(
            'INSERT INTO order_items(
                order_id,variant_id,product_name_snapshot,sku_snapshot,size_snapshot,color_snapshot,
                unit_price,quantity,line_total
            )
            VALUES(?,?,?,?,?,?,?,?,?)',
        );
        $stock = $pdo->prepare(
            'UPDATE product_variants
            SET stock_quantity=stock_quantity-?
            WHERE variant_id=? AND stock_quantity>=?',
        );
        foreach ($items as $i) {
            $qty = (int) $i["quantity"];
            $oi->execute([
                $orderId,
                $i["variant_id"],
                $i["product_name"],
                $i["sku"],
                $i["size_name"],
                $i["color_name"],
                $i["price"],
                $qty,
                (float) $i["price"] * $qty,
            ]);
            $stock->execute([$qty, $i["variant_id"], $qty]);

            if ($stock->rowCount() !== 1) {
                throw new RuntimeException(
                    "Stock changed during checkout. Please try again.",
                );
            }

            log_inventory(
                $pdo,
                (int) $i["variant_id"],
                (int) $uid,
                -$qty,
                "SALE",
                $number,
            );
        }

        $pay = $pdo->prepare(
            "INSERT INTO payments(order_id,amount,payment_status) VALUES(?,?,'pending')",
        );
        $pay->execute([$orderId, $paymentAmount]);
        log_order_status($pdo, $orderId, $status, $uid, "Order placed");
        $del = $pdo->prepare("DELETE FROM cart_items WHERE user_id=?");
        $del->execute([$uid]);
        $pdo->commit();

        flash("Order placed successfully.");
        redirect(APP_BASE . "/order-details.php?id=" . $orderId);
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }

        flash(
            $e instanceof RuntimeException
                ? $e->getMessage()
                : "Checkout failed. Please try again.",
            "error",
        );
        redirect(APP_BASE . "/checkout.php");
    }
}

$q = $pdo->prepare(
    'SELECT ci.quantity,p.product_name,pv.price,pv.stock_quantity
    FROM cart_items ci
    JOIN product_variants pv ON pv.variant_id=ci.variant_id
    JOIN products p ON p.product_id=pv.product_id
    WHERE ci.user_id=?',
);
$q->execute([current_user()["id"]]);
$items = $q->fetchAll();
$addressQuery = $pdo->prepare(
    'SELECT address_id,recipient_name,phone,address_line1,city,province,postal_code
    FROM addresses WHERE user_id=? ORDER BY is_default DESC,address_id DESC',
);
$addressQuery->execute([current_user()["id"]]);
$deliveryAddress = $addressQuery->fetchAll();
$totalCents = 0;

foreach ($items as $i) {
    $totalCents +=
        (int) round((float) $i["price"] * 100) * (int) $i["quantity"];
}
$total = $totalCents / 100;

$pageTitle = "Checkout";
require __DIR__ . "/includes/header.php";
?>

<h1 class="page-title">Checkout</h1>
<?php if (!$items): ?>
    <div class="empty">
        Your cart is empty. <a href="<?= APP_BASE ?>/shop.php">Shop now</a>
    </div>
<?php else: ?>
    <div class="row">
        <?php if (!$deliveryAddress): ?>
            <section class="notice">
                Save a delivery address before checking out.
                <a href="<?= e(APP_BASE . "/user/addresses.php") ?>">Manage addresses</a>
            </section>
        <?php else: ?>
        <form class="form-card" method="post">
            <h2>Delivery address</h2>
            <input type="hidden" name="csrf" value="<?= e(csrf_token()) ?>" />
            <label for="address_id">Saved address</label>
            <select id="address_id" name="address_id" required>
                <?php foreach ($deliveryAddress as $address): ?>
                    <option value="<?= (int) $address["address_id"] ?>">
                        <?= e(
                            $address["recipient_name"] .
                                " · " .
                                $address["phone"] .
                                " · " .
                                $address["address_line1"] .
                                ", " .
                                $address["city"] .
                                ", " .
                                $address["province"] .
                                " " .
                                $address["postal_code"],
                        ) ?>
                    </option>
                <?php endforeach; ?>
            </select>
            <p><a href="<?= e(APP_BASE . "/user/addresses.php") ?>">Manage saved addresses</a></p>

            <label for="payment_amount">Payment amount (₱)</label>
            <input
                id="payment_amount"
                name="payment_amount"
                type="number"
                min="<?= number_format($total, 2, ".", "") ?>"
                step="0.01"
                value="<?= number_format($total, 2, ".", "") ?>"
                required
                aria-describedby="payment-amount-warning"
            />
            <p id="payment-amount-warning" class="notice error" role="alert" hidden>
                Payment amount is insufficient. Enter at least ₱<?= number_format($total, 2) ?>.
            </p>
            <label>Order note (optional)</label>
            <textarea name="customer_note"></textarea>
            <button id="place-order-button">Place order - ₱<?= number_format($total, 2) ?></button>
        </form>
        <?php endif; ?>

        <section class="card">
            <h2>Order summary</h2>
            <?php foreach ($items as $i): ?>
                <p>
                    <?= e($i["product_name"]) ?> × <?= (int) $i["quantity"] ?>
                    <span style="float: right">
                        ₱<?= number_format(
                            (float) $i["price"] * (int) $i["quantity"],
                            2,
                        ) ?>
                    </span>
                </p>
            <?php endforeach; ?>
            <hr />
            <b>Total ₱<?= number_format($total, 2) ?></b>
        </section>
    </div>
<?php endif; ?>

<script>
    const paymentAmountInput = document.getElementById("payment_amount");
    const paymentAmountWarning = document.getElementById("payment-amount-warning");
    const placeOrderButton = document.getElementById("place-order-button");

    if (paymentAmountInput && paymentAmountWarning && placeOrderButton) {
        const minimumPaymentCents = Math.round(Number(paymentAmountInput.min) * 100);
        const validatePaymentAmount = () => {
            const enteredAmount = Number(paymentAmountInput.value);
            const enteredAmountCents = Number.isFinite(enteredAmount)
                ? Math.round(enteredAmount * 100)
                : 0;
            const insufficient = enteredAmountCents < minimumPaymentCents;

            paymentAmountWarning.hidden = !insufficient;
            placeOrderButton.disabled = insufficient;
        };

        paymentAmountInput.addEventListener("input", validatePaymentAmount);
        validatePaymentAmount();
    }
</script>

<?php require __DIR__ . "/includes/footer.php"; ?>
