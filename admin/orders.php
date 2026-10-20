<?php
require_once __DIR__ . '/../includes/functions.php';
require_once __DIR__ . '/../includes/order_email.php';
require_admin();
$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_check();
    $id = (int) ($_POST['order_id'] ?? 0);
    $new = (int) ($_POST['status_id'] ?? 0);
    $pdo->beginTransaction();
    try {
        $s = $pdo->prepare(
            'SELECT order_status_id,order_number FROM orders WHERE order_id=? FOR UPDATE',
        );
        $s->execute([$id]);
        $old = $s->fetch();
        if (!$old) {
            throw new RuntimeException('Order not found.');
        }
        $oldId = (int) $old['order_status_id'];
        $oldName = $pdo->prepare('SELECT status_name FROM order_statuses WHERE order_status_id=?');
        $oldName->execute([$oldId]);
        $oldLabel = $oldName->fetchColumn();
        if ($oldLabel === 'Cancelled' && $new !== $oldId) {
            throw new RuntimeException('Cancelled orders cannot be reopened from this screen.');
        }
        $get = $pdo->prepare('SELECT status_name FROM order_statuses WHERE order_status_id=?');
        $get->execute([$new]);
        $newLabel = $get->fetchColumn();
        if (!$newLabel) {
            throw new RuntimeException('Choose a valid status.');
        }
        if ($new !== $oldId) {
            if ($newLabel === 'Cancelled' && $oldLabel !== 'Cancelled') {
                $lines = $pdo->prepare(
                    'SELECT variant_id,quantity FROM order_items WHERE order_id=? AND variant_id IS NOT NULL',
                );
                $lines->execute([$id]);
                foreach ($lines->fetchAll() as $line) {
                    $pdo->prepare(
                        'UPDATE product_variants SET stock_quantity=stock_quantity+? WHERE variant_id=?',
                    )->execute([$line['quantity'], $line['variant_id']]);
                    $pdo->prepare(
                        "INSERT INTO inventory_transactions(variant_id,changed_by,quantity_change,reason,reference_text) VALUES(?,?,?,'CANCELLATION',?)",
                    )->execute([
                        $line['variant_id'],
                        current_user()['id'],
                        $line['quantity'],
                        $old['order_number'],
                    ]);
                }
            }
            $pdo->prepare(
                'UPDATE orders SET order_status_id=?,updated_at=CURRENT_TIMESTAMP WHERE order_id=?',
            )->execute([$new, $id]);
            $hist = $pdo->prepare(
                'INSERT INTO order_status_history(order_id,order_status_id,changed_by,note) VALUES(?,?,?,?)',
            );
            $hist->execute([
                $id,
                $new,
                current_user()['id'],
                'Changed from ' . $oldLabel . ' to ' . $newLabel,
            ]);
        }
        $pdo->commit();
        try {
            send_order_status_email($pdo, $id);
        } catch (Throwable $mailError) {
            error_log('Order status email failed: ' . $mailError->getMessage());
        }
        flash('Order status updated.');
        redirect('/clothing-store-backup/admin/orders.php');
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        $error = $e instanceof RuntimeException ? $e->getMessage() : 'Could not update order.';
    }
}
$statuses = $pdo
    ->query('SELECT order_status_id,status_name FROM order_statuses ORDER BY order_status_id')
    ->fetchAll();
$orders = $pdo
    ->query(
        'SELECT o.order_id,o.order_number,o.total_amount,o.placed_at,os.status_name,u.first_name,u.last_name FROM orders o JOIN order_statuses os ON os.order_status_id=o.order_status_id JOIN users u ON u.user_id=o.user_id ORDER BY o.placed_at DESC',
    )
    ->fetchAll();
$pageTitle = 'Orders';
require __DIR__ . '/../includes/admin_header.php';
?>

<h1 class="page-title">Order management</h1>
<?php if ($error): ?>

<div class="notice error"><?= e(
    $error,
) ?></div>
<?php endif; ?>

<div class="table-wrap">
  <table>
    <thead>
      <tr>
        <th>Order</th>
        <th>Customer</th>
        <th>Date</th>
        <th>Total</th>
        <th>Status</th>
      </tr>
    </thead>
    <tbody>
      <?php foreach (
    $orders
    as $o
): ?>

      <tr>
        <td><?= e($o['order_number']) ?></td>
        <td><?= e(
    $o['first_name'] . ' ' . $o['last_name'],
) ?></td>
        <td><?= e($o['placed_at']) ?></td>
        <td>₱<?= number_format(
    (float) $o['total_amount'],
    2,
) ?></td>
        <td>
          <form class="row" method="post">
            <input type="hidden" name="csrf" value="<?= e(
    csrf_token(),
) ?>" /><input type="hidden" name="order_id" value="<?= (int) $o[
    'order_id'
] ?>" /><select name="status_id">
              <?php foreach ($statuses as $st): ?>

              <option value="<?= (int) $st[
    'order_status_id'
] ?>" <?= $o['status_name'] === $st['status_name'] ? 'selected' : '' ?>><?= e(
    $st['status_name'],
) ?></option>
              <?php endforeach; ?></select
            ><button>Save</button>
          </form>
        </td>
      </tr>
      <?php endforeach; ?>
      <?php if (!$orders): ?>
      <tr><td colspan="5" class="empty-note">No orders have been placed yet.</td></tr>
      <?php endif; ?>

    </tbody>
  </table>
</div>
<?php require __DIR__ . '/../includes/admin_footer.php'; ?>
