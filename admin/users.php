<?php
require_once __DIR__ . '/../includes/functions.php';
require_admin();
$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_check();
    $id = (int) ($_POST['user_id'] ?? 0);
    $action = $_POST['action'] ?? '';
    if ($id === current_user()['id']) {
        $error = 'You cannot change your own account here.';
    } else {
        try {
            if ($action === 'status') {
                $status = (int) ($_POST['status_id'] ?? 0);
                $s = $pdo->prepare('UPDATE users SET status_id=? WHERE user_id=?');
                $s->execute([$status, $id]);
                flash('User status updated.');
            } elseif ($action === 'role') {
                $role = (int) ($_POST['role_id'] ?? 0);
                $s = $pdo->prepare('UPDATE users SET role_id=? WHERE user_id=?');
                $s->execute([$role, $id]);
                flash('User role updated.');
            }
            redirect(APP_BASE . '/admin/users.php');
        } catch (Throwable $e) {
            $error = 'Could not update the user.';
        }
    }
}
$users = $pdo
    ->query(
        'SELECT u.user_id,u.first_name,u.last_name,u.email,u.created_at,u.status_id,u.role_id,s.status_name,r.role_name FROM users u JOIN account_statuses s ON s.status_id=u.status_id JOIN roles r ON r.role_id=u.role_id ORDER BY u.created_at DESC',
    )
    ->fetchAll();
$roles = $pdo->query('SELECT role_id,role_name FROM roles ORDER BY role_name')->fetchAll();
$statuses = $pdo
    ->query('SELECT status_id,status_name FROM account_statuses ORDER BY status_name')
    ->fetchAll();
$pageTitle = 'Customers';
require __DIR__ . '/../includes/admin_header.php';
?>

<h1 class="page-title">Users</h1>
<?php if ($error): ?>

<div class="notice error"><?= e(
    $error,
) ?></div>
<?php endif; ?>

<div class="table-wrap">
  <table>
    <thead>
      <tr>
        <th>Name</th>
        <th>Email</th>
        <th>Role</th>
        <th>Status</th>
        <th>Joined</th>
        <th>Actions</th>
      </tr>
    </thead>
    <tbody>
      <?php foreach (
    $users
    as $u
): ?>

      <tr>
        <td><?= e($u['first_name'] . ' ' . $u['last_name']) ?></td>
        <td><?= e(
    $u['email'],
) ?></td>
        <td>
          <form method="post">
            <input type="hidden" name="csrf" value="<?= e(
    csrf_token(),
) ?>" /><input type="hidden" name="user_id" value="<?= (int) $u[
    'user_id'
] ?>" /><input type="hidden" name="action" value="role" /><select
              name="role_id"
            >
              <?php foreach (
    $roles
    as $r
): ?>

              <option value="<?= (int) $r['role_id'] ?>" <?= (int) $u['role_id'] === (int) $r['role_id']
    ? 'selected'
    : '' ?>><?= e(
    $r['role_name'],
) ?></option>
              <?php endforeach; ?></select
            ><button>Save role</button>
          </form>
        </td>
        <td><?= e(
    $u['status_name'],
) ?></td>
        <td><?= e(
    $u['created_at'],
) ?></td>
        <td>
          <form method="post">
            <input type="hidden" name="csrf" value="<?= e(
    csrf_token(),
) ?>" /><input type="hidden" name="user_id" value="<?= (int) $u[
    'user_id'
] ?>" /><input type="hidden" name="action" value="status" /><select
              name="status_id"
            >
              <?php foreach (
    $statuses
    as $st
): ?>

              <option value="<?= (int) $st['status_id'] ?>" <?= (int) $u['status_id'] ===
(int) $st['status_id']
    ? 'selected'
    : '' ?>><?= e(
    $st['status_name'],
) ?></option>
              <?php endforeach; ?></select
            ><button>Save status</button>
          </form>
        </td>
      </tr>
      <?php endforeach; ?>
      <?php if (!$users): ?>
      <tr><td colspan="6" class="empty-note">No customer accounts found.</td></tr>
      <?php endif; ?>

    </tbody>
  </table>
</div>
<?php require __DIR__ . '/../includes/admin_footer.php'; ?>
