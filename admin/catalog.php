<?php
require_once __DIR__ . '/../includes/functions.php';
require_admin();
$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_check();
    try {
        if (($_POST['kind'] ?? '') === 'category') {
            $n = trim($_POST['category_name'] ?? '');
            if (!$n) {
                throw new RuntimeException('Category name is required.');
            }
            $q = $pdo->prepare(
                'INSERT INTO categories(category_name,description,is_active) VALUES(?,?,1)',
            );
            $q->execute([$n, trim($_POST['description'] ?? '') ?: null]);
        } else {
            $n = trim($_POST['type_name'] ?? '');
            $cid = (int) ($_POST['category_id'] ?? 0);
            if (!$n || !$cid) {
                throw new RuntimeException('Choose a category and enter a product type.');
            }
            $q = $pdo->prepare('INSERT INTO product_types(type_name,category_id) VALUES(?,?)');
            $q->execute([$n, $cid]);
        }
        flash('Saved successfully.');
        redirect('/clothing-store-backup/admin/catalog.php');
    } catch (Throwable $e) {
        $error =
            $e instanceof RuntimeException
                ? $e->getMessage()
                : 'Could not save. Check for a duplicate name.';
    }
}
$cats = $pdo
    ->query('SELECT category_id,category_name FROM categories ORDER BY category_name')
    ->fetchAll();
$types = $pdo
    ->query('SELECT product_type_id,type_name FROM product_types ORDER BY type_name')
    ->fetchAll();
$pageTitle = 'Catalog setup';
require __DIR__ . '/../includes/header.php';
?>

<h1 class="page-title">Categories and product types</h1>
<?php if (
    $error
): ?>

<div class="notice error"><?= e(
    $error,
) ?></div>
<?php endif; ?>

<div class="row">
  <form class="form-card" method="post">
    <h2>Add category</h2>
    <input type="hidden" name="csrf" value="<?= e(
    csrf_token(),
) ?>" /><input type="hidden" name="kind" value="category" /><label>Name</label><input name="category_name" /><label>Description</label
    ><textarea name="description"></textarea><button>Add category</button>
  </form>
  <form class="form-card" method="post">
    <h2>Add product type</h2>
    <input type="hidden" name="csrf" value="<?= e(
    csrf_token(),
) ?>" /><input type="hidden" name="kind" value="type" /><label>Category</label
    ><select name="category_id">
      <?php foreach (
    $cats
    as $c
): ?>

      <option value="<?= (int) $c['category_id'] ?>"><?= e(
    $c['category_name'],
) ?></option>
      <?php endforeach; ?></select
    ><label>Type name</label><input name="type_name" /><button>Add type</button>
  </form>
</div>
<h2>Current categories</h2>
<p><?= e(
    implode(', ', array_column($cats, 'category_name')),
) ?></p>
<h2>Current types</h2>
<p><?= e(
    implode(', ', array_column($types, 'type_name')),
) ?></p>
<?php require __DIR__ . '/../includes/footer.php'; ?>
