<?php
require_once __DIR__ . "/../includes/functions.php";
if (current_user()) {
    redirect(
        (current_user()["role"] ?? "") === "Admin"
            ? APP_BASE . "/admin/index.php"
            : APP_BASE . "/index.php",
    );
}
$error = "";
if ($_SERVER["REQUEST_METHOD"] === "POST") {
    csrf_check();
    $identifier = strtolower(
        trim(is_string($_POST["email"] ?? null) ? $_POST["email"] : ""),
    );
    $password = is_string($_POST["password"] ?? null)
        ? $_POST["password"]
        : "";

    if ($identifier === "" || !filter_var($identifier, FILTER_VALIDATE_EMAIL)) {
        $error = "Enter a valid email address.";
    } elseif ($password === "") {
        $error = "Enter your password.";
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
            password_verify($password, $u["password_hash"])
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
                    ? APP_BASE . "/admin/index.php"
                    : APP_BASE . "/index.php",
            );
        }
        $error = "Email or password is incorrect";
    }
}
$pageTitle = "Sign in";
require __DIR__ . "/../includes/header.php";
?>

<form class="form-card" method="post" novalidate>
  <div class="eyebrow">Welcome back</div>
  <h1 class="page-title">Sign in</h1>
  <?php if ($error): ?>
  <div class="notice error"><?= e($error) ?></div>
  <?php endif; ?><input type="hidden" name="csrf" value="<?= e(
    csrf_token(),
) ?>" /><label>Email address</label><input type="text" name="email" value="<?= e(
    $_POST["email"] ?? "",
) ?>" /><label>Password</label
  ><input type="password" name="password" /><button>Sign in</button>
  <p>New here? <a href="<?= APP_BASE ?>/user/register.php">Create an account</a></p>
</form>
<?php require __DIR__ . "/../includes/footer.php"; ?>
