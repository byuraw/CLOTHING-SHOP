<?php
require_once __DIR__ . '/../includes/functions.php';
require_login();
$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_check();
    if (($_POST['action'] ?? '') === 'delete') {
        $q = $pdo->prepare('DELETE FROM addresses WHERE address_id=? AND user_id=?');
        $q->execute([(int) ($_POST['address_id'] ?? 0), current_user()['id']]);
        flash('Address removed.');
        redirect('/clothing-store-backup/user/addresses.php');
    }
    $keys = ['recipient_name', 'phone', 'address_line1', 'city', 'province', 'postal_code'];
    $values = [];
    foreach ($keys as $k) {
        $values[] = trim($_POST[$k] ?? '');
    }
    if (in_array('', $values, true)) {
        $error = 'Complete all address fields.';
    } else {
        try {
            $q = $pdo->prepare(
                'INSERT INTO addresses(user_id,recipient_name,phone,address_line1,city,province,postal_code,is_default) VALUES(?,?,?,?,?,?,?,0)',
            );
            $q->execute(array_merge([current_user()['id']], $values));
            flash('Address saved.');
            redirect('/clothing-store-backup/user/addresses.php');
        } catch (Throwable $e) {
            $error = 'Could not save the address.';
        }
    }
}
$q = $pdo->prepare(
    'SELECT address_id,recipient_name,phone,address_line1,city,province,postal_code FROM addresses WHERE user_id=? ORDER BY address_id DESC',
);
$q->execute([current_user()['id']]);
$addresses = $q->fetchAll();
$pageTitle = 'My addresses';
require __DIR__ . '/../includes/header.php';
?>

<h1 class="page-title">My addresses</h1>
<?php if ($error): ?>
<div class="notice error"><?= e(
    $error,
) ?></div>
<?php endif; ?>
<div class="grid">
  <?php foreach (
    $addresses
    as $a
): ?>
  <article class="card">
    <b><?= e($a['recipient_name']) ?></b>
    <p><?= e($a['phone']) ?><br /><?= e(
    $a['address_line1'],
) ?><br /><?= e(
    $a['city'] . ', ' . $a['province'] . ' ' . $a['postal_code'],
) ?></p>
    <form method="post">
      <input type="hidden" name="csrf" value="<?= e(
    csrf_token(),
) ?>" /><input type="hidden" name="action" value="delete" /><input type="hidden" name="address_id" value="<?= (int) $a[
    'address_id'
] ?>" /><button>
        Remove
      </button>
    </form>
  </article>
  <?php endforeach; ?>
</div>
<form class="form-card" method="post">
  <h2>Add address</h2>
  <input type="hidden" name="csrf" value="<?= e(
    csrf_token(),
) ?>" /><?php foreach (
    [
        'recipient_name' => 'Recipient name',
        'phone' => 'Phone',
        'address_line1' => 'Address',
        'city' => 'City',
        'province' => 'Province',
        'postal_code' => 'Postal code',
    ]
    as $key => $label
): ?><label><?= e($label) ?></label><input name="<?= e(
    $key,
) ?>" /><?php endforeach; ?><button>Save address</button>
</form>
<?php require __DIR__ .
    '/../includes/footer.php'; ?>
