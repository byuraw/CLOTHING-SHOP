<?php
require_once __DIR__ . '/../includes/functions.php';
require_admin();
$error = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_check();
    try {
        $action = $_POST['action'] ?? '';
        if ($action === 'images') {
            $pid = (int) ($_POST['product_id'] ?? 0);
            if (!$pid) {
                throw new RuntimeException('Select a product.');
            }
            $count = 0;
            foreach ($_FILES['photos']['name'] ?? [] as $idx => $unused) {
                $one = [
                    'name' => $_FILES['photos']['name'][$idx],
                    'type' => $_FILES['photos']['type'][$idx],
                    'tmp_name' => $_FILES['photos']['tmp_name'][$idx],
                    'error' => $_FILES['photos']['error'][$idx],
                    'size' => $_FILES['photos']['size'][$idx],
                ];
                $path = upload_image($one, 'products');
                if ($path) {
                    $q = $pdo->prepare(
                        'INSERT INTO product_images(product_id,image_path,alt_text,sort_order) VALUES(?,?,?,?)',
                    );
                    $q->execute([$pid, $path, trim($_POST['alt_text'] ?? ''), $count++]);
                }
            }
            flash($count ? 'Product photos uploaded.' : 'Choose at least one photo.');
        } elseif ($action === 'product') {
            $name = trim($_POST['product_name'] ?? '');
            $categoryId = (int) ($_POST['product_category_id'] ?? 0);
            $price = filter_var($_POST['base_price'] ?? null, FILTER_VALIDATE_FLOAT);
            $slug =
                strtolower(trim(preg_replace('/[^a-z0-9]+/i', '-', $name), '-')) .
                '-' .
                bin2hex(random_bytes(2));
            if (!$name || !$categoryId || $price === false || $price < 0) {
                throw new RuntimeException('Enter product name, product category, and valid price.');
            }
            $typeValue = trim((string) ($_POST['product_type_id'] ?? ''));
            $typeId = $typeValue === ''
                ? null
                : filter_var($typeValue, FILTER_VALIDATE_INT);
            if ($typeId === false || $typeId === null || $typeId < 1) {
                throw new RuntimeException('Choose a product type.');
            }
            $typeCheck = $pdo->prepare('SELECT COUNT(*) FROM product_types WHERE product_type_id=?');
            $typeCheck->execute([$typeId]);
            if (!$typeCheck->fetchColumn()) {
                throw new RuntimeException('Choose a valid product type.');
            }
            $catalogInfo = $pdo->prepare(
                'SELECT category_name,type_name
                FROM product_categories
                JOIN product_types ON product_type_id=?
                WHERE product_category_id=? AND is_active=1',
            );
            $catalogInfo->execute([$typeId, $categoryId]);
            $catalogInfo = $catalogInfo->fetch();
            if (!$catalogInfo) {
                throw new RuntimeException('Choose a valid product category and type.');
            }
            clothing_sku($catalogInfo['category_name'], $catalogInfo['type_name'], $name, null, null);
            $q = $pdo->prepare(
                'INSERT INTO products(product_category_id,product_type_id,product_name,slug,description,base_price,is_active) VALUES(?,?,?,?,?,?,1)',
            );
            $q->execute([
                $categoryId,
                $typeId,
                $name,
                $slug,
                trim($_POST['description'] ?? ''),
                $price,
            ]);
            $newPid = (int) $pdo->lastInsertId();
            $count = 0;
            foreach ($_FILES['photos']['name'] ?? [] as $idx => $unused) {
                $one = [
                    'name' => $_FILES['photos']['name'][$idx],
                    'type' => $_FILES['photos']['type'][$idx],
                    'tmp_name' => $_FILES['photos']['tmp_name'][$idx],
                    'error' => $_FILES['photos']['error'][$idx],
                    'size' => $_FILES['photos']['size'][$idx],
                ];
                $path = upload_image($one, 'products');
                if ($path) {
                    $im = $pdo->prepare(
                        'INSERT INTO product_images(product_id,image_path,alt_text,sort_order) VALUES(?,?,?,?)',
                    );
                    $im->execute([$newPid, $path, $name, $count++]);
                }
            }
            flash('Product created. Add at least one variant below.');
        } elseif ($action === 'edit') {
            $pid = (int) ($_POST['product_id'] ?? 0);
            $name = trim($_POST['product_name'] ?? '');
            $categoryId = (int) ($_POST['product_category_id'] ?? 0);
            $typeId = filter_var($_POST['product_type_id'] ?? null, FILTER_VALIDATE_INT);
            $price = filter_var($_POST['base_price'] ?? null, FILTER_VALIDATE_FLOAT);
            if (
                !$pid ||
                $name === '' ||
                !$categoryId ||
                $typeId === false ||
                $typeId < 1 ||
                $price === false ||
                $price < 0
            ) {
                throw new RuntimeException('Enter a product name, category, type, and valid price.');
            }
            $slug =
                strtolower(trim(preg_replace('/[^a-z0-9]+/i', '-', $name), '-')) .
                '-' .
                bin2hex(random_bytes(3));
            $catalogInfo = $pdo->prepare(
                'SELECT category_name,type_name
                FROM product_categories
                JOIN product_types ON product_type_id=?
                WHERE product_category_id=? AND is_active=1',
            );
            $catalogInfo->execute([$typeId, $categoryId]);
            $catalogInfo = $catalogInfo->fetch();
            if (!$catalogInfo) {
                throw new RuntimeException('Choose a valid product category and type.');
            }
            clothing_sku($catalogInfo['category_name'], $catalogInfo['type_name'], $name, null, null);
            $pdo->beginTransaction();
            try {
                $q = $pdo->prepare(
                    'UPDATE products SET product_category_id=?,product_type_id=?,product_name=?,slug=?,description=?,base_price=? WHERE product_id=?',
                );
                $q->execute([$categoryId, $typeId, $name, $slug, trim($_POST['description'] ?? ''), $price, $pid]);
                $variants = $pdo->prepare(
                    'SELECT variant_id,size_id,color_id FROM product_variants WHERE product_id=?',
                );
                $variants->execute([$pid]);
                $saveSku = $pdo->prepare('UPDATE product_variants SET sku=? WHERE variant_id=?');
                foreach ($variants->fetchAll() as $variant) {
                    $sku = clothing_sku(
                        $catalogInfo['category_name'],
                        $catalogInfo['type_name'],
                        $name,
                        $variant['size_id'] === null ? null : (int) $variant['size_id'],
                        $variant['color_id'] === null ? null : (int) $variant['color_id'],
                    );
                    $saveSku->execute([$sku, $variant['variant_id']]);
                }
                $pdo->commit();
            } catch (Throwable $e) {
                if ($pdo->inTransaction()) {
                    $pdo->rollBack();
                }
                throw $e;
            }
            flash('Product updated.');
        } elseif ($action === 'variant') {
            $pid = (int) ($_POST['product_id'] ?? 0);
            $price = filter_var($_POST['price'] ?? null, FILTER_VALIDATE_FLOAT);
            $stock = max(0, (int) ($_POST['stock_quantity'] ?? 0));
            if (!$pid || $price === false || $price < 0) {
                throw new RuntimeException('Select a product and enter a valid price.');
            }
            $product = $pdo->prepare(
                'SELECT p.product_name,pc.category_name,pt.type_name FROM products p JOIN product_categories pc ON pc.product_category_id=p.product_category_id JOIN product_types pt ON pt.product_type_id=p.product_type_id WHERE p.product_id=? AND p.is_active=1',
            );
            $product->execute([$pid]);
            $product = $product->fetch();
            if (!$product) {
                throw new RuntimeException('Choose a valid product.');
            }
            $sizeValue = trim((string) ($_POST['size_id'] ?? ''));
            $colorValue = trim((string) ($_POST['color_id'] ?? ''));
            $sizeId = $sizeValue === '' ? null : filter_var($sizeValue, FILTER_VALIDATE_INT);
            $colorId = $colorValue === '' ? null : filter_var($colorValue, FILTER_VALIDATE_INT);
            if (
                $sizeId === false ||
                ($sizeId !== null && $sizeId < 1) ||
                $colorId === false ||
                ($colorId !== null && $colorId < 1)
            ) {
                throw new RuntimeException('Choose valid size and color options.');
            }
            $sku = clothing_sku(
                $product['category_name'],
                $product['type_name'],
                $product['product_name'],
                $sizeId,
                $colorId,
            );
            $q = $pdo->prepare(
                'INSERT INTO product_variants(product_id,size_id,color_id,sku,price,stock_quantity,is_active) VALUES(?,?,?,?,?,?,1)',
            );
            $q->execute([
                $pid,
                $sizeId,
                $colorId,
                $sku,
                $price,
                $stock,
            ]);
            $variantId = (int) $pdo->lastInsertId();
            if ($stock > 0) {
                $i = $pdo->prepare(
                    "INSERT INTO inventory_transactions(variant_id,changed_by,quantity_change,reference_text) VALUES(?,?,?,'Initial variant stock')",
                );
                $i->execute([$variantId, current_user()['id'], $stock]);
            }
            flash('Variant created.');
        } elseif ($action === 'archive') {
            $q = $pdo->prepare('UPDATE products SET is_active=0 WHERE product_id=?');
            $q->execute([(int) $_POST['product_id']]);
            flash('Product archived.');
        }
        redirect('/clothing-store-backup/admin/products.php');
    } catch (Throwable $e) {
        $error =
            $e instanceof RuntimeException
                ? $e->getMessage()
                : 'Could not save. Check duplicate SKU and database setup.';
    }
}
$cats = $pdo
    ->query(
        'SELECT product_category_id,category_name FROM product_categories WHERE is_active=1 ORDER BY category_name',
    )
    ->fetchAll();
$types = $pdo
    ->query('SELECT product_type_id,type_name FROM product_types ORDER BY type_name')
    ->fetchAll();
$products = $pdo
    ->query('SELECT product_id,product_name FROM products WHERE is_active=1 ORDER BY product_name')
    ->fetchAll();
$sizes = $pdo->query('SELECT size_id,size_name FROM sizes ORDER BY size_id')->fetchAll();
$colors = $pdo->query('SELECT color_id,color_name FROM colors ORDER BY color_name')->fetchAll();
$list = $pdo
    ->query(
        'SELECT p.product_id,p.product_name,p.description,p.product_category_id,p.product_type_id,p.base_price,pc.category_name,pt.type_name,(SELECT COUNT(*) FROM product_variants v WHERE v.product_id=p.product_id AND v.is_active=1) variants FROM products p JOIN product_categories pc ON pc.product_category_id=p.product_category_id JOIN product_types pt ON pt.product_type_id=p.product_type_id WHERE p.is_active=1 ORDER BY p.created_at DESC',
    )
    ->fetchAll();
$pageTitle = 'Products';
require __DIR__ . '/../includes/admin_header.php';
?>

<h1 class="page-title">Products</h1>
<?php if ($error): ?>

<div class="notice error"><?= e(
    $error,
) ?></div>
<?php endif; ?>

<div class="row">
  <form class="form-card" method="post" enctype="multipart/form-data">
    <h2>New product</h2>
    <input type="hidden" name="csrf" value="<?= e(
    csrf_token(),
) ?>" /><input type="hidden" name="action" value="product" /><label>Name</label><input name="product_name" /><label>Product category</label
    ><select name="product_category_id">
      <?php foreach (
    $cats
    as $c
): ?>

      <option value="<?= (int) $c['product_category_id'] ?>"><?= e(
    $c['category_name'],
) ?></option>
      <?php endforeach; ?></select
    ><label>Type</label
    ><select name="product_type_id">
      <option value="">Choose a type</option>
      <?php foreach (
    $types
    as $t
): ?>

      <option value="<?= (int) $t['product_type_id'] ?>"><?= e(
    $t['type_name'],
) ?></option>
      <?php endforeach; ?></select
    ><label>Base price</label><input name="base_price" type="number" min="0" step=".01" /><label>Description</label><textarea name="description"></textarea
    ><label>Product photos (select multiple)</label><input type="file" name="photos[]" multiple accept="image/jpeg,image/png,image/webp,image/gif" /><button>Create product</button>
  </form>
  <form class="form-card" method="post">
    <h2>Add size/color variant</h2>
    <input type="hidden" name="csrf" value="<?= e(
    csrf_token(),
) ?>" /><input type="hidden" name="action" value="variant" /><label>Product</label
    ><select name="product_id">
      <?php foreach (
    $products
    as $p
): ?>

      <option value="<?= (int) $p['product_id'] ?>"><?= e(
    $p['product_name'],
) ?></option>
      <?php endforeach; ?></select
    ><label>SKU</label><p class="muted">Generated automatically from product, size, and color.</p><label>Size</label
    ><select name="size_id">
      <option value="">N/A</option>
      <?php foreach (
    $sizes
    as $s
): ?>

      <option value="<?= (int) $s['size_id'] ?>"><?= e(
    $s['size_name'],
) ?></option>
      <?php endforeach; ?></select
    ><label>Color</label
    ><select name="color_id">
      <option value="">N/A</option>
      <?php foreach (
    $colors
    as $c
): ?>

      <option value="<?= (int) $c['color_id'] ?>"><?= e(
    $c['color_name'],
) ?></option>
      <?php endforeach; ?></select
    ><label>Price</label><input name="price" type="number" min="0" step=".01" /><label>Starting stock</label><input name="stock_quantity" type="number" min="0" value="0" /><button>Add variant</button>
  </form>
</div>
<form class="form-card" method="post" enctype="multipart/form-data">
  <h2>Upload more product photos</h2>
  <input type="hidden" name="csrf" value="<?= e(
    csrf_token(),
) ?>" /><input type="hidden" name="action" value="images" /><label>Product</label
  ><select name="product_id">
    <?php foreach (
    $products
    as $p
): ?>

    <option value="<?= (int) $p['product_id'] ?>"><?= e(
    $p['product_name'],
) ?></option>
    <?php endforeach; ?></select
  ><label>Photos (select multiple)</label><input type="file" name="photos[]" multiple accept="image/jpeg,image/png,image/webp,image/gif" /><label>Alt text</label><input name="alt_text" /><button>
    Upload photos
  </button>
</form>
<div class="table-wrap">
  <table>
    <thead>
      <tr>
        <th>Edit product</th>
        <th>Category</th>
        <th>Price</th>
        <th>Variants</th>
        <th>Archive</th>
      </tr>
    </thead>
    <tbody>
      <?php foreach (
    $list
    as $p
): ?>

      <tr>
        <td>
          <form method="post">
            <input type="hidden" name="csrf" value="<?= e(
    csrf_token(),
) ?>" /><input type="hidden" name="action" value="edit" /><input type="hidden" name="product_id" value="<?= (int) $p[
    'product_id'
] ?>" /><input
              name="product_name"
              value="<?= e(
    $p['product_name'],
) ?>"
            /><textarea name="description"><?= e(
    $p['description'] ?? '',
) ?></textarea
            ><select name="product_category_id">
              <?php foreach (
    $cats
    as $c
): ?>

              <option value="<?= (int) $c['product_category_id'] ?>" <?= (int) $p['product_category_id'] ===
(int) $c['product_category_id']
    ? 'selected'
    : '' ?>><?= e(
    $c['category_name'],
) ?></option>
              <?php endforeach; ?></select
            ><select name="product_type_id">
              <?php foreach ($types as $type): ?>
              <option value="<?= (int) $type['product_type_id'] ?>" <?= (int) $p['product_type_id'] === (int) $type['product_type_id'] ? 'selected' : '' ?>><?= e($type['type_name']) ?></option>
              <?php endforeach; ?></select
            ><input type="number" name="base_price" step="0.01" min="0" value="<?= e(
    $p['base_price'],
) ?>" /><button>Update</button>
          </form>
        </td>
        <td><?= e(
    $p['category_name'] . ' / ' . $p['type_name'],
) ?></td>
        <td>₱<?= number_format((float) $p['base_price'], 2) ?></td>
        <td><?= (int) $p[
    'variants'
] ?></td>
        <td>
          <form method="post">
            <input type="hidden" name="csrf" value="<?= e(
    csrf_token(),
) ?>" /><input type="hidden" name="action" value="archive" /><input type="hidden" name="product_id" value="<?= (int) $p[
    'product_id'
] ?>" /><button>
              Archive
            </button>
          </form>
        </td>
      </tr>
      <?php endforeach; ?>
      <?php if (!$list): ?>
      <tr><td colspan="5" class="empty-note">No products yet. Create a product above to get started.</td></tr>
      <?php endif; ?>

    </tbody>
  </table>
</div>
<?php require __DIR__ . '/../includes/admin_footer.php'; ?>
