<?php
require_once __DIR__ . "/../includes/functions.php";
require_admin();
$error = "";
if ($_SERVER["REQUEST_METHOD"] === "POST") {
    csrf_check();
    try {
        $action = $_POST["action"] ?? "";
        if ($action === "remove_category") {
            $categoryId = (int) ($_POST["product_category_id"] ?? 0);
            if ($categoryId < 1) {
                throw new RuntimeException("Select a valid product category.");
            }
            $q = $pdo->prepare(
                "SELECT COUNT(*) FROM products WHERE product_category_id=?",
            );
            $q->execute([$categoryId]);
            $productCount = (int) $q->fetchColumn();
            if ($productCount > 0) {
                throw new RuntimeException(
                    "This category has " .
                        $productCount .
                        " product(s). Move or remove them before removing the category.",
                );
            }
            $q = $pdo->prepare(
                "UPDATE product_categories SET is_active=? WHERE product_category_id=?",
            );
            $q->execute([0, $categoryId]);
            if ($q->rowCount() !== 1) {
                throw new RuntimeException(
                    "The category was already removed or could not be found.",
                );
            }
            flash("Product category removed from the catalog. Existing products were kept.");
            redirect("/clothing-store-backup/admin/catalog.php");
        } elseif ($action === "remove_type") {
            $typeId = (int) ($_POST["product_type_id"] ?? 0);
            if ($typeId < 1) {
                throw new RuntimeException("Select a valid product type.");
            }
            $q = $pdo->prepare(
                "SELECT COUNT(*) FROM products WHERE product_type_id=?",
            );
            $q->execute([$typeId]);
            $productCount = (int) $q->fetchColumn();
            if ($productCount > 0) {
                throw new RuntimeException(
                    "This type is used by " .
                        $productCount .
                        " product(s). Reassign those products before removing the type.",
                );
            }
            $q = $pdo->prepare(
                "DELETE FROM product_types WHERE product_type_id=?",
            );
            $q->execute([$typeId]);
            if ($q->rowCount() !== 1) {
                throw new RuntimeException(
                    "The type could not be found. Refresh the page and try again.",
                );
            }
            flash("Product type removed.");
            redirect("/clothing-store-backup/admin/catalog.php");
        } elseif (($_POST["kind"] ?? "") === "category") {
            $n = trim($_POST["category_name"] ?? "");
            if (!$n) {
                throw new RuntimeException("Category name is required.");
            }
            $q = $pdo->prepare(
                "INSERT INTO product_categories(category_name,description,is_active) VALUES(?,?,1)",
            );
            $q->execute([$n, trim($_POST["description"] ?? "") ?: null]);
        } elseif (($_POST["kind"] ?? "") === "type") {
            $n = trim($_POST["type_name"] ?? "");
            if (!$n) {
                throw new RuntimeException("Product type name is required.");
            }
            $q = $pdo->prepare(
                "INSERT INTO product_types(type_name) VALUES(?)",
            );
            $q->execute([$n]);
        } else {
            throw new RuntimeException("Choose a valid catalog action.");
        }
        flash("Saved successfully.");
        redirect("/clothing-store-backup/admin/catalog.php");
    } catch (RuntimeException $e) {
        $error = $e->getMessage();
    } catch (PDOException $e) {
        if ($e->getCode() === "23000") {
            $error =
                "This catalog entry is already in use or has a duplicate name.";
        } else {
            $error = "Could not update the catalog. Please try again.";
        }
    }
}
$cats = $pdo
    ->query(
        "SELECT pc.product_category_id,pc.category_name,COUNT(p.product_id) AS product_count
        FROM product_categories pc
        LEFT JOIN products p ON p.product_category_id=pc.product_category_id
        WHERE pc.is_active=1
        GROUP BY pc.product_category_id,pc.category_name
        ORDER BY pc.category_name",
    )
    ->fetchAll();
$types = $pdo
    ->query(
        "SELECT pt.product_type_id,pt.type_name,COUNT(p.product_id) AS product_count
        FROM product_types pt
        LEFT JOIN products p ON p.product_type_id=pt.product_type_id
        GROUP BY pt.product_type_id,pt.type_name
        ORDER BY pt.type_name",
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
<section class="card">
<h2>Product categories</h2>
<?php if ($cats): ?>
<table>
  <thead><tr><th>Category</th><th>Products</th><th>Action</th></tr></thead>
  <tbody>
    <?php foreach ($cats as $category): ?>
      <tr>
        <td><?= e($category["category_name"]) ?></td>
        <td><?= number_format((int) $category["product_count"]) ?></td>
        <td>
          <?php if ((int) $category["product_count"] === 0): ?>
            <form method="post" onsubmit="return confirm('Remove this category from the catalog?');">
              <input type="hidden" name="csrf" value="<?= e(csrf_token()) ?>">
              <input type="hidden" name="action" value="remove_category">
              <input type="hidden" name="product_category_id" value="<?= (int) $category[
                  "product_category_id"
              ] ?>">
              <button type="submit" class="secondary">Remove</button>
            </form>
          <?php else: ?>
            <span class="muted">Remove products first</span>
          <?php endif; ?>
        </td>
      </tr>
    <?php endforeach; ?>
  </tbody>
</table>
<?php else: ?>
<p class="empty-note">No categories yet. Add a category to start organizing products.</p>
<?php endif; ?>
<p class="empty-note">Categories can only be removed when they have no products.</p>
</section>

<section class="card">
<h2>Product types</h2>
<?php if ($types): ?>
<table>
  <thead><tr><th>Type</th><th>Products</th><th>Action</th></tr></thead>
  <tbody>
    <?php foreach ($types as $type): ?>
      <tr>
        <td><?= e($type["type_name"]) ?></td>
        <td><?= number_format((int) $type["product_count"]) ?></td>
        <td>
          <?php if ((int) $type["product_count"] === 0): ?>
            <form method="post" onsubmit="return confirm('Permanently remove this unused product type?');">
              <input type="hidden" name="csrf" value="<?= e(csrf_token()) ?>">
              <input type="hidden" name="action" value="remove_type">
              <input type="hidden" name="product_type_id" value="<?= (int) $type[
                  "product_type_id"
              ] ?>">
              <button type="submit" class="secondary">Remove</button>
            </form>
          <?php else: ?>
            <span class="muted">Reassign products first</span>
          <?php endif; ?>
        </td>
      </tr>
    <?php endforeach; ?>
  </tbody>
</table>
<?php else: ?>
<p class="empty-note">No product types yet.</p>
<?php endif; ?>
</section>
<?php require __DIR__ . "/../includes/admin_footer.php"; ?>
