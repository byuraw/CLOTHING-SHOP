<?php
require_once __DIR__ . '/../includes/functions.php';
if (current_user()) {
    redirect('/clothing-store-backup/index.php');
}
$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_check();
    $email = strtolower(trim($_POST['email'] ?? ''));
    if (!filter_var($email, FILTER_VALIDATE_EMAIL) || trim($_POST['password'] ?? '') === '') {
        $error = 'Enter a valid email and password.';
    } else {
        $q = $pdo->prepare(
            'SELECT u.user_id,u.first_name,u.last_name,u.email,u.password_hash,r.role_name,s.status_name FROM users u JOIN roles r ON r.role_id=u.role_id JOIN account_statuses s ON s.status_id=u.status_id WHERE u.email=?',
        );
        $q->execute([$email]);
        $u = $q->fetch();
        if (
            $u &&
            $u['status_name'] === 'Active' &&
            password_verify($_POST['password'] ?? '', $u['password_hash'])
        ) {
            session_regenerate_id(true);
            $_SESSION['user'] = [
                'id' => (int) $u['user_id'],
                'name' => $u['first_name'],
                'email' => $u['email'],
                'role' => $u['role_name'],
            ];
            flash('Welcome back, ' . $u['first_name'] . '.');
            redirect('/clothing-store-backup/index.php');
        }
        $error = 'Email or password is incorrect, or the account is inactive.';
    }
}
$pageTitle = 'Sign in';
require __DIR__ . '/../includes/header.php';
?>

<form class="form-card" method="post">
  <div class="eyebrow">Welcome back</div>
  <h1 class="page-title">Sign in</h1>
  <?php if (
    $error
): ?>
  <div class="notice error"><?= e(
    $error,
) ?></div>
  <?php endif; ?><input type="hidden" name="csrf" value="<?= e(
    csrf_token(),
) ?>" /><label>Email address</label><input type="text" name="email" value="<?= e(
    $_POST['email'] ?? '',
) ?>" /><label>Password</label
  ><input type="password" name="password" /><button>Sign in</button>
  <p>New here? <a href="/clothing-store-backup/user/register.php">Create an account</a></p>
</form>
<?php require __DIR__ .
    '/../includes/footer.php'; ?>
