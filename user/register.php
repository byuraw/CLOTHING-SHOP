<?php
require_once __DIR__ . "/../includes/functions.php";
if (current_user()) {
    redirect(APP_BASE . "/index.php");
}
$error = "";
if ($_SERVER["REQUEST_METHOD"] === "POST") {
    csrf_check();
    $first = trim($_POST["first_name"] ?? "");
    $last = trim($_POST["last_name"] ?? "");
    $email = strtolower(trim($_POST["email"] ?? ""));
    $password = $_POST["password"] ?? "";
    $phone = trim($_POST["phone"] ?? "");
    if (
        $first === "" ||
        $last === "" ||
        !filter_var($email, FILTER_VALIDATE_EMAIL) ||
        strlen($password) < 8
    ) {
        $error =
            "Enter your name, a valid email, and a password of at least 8 characters.";
    } else {
        try {
            $st = $pdo
                ->query(
                    "SELECT status_id FROM account_statuses WHERE status_name='Active'",
                )
                ->fetchColumn();
            $photo = upload_image($_FILES["profile_photo"] ?? [], "profiles");
            $q = $pdo->prepare(
                "INSERT INTO users(first_name,last_name,email,password_hash,phone,profile_photo,role_name,status_id) VALUES(?,?,?,?,?,?,?,?)",
            );
            $q->execute([
                $first,
                $last,
                $email,
                password_hash($password, PASSWORD_DEFAULT),
                $phone ?: null,
                $photo,
                "Customer",
                $st,
            ]);
            flash("Account created. You can now sign in.");
            redirect(APP_BASE . "/user/login.php");
        } catch (PDOException $e) {
            $error =
                $e->getCode() === "23000"
                    ? "That email already has an account."
                    : "Registration could not be completed. Check database setup.";
        }
    }
}
$pageTitle = "Create account";
require __DIR__ . "/../includes/header.php";
?>

<form class="form-card" method="post" enctype="multipart/form-data">
  <div class="eyebrow">Customer account</div>
  <h1 class="page-title">Create your account</h1>
  <?php if ($error): ?>
  <div class="notice error"><?= e($error) ?></div>
  <?php endif; ?><input type="hidden" name="csrf" value="<?= e(
    csrf_token(),
) ?>" /><label>First name</label><input name="first_name" value="<?= e(
    $_POST["first_name"] ?? "",
) ?>" /><label>Last name</label
  ><input name="last_name" value="<?= e(
      $_POST["last_name"] ?? "",
  ) ?>" /><label>Email</label><input type="email" name="email" value="<?= e(
    $_POST["email"] ?? "",
) ?>" /><label>Phone (optional)</label
  ><input name="phone" value="<?= e(
      $_POST["phone"] ?? "",
  ) ?>" /><label>Profile photo (optional)</label><input type="file" name="profile_photo" accept="image/jpeg,image/png,image/webp,image/gif" /><label
    >Password</label
  ><input type="password" name="password" /><button>Create account</button>
  <p>Already registered? <a href="<?= APP_BASE ?>/user/login.php">Sign in</a></p>
</form>
<?php require __DIR__ . "/../includes/footer.php"; ?>
