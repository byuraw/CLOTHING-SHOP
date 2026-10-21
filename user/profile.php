<?php
require_once __DIR__ . '/../includes/functions.php';
require_login();
$error = '';
$q = $pdo->prepare(
    'SELECT first_name,last_name,email,phone,profile_photo FROM users WHERE user_id=?',
);
$q->execute([current_user()['id']]);
$profile = $q->fetch();
$addressQuery = $pdo->prepare(
    'SELECT address_id,recipient_name,phone,address_line1,city,province,postal_code
    FROM addresses WHERE user_id=? ORDER BY is_default DESC,address_id DESC LIMIT 1',
);
$addressQuery->execute([current_user()['id']]);
$deliveryAddress = $addressQuery->fetch() ?: [];
$addressFields = [
    'recipient_name',
    'phone',
    'address_line1',
    'city',
    'province',
    'postal_code',
];
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_check();
    $first = trim($_POST['first_name'] ?? '');
    $last = trim($_POST['last_name'] ?? '');
    $phone = trim($_POST['phone'] ?? '');
    $email = strtolower(trim($_POST['email'] ?? ''));
    $submittedAddress = [];
    foreach ($addressFields as $field) {
        $submittedAddress[$field] = trim($_POST[$field] ?? '');
    }
    $hasAddress = count(array_filter($submittedAddress, static fn($value) => $value !== '')) > 0;
    $addressComplete = !in_array('', $submittedAddress, true);
    if ($hasAddress) {
        $deliveryAddress = array_merge($deliveryAddress, $submittedAddress);
    }
    if ($first === '' || $last === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
        $error = 'Enter a first name, last name, and valid email.';
    } elseif ($hasAddress && !$addressComplete) {
        $error = 'Complete every delivery address field, or leave them all blank.';
    } else {
        try {
            $photo = upload_image($_FILES['profile_photo'] ?? [], 'profiles');
            $sql =
                'UPDATE users SET first_name=?,last_name=?,email=?,phone=?' .
                ($photo ? ',profile_photo=?' : '') .
                ' WHERE user_id=?';
            $st = $pdo->prepare($sql);
            $args = [$first, $last, $email, $phone ?: null];
            if ($photo) {
                $args[] = $photo;
            }
            $args[] = current_user()['id'];
            $pdo->beginTransaction();
            $st->execute($args);
            if ($hasAddress) {
                $pdo->prepare('UPDATE addresses SET is_default=0 WHERE user_id=?')
                    ->execute([current_user()['id']]);
                if (!empty($deliveryAddress['address_id'])) {
                    $saveAddress = $pdo->prepare(
                        'UPDATE addresses
                        SET recipient_name=?,phone=?,address_line1=?,city=?,province=?,postal_code=?,is_default=1
                        WHERE address_id=? AND user_id=?',
                    );
                    $saveAddress->execute([
                        $submittedAddress['recipient_name'],
                        $submittedAddress['phone'],
                        $submittedAddress['address_line1'],
                        $submittedAddress['city'],
                        $submittedAddress['province'],
                        $submittedAddress['postal_code'],
                        $deliveryAddress['address_id'],
                        current_user()['id'],
                    ]);
                } else {
                    $saveAddress = $pdo->prepare(
                        'INSERT INTO addresses(user_id,recipient_name,phone,address_line1,city,province,postal_code,is_default)
                        VALUES(?,?,?,?,?,?,?,1)',
                    );
                    $saveAddress->execute([
                        current_user()['id'],
                        $submittedAddress['recipient_name'],
                        $submittedAddress['phone'],
                        $submittedAddress['address_line1'],
                        $submittedAddress['city'],
                        $submittedAddress['province'],
                        $submittedAddress['postal_code'],
                    ]);
                }
            }
            $pdo->commit();
            $_SESSION['user']['name'] = $first;
            $_SESSION['user']['email'] = $email;
            flash($hasAddress ? 'Profile and delivery address updated.' : 'Profile updated.');
            redirect(APP_BASE . '/user/profile.php');
        } catch (Throwable $ex) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            $error =
                $ex instanceof RuntimeException
                    ? $ex->getMessage()
                    : 'Could not update profile. The email may already be in use.';
        }
    }
}
$pageTitle = 'My profile';
require __DIR__ . '/../includes/header.php';
?>

<h1 class="page-title">My profile</h1>
<?php if ($error): ?>
<div class="notice error"><?= e(
    $error,
) ?></div>
<?php endif; ?>

<form class="form-card" method="post" enctype="multipart/form-data">
  <input type="hidden" name="csrf" value="<?= e(
    csrf_token(),
) ?>" /><label>First name</label><input name="first_name" value="<?= e(
    $profile['first_name'],
) ?>" /><label>Last name</label
  ><input name="last_name" value="<?= e(
    $profile['last_name'],
) ?>" /><label>Email</label><input name="email" value="<?= e(
    $profile['email'],
) ?>" /><label>Phone</label><input name="phone" value="<?= e(
    $profile['phone'] ?? '',
) ?>" /><label
    >Profile photo (JPG, PNG, WEBP, GIF; max 5 MB)</label
  ><input type="file" name="profile_photo" accept="image/jpeg,image/png,image/webp,image/gif" /><?php if (
    $profile['profile_photo']
): ?>
  <p><img style="max-width: 140px; border-radius: 50%" src="<?= APP_BASE .
    '/' .
    e(
        $profile['profile_photo'],
    ) ?>" alt="Profile photo" /></p>
  <?php endif; ?>
  <h2>Delivery address</h2>
  <p>This address will be filled in automatically at checkout. You can change it for an individual order.</p>
  <?php foreach (
    [
        'recipient_name' => 'Recipient name',
        'phone' => 'Delivery phone',
        'address_line1' => 'Address',
        'city' => 'City',
        'province' => 'Province',
        'postal_code' => 'Postal code',
    ]
    as $key => $label
): ?><label><?= e($label) ?></label><input name="<?= e(
    $key,
) ?>" value="<?= e($deliveryAddress[$key] ?? '') ?>" /><?php endforeach; ?>
  <button>Save profile</button>
</form>
<p><a class="button secondary" href="<?= APP_BASE ?>/user/addresses.php">Manage addresses</a> <a class="button secondary" href="<?= APP_BASE ?>/orders.php">View order history</a></p>
<?php require __DIR__ .
    '/../includes/footer.php'; ?>
