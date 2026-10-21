<?php
require_once __DIR__ . "/../includes/functions.php";
require_admin();
$error = "";
if ($_SERVER["REQUEST_METHOD"] === "POST") {
    csrf_check();
    try {
        if (($_POST["kind"] ?? "") === "category") {
            $n = trim($_POST["category_name"] ?? "");
            if (!$n) {
                throw new RuntimeException("Category name is required.");
            }
            $q = $pdo->prepare(
                "INSERT INTO product_categories(category_name,description,is_active) VALUES(?,?,1)",
            );
            $q->execute([$n, trim($_POST["description"] ?? "") ?: null]);
        } else {
            $n = trim($_POST["type_name"] ?? "");
            if (!$n) {
                throw new RuntimeException("Product type name is required.");
            }
            $q = $pdo->prepare(
                "INSERT INTO product_types(type_name) VALUES(?)",
            );
            $q->execute([$n]);
        }
        flash("Saved successfully.");
        redirect("/clothing-store-backup/admin/catalog.php");
    } catch (Throwable $e) {
        $error =
            $e instanceof RuntimeException
                ? $e->getMessage()
                : "Could not save. Check for a duplicate name.";
    }
}
$cats = $pdo
    ->query(
        "SELECT product_category_id,category_name FROM product_categories ORDER BY category_name",
    )
    ->fetchAll();
$types = $pdo
    ->query(
        "SELECT product_type_id,type_name FROM product_types ORDER BY type_name",
    )
    ->fetchAll();
$pageTitle = "Catalog";
require __DIR__ . "/../includes/admin_header.php";
?>

<h1 class="page-title">Product categories and types</h1>
<?php if ($error): ?>

<div class="notice error"><?= e($error) ?></div>
<?php endif; ?>

<div class="row">
  <form class="form-card" method="post">
    <h2>Add product category</h2>
    <input type="hidden" name="csrf" value="<?= e(
        csrf_token(),
    ) ?>" /><input type="hidden" name="kind" value="category" /><label>Name</label><input name="category_name" /><label>Description</label
    ><textarea name="description"></textarea><button>Add category</button>
  </form>
  <form class="form-card" method="post">
    <h2>Add product type</h2>
    <input type="hidden" name="csrf" value="<?= e(
        csrf_token(),
    ) ?>" /><input type="hidden" name="kind" value="type" /><label>Type name</label><input name="type_name" /><button>Add type</button>
  </form>
</div>
<h2>Current product categories</h2>
<?php if ($cats): ?>
<p><?= e(implode(", ", array_column($cats, "category_name"))) ?></p>
<?php else: ?>
<p class="empty-note">No categories yet. Add a category to start organizing products.</p>
<?php endif; ?>
<h2>Current types</h2>
<?php if ($types): ?>
<p><?= e(implode(", ", array_column($types, "type_name"))) ?></p>
<?php else: ?>
<p class="empty-note">No product types yet.</p>
<?php endif; ?>
<?php require __DIR__ . "/../includes/admin_footer.php"; ?>
