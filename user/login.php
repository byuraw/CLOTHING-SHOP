<?php
require_once __DIR__ . "/../includes/functions.php";
if (current_user()) {
    redirect(
        (current_user()["role"] ?? "") === "Admin"
            ? "/clothing-store-backup/admin/index.php"
            : "/clothing-store-backup/index.php",
    );
}
$error = "";
if ($_SERVER["REQUEST_METHOD"] === "POST") {
    csrf_check();
    $identifier = strtolower(trim($_POST["email"] ?? ""));

    if ($identifier === "" || trim($_POST["password"] ?? "") === "") {
        $error = "Enter your email address and password.";
    } else {
        $q = $pdo->prepare(
            'SELECT u.user_id,u.first_name,u.last_name,u.email,u.password_hash,u.role_name,s.status_name
            FROM users u 
            JOIN account_statuses s ON s.status_id=u.status_id 
            WHERE u.email=?',
        );
        $q->execute([$identifier]);
        $u = $q->fetch();
        if (
            $u &&
            $u["status_name"] === "Active" &&
            password_verify($_POST["password"] ?? "", $u["password_hash"])
        ) {
            session_regenerate_id(true);
            $_SESSION["user"] = [
                "id" => (int) $u["user_id"],
                "name" => $u["first_name"],
                "email" => $u["email"],
                "role" => $u["role_name"],
            ];
            flash("Welcome back, " . $u["first_name"] . ".");
            redirect(
                $u["role_name"] === "Admin"
                    ? "/clothing-store-backup/admin/index.php"
                    : "/clothing-store-backup/index.php",
            );
        }
        $error = "Email or password is incorrect, or the account is inactive.";
    }
}
$pageTitle = "Sign in";
require __DIR__ . "/../includes/header.php";
?>

<form class="form-card" method="post">
  <div class="eyebrow">Welcome back</div>
  <h1 class="page-title">Sign in</h1>
  <?php if ($error): ?>
  <div class="notice error"><?= e($error) ?></div>
  <?php endif; ?><input type="hidden" name="csrf" value="<?= e(
    csrf_token(),
) ?>" /><label>Email address</label><input type="email" name="email" value="<?= e(
    $_POST["email"] ?? "",
) ?>" /><label>Password</label
  ><input type="password" name="password" /><button>Sign in</button>
  <p>New here? <a href="/clothing-store-backup/user/register.php">Create an account</a></p>
</form>
<?php require __DIR__ . "/../includes/footer.php"; ?>
