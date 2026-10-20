<?php
require_once __DIR__ . '/../includes/functions.php';
require_admin();
$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_check();
    $variant = (int) ($_POST['variant_id'] ?? 0);
    $qty = (int) ($_POST['quantity'] ?? 0);
    $reason = trim($_POST['reason'] ?? 'Restock');
    if ($variant > 0 && $qty > 0) {
        $pdo->beginTransaction();
        try {
            $q = $pdo->prepare(
                'UPDATE product_variants SET stock_quantity=stock_quantity+? WHERE variant_id=?',
            );
            $q->execute([$qty, $variant]);
            $q = $pdo->prepare(
                "INSERT INTO inventory_transactions(variant_id,changed_by,quantity_change,reason,reference_text) VALUES(?,?,?,'RESTOCK',?)",
            );
            $q->execute([$variant, current_user()['id'], $qty, $reason]);
            $pdo->commit();
            flash('Stock restocked.');
            redirect('/clothing-store-backup/admin/inventory.php');
        } catch (Throwable $e) {
            $pdo->rollBack();
            $error = 'Could not update inventory.';
        }
    } else {
        $error = 'Choose a variant and enter a positive quantity.';
    }
}
$list = $pdo
    ->query(
        'SELECT v.variant_id,v.sku,v.stock_quantity,v.price,p.product_name,s.size_name,c.color_name FROM product_variants v JOIN products p ON p.product_id=v.product_id LEFT JOIN sizes s ON s.size_id=v.size_id LEFT JOIN colors c ON c.color_id=v.color_id WHERE v.is_active=1 ORDER BY p.product_name',
    )
    ->fetchAll();
$pageTitle = 'Inventory';
require __DIR__ . '/../includes/admin_header.php';
?>

<h1 class="page-title">Inventory</h1>
<?php if ($error): ?>

<div class="notice error"><?= e(
    $error,
) ?></div>
<?php endif; ?>

<div class="table-wrap">
  <table>
    <thead>
      <tr>
        <th>Product / option</th>
        <th>SKU</th>
        <th>On hand</th>
        <th>Restock</th>
      </tr>
    </thead>
    <tbody>
      <?php foreach (
    $list
    as $x
): ?>

      <tr>
        <td><?= e(
    $x['product_name'] .
        ' / ' .
        ($x['size_name'] ?? 'One size') .
        ' / ' .
        ($x['color_name'] ?? 'Default'),
) ?></td>
        <td><?= e($x['sku']) ?></td>
        <td><?= (int) $x[
    'stock_quantity'
] ?></td>
        <td>
          <form class="row" method="post">
            <input type="hidden" name="csrf" value="<?= e(
    csrf_token(),
) ?>" /><input type="hidden" name="variant_id" value="<?= (int) $x[
    'variant_id'
] ?>" /><input
              type="number"
              min="1"
              name="quantity"
              placeholder="Qty"
            /><input name="reason" placeholder="Reason" /><button>Restock</button>
          </form>
        </td>
      </tr>
      <?php endforeach; ?>
      <?php if (!$list): ?>
      <tr><td colspan="4" class="empty-note">No active product variants to manage yet.</td></tr>
      <?php endif; ?>

    </tbody>
  </table>
</div>
<?php require __DIR__ . '/../includes/admin_footer.php'; ?>
