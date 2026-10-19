<?php
require_once __DIR__ . '/includes/functions.php';
require_login();
csrf_check();
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $id = (int) ($_POST['cart_item_id'] ?? 0);
    $action = $_POST['action'] ?? '';
    if ($action === 'remove') {
        $q = $pdo->prepare('DELETE FROM cart_items WHERE cart_item_id=? AND user_id=?');
        $q->execute([$id, current_user()['id']]);
        flash('Item removed.');
    } elseif ($action === 'update') {
        $qty = max(1, min(99, (int) ($_POST['quantity'] ?? 1)));
        $q = $pdo->prepare('UPDATE cart_items SET quantity=? WHERE cart_item_id=? AND user_id=?');
        $q->execute([$qty, $id, current_user()['id']]);
        flash('Cart updated.');
    }
    redirect('/clothing-store-backup/cart.php');
}
$q = $pdo->prepare(
    'SELECT ci.cart_item_id,ci.quantity,p.product_name,pv.price,pv.stock_quantity,sz.size_name,co.color_name FROM cart_items ci JOIN product_variants pv ON pv.variant_id=ci.variant_id JOIN products p ON p.product_id=pv.product_id LEFT JOIN sizes sz ON sz.size_id=pv.size_id LEFT JOIN colors co ON co.color_id=pv.color_id WHERE ci.user_id=? ORDER BY ci.added_at DESC',
);
$q->execute([current_user()['id']]);
$items = $q->fetchAll();
$total = 0;
foreach ($items as $i) {
    $total += (float) $i['price'] * (int) $i['quantity'];
}
$pageTitle = 'Your cart';
require __DIR__ . '/includes/header.php';
?>

<h1 class="page-title">Your cart</h1>
<?php
if (
    !$items
): ?>

<div class="empty">
  Your cart is empty.
  <a href="/clothing-store-backup/shop.php">Browse the shop</a>.
</div>
<?php else: ?>

<div class="table-wrap">
  <table>
    <thead>
      <tr>
        <th>Item</th>
        <th>Price</th>
        <th>Qty</th>
        <th>Subtotal</th>
        <th></th>
      </tr>
    </thead>
    <tbody>
      <?php foreach (
    $items
    as $i
): ?>

      <tr>
        <td>
          <?= e($i['product_name']) ?>

          <div class="muted"><?= e(
    ($i['size_name'] ?? 'One size') . ' / ' . ($i['color_name'] ?? 'Default'),
) ?></div>
        </td>
        <td>₱<?= number_format(
    (float) $i['price'],
    2,
) ?>
</td>
        <td>
          <form method="post" class="row">
            <input type="hidden" name="csrf" value="<?= e(
    csrf_token(),
) ?>" />
            <input type="hidden" name="cart_item_id" value="<?= (int) $i[
    'cart_item_id'
] ?>" />
            <input type="hidden" name="action" value="update" />
            <input class="quantity" type="number" name="quantity" min="1" max="<?= (int) $i[
    'stock_quantity'
] ?>" value="<?= (int) $i['quantity'] ?>" />
            <button>Update</button>
          </form>
        </td>
        <td>₱<?= number_format(
    (float) $i['price'] * (int) $i['quantity'],
    2,
) ?>
</td>
        <td>
          <form method="post">
            <input type="hidden" name="csrf" value="<?= e(
    csrf_token(),
) ?>" />
            <input type="hidden" name="cart_item_id" value="<?= (int) $i[
    'cart_item_id'
] ?>" />
            <input type="hidden" name="action" value="remove" />
            <button class="secondary">Remove</button>
          </form>
        </td>
      </tr>
      <?php endforeach; ?>

    </tbody>
  </table>
</div>
<div class="section-head">
  <span></span>
  <b>Total: ₱<?= number_format(
    $total,
    2,
) ?></b>
</div>
<a class="button" href="/clothing-store-backup/checkout.php">Continue to checkout</a>
<?php endif;
require __DIR__ . '/includes/footer.php';

?>
