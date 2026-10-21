<?php
require_once __DIR__ . '/includes/functions.php';
require_login();

$methods = $pdo
    ->query('SELECT payment_method_id,method_name FROM payment_methods ORDER BY payment_method_id')
    ->fetchAll();

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_check();
    $pdo->beginTransaction();

    try {
        $uid = current_user()['id'];
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
            throw new RuntimeException('Your cart is empty.');
        }

        $subtotal = 0;
        foreach ($items as $i) {
            if ((int) $i['quantity'] < 1 || (int) $i['quantity'] > (int) $i['stock_quantity']) {
                throw new RuntimeException(
                    'An item no longer has enough stock. Please update your cart.',
                );
            }

            $subtotal += (float) $i['price'] * (int) $i['quantity'];
        }

        $method = (int) ($_POST['payment_method_id'] ?? 0);
        $validMethod = $pdo->prepare(
            'SELECT payment_method_id FROM payment_methods WHERE payment_method_id=?',
        );
        $validMethod->execute([$method]);

        if (!$validMethod->fetchColumn()) {
            throw new RuntimeException('Choose a valid payment method.');
        }

        $recipient = trim($_POST['recipient_name'] ?? '');
        $phone = trim($_POST['phone'] ?? '');
        $line = trim($_POST['address_line1'] ?? '');
        $city = trim($_POST['city'] ?? '');
        $province = trim($_POST['province'] ?? '');
        $postal = trim($_POST['postal_code'] ?? '');

        if (!$recipient || !$phone || !$line || !$city || !$province || !$postal) {
            throw new RuntimeException('Complete every delivery address field.');
        }

        $a = $pdo->prepare(
            'INSERT INTO addresses(user_id,recipient_name,phone,address_line1,city,province,postal_code,is_default)
            VALUES(?,?,?,?,?,?,?,0)',
        );
        $a->execute([$uid, $recipient, $phone, $line, $city, $province, $postal]);
        $addressId = (int) $pdo->lastInsertId();
        $status = (int) $pdo
            ->query("SELECT order_status_id FROM order_statuses WHERE status_name='Pending'")
            ->fetchColumn();
        $shipping = 0.0;
        $number = 'ORD-' . date('Ymd') . '-' . strtoupper(bin2hex(random_bytes(3)));
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
            trim($_POST['customer_note'] ?? '') ?: null,
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
        $inv = $pdo->prepare(
            'INSERT INTO inventory_transactions(variant_id,changed_by,quantity_change,reference_text)
            VALUES(?,?,?,?)',
        );

        foreach ($items as $i) {
            $qty = (int) $i['quantity'];
            $oi->execute([
                $orderId,
                $i['variant_id'],
                $i['product_name'],
                $i['sku'],
                $i['size_name'],
                $i['color_name'],
                $i['price'],
                $qty,
                (float) $i['price'] * $qty,
            ]);
            $stock->execute([$qty, $i['variant_id'], $qty]);

            if ($stock->rowCount() !== 1) {
                throw new RuntimeException('Stock changed during checkout. Please try again.');
            }

            $inv->execute([$i['variant_id'], $uid, -$qty, $number]);
        }

        $pay = $pdo->prepare(
            "INSERT INTO payments(order_id,payment_method_id,amount,payment_status) VALUES(?,?,?,'pending')",
        );
        $pay->execute([$orderId, $method, $subtotal + $shipping]);
        $hist = $pdo->prepare(
            "INSERT INTO order_status_history(order_id,order_status_id,changed_by,note) VALUES(?,?,?,'Order placed')",
        );
        $hist->execute([$orderId, $status, $uid]);
        $del = $pdo->prepare('DELETE FROM cart_items WHERE user_id=?');
        $del->execute([$uid]);
        $pdo->commit();

        flash('Order placed successfully.');
        redirect('/clothing-store-backup/order-details.php?id=' . $orderId);
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }

        flash(
            $e instanceof RuntimeException
                ? $e->getMessage()
                : 'Checkout failed. Please try again.',
            'error',
        );
        redirect('/clothing-store-backup/checkout.php');
    }
}

$q = $pdo->prepare(
    'SELECT ci.quantity,p.product_name,pv.price,pv.stock_quantity
    FROM cart_items ci
    JOIN product_variants pv ON pv.variant_id=ci.variant_id
    JOIN products p ON p.product_id=pv.product_id
    WHERE ci.user_id=?',
);
$q->execute([current_user()['id']]);
$items = $q->fetchAll();
$addressQuery = $pdo->prepare(
    'SELECT recipient_name,phone,address_line1,city,province,postal_code
    FROM addresses WHERE user_id=? ORDER BY is_default DESC,address_id DESC LIMIT 1',
);
$addressQuery->execute([current_user()['id']]);
$deliveryAddress = $addressQuery->fetch() ?: [];
$total = 0;

foreach ($items as $i) {
    $total += (float) $i['price'] * (int) $i['quantity'];
}

$pageTitle = 'Checkout';
require __DIR__ . '/includes/header.php';
?>

<h1 class="page-title">Checkout</h1>
<?php if (!$items): ?>
    <div class="empty">
        Your cart is empty. <a href="/clothing-store-backup/shop.php">Shop now</a>
    </div>
<?php else: ?>
    <div class="row">
        <form class="form-card" method="post">
            <h2>Delivery address</h2>
            <input type="hidden" name="csrf" value="<?= e(csrf_token()) ?>" />
            <?php
            foreach (
                [
                    'recipient_name' => 'Recipient name',
                    'phone' => 'Phone',
                    'address_line1' => 'Address',
                    'city' => 'City',
                    'province' => 'Province',
                    'postal_code' => 'Postal code',
                ] as $key => $label
            ):
                ?>
                <label><?= e($label) ?></label>
                <input name="<?= e($key) ?>" value="<?= e($deliveryAddress[$key] ?? '') ?>" />
            <?php endforeach; ?>

            <label>Payment method</label>
            <select name="payment_method_id">
                <?php foreach ($methods as $m): ?>
                    <option value="<?= (int) $m['payment_method_id'] ?>">
                        <?= e($m['method_name']) ?>
                    </option>
                <?php endforeach; ?>
            </select>
            <label>Order note (optional)</label>
            <textarea name="customer_note"></textarea>
            <button>Place order - ₱<?= number_format($total, 2) ?></button>
        </form>

        <section class="card">
            <h2>Order summary</h2>
            <?php foreach ($items as $i): ?>
                <p>
                    <?= e($i['product_name']) ?> × <?= (int) $i['quantity'] ?>
                    <span style="float: right">
                        ₱<?= number_format((float) $i['price'] * (int) $i['quantity'], 2) ?>
                    </span>
                </p>
            <?php endforeach; ?>
            <hr />
            <b>Total ₱<?= number_format($total, 2) ?></b>
        </section>
    </div>
<?php endif; ?>

<?php require __DIR__ . '/includes/footer.php'; ?>
