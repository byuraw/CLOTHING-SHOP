<?php
require_once __DIR__ . "/../includes/functions.php";
require_admin();
$error = "";
$restockFilterIds = [];
foreach (
    [
        "product_category_id" => "category",
        "product_type_id" => "type",
        "size_id" => "size",
        "color_id" => "color",
    ]
    as $key => $label
) {
    $restockFilterIds[$key] = parse_filter_id($_GET, $key);
    if ($restockFilterIds[$key] === false) {
        $error = "Choose a valid " . $label . " filter.";
    }
}
if ($_SERVER["REQUEST_METHOD"] === "POST") {
    csrf_check();
    try {
        $action = $_POST["action"] ?? "";
        if ($action === "images") {
            $pid = (int) ($_POST["product_id"] ?? 0);
            if (!$pid) {
                throw new RuntimeException("Select a product.");
            }
            $count = 0;
            foreach ($_FILES["photos"]["name"] ?? [] as $idx => $unused) {
                $one = [
                    "name" => $_FILES["photos"]["name"][$idx],
                    "type" => $_FILES["photos"]["type"][$idx],
                    "tmp_name" => $_FILES["photos"]["tmp_name"][$idx],
                    "error" => $_FILES["photos"]["error"][$idx],
                    "size" => $_FILES["photos"]["size"][$idx],
                ];
                $path = upload_image($one, "products");
                if ($path) {
                    $q = $pdo->prepare(
                        "INSERT INTO product_images(product_id,image_path,alt_text,sort_order) VALUES(?,?,?,?)",
                    );
                    $q->execute([
                        $pid,
                        $path,
                        trim($_POST["alt_text"] ?? ""),
                        $count++,
                    ]);
                }
            }
            flash(
                $count
                    ? "Product photos uploaded."
                    : "Choose at least one photo.",
            );
        } elseif ($action === "product") {
            $name = trim($_POST["product_name"] ?? "");
            $categoryId = (int) ($_POST["product_category_id"] ?? 0);
            $price = filter_var(
                $_POST["base_price"] ?? null,
                FILTER_VALIDATE_FLOAT,
            );
            $description = trim($_POST["description"] ?? "");
            $slug =
                strtolower(
                    trim(preg_replace("/[^a-z0-9]+/i", "-", $name), "-"),
                ) .
                "-" .
                bin2hex(random_bytes(2));
            if (
                !$name ||
                !$categoryId ||
                $price === false ||
                $price < 0 ||
                $description === ""
            ) {
                throw new RuntimeException(
                    "Complete the product name, category, base price, and description.",
                );
            }
            $typeValue = trim((string) ($_POST["product_type_id"] ?? ""));
            $typeId =
                $typeValue === ""
                    ? null
                    : filter_var($typeValue, FILTER_VALIDATE_INT);
            if ($typeId === false || $typeId === null || $typeId < 1) {
                throw new RuntimeException("Choose a product type.");
            }
            $catalogInfo = $pdo->prepare(
                'SELECT pc.category_name,pt.type_name
                FROM product_types pt
                LEFT JOIN product_categories pc
                    ON pc.product_category_id=? AND pc.is_active=1
                WHERE pt.product_type_id=?',
            );
            $catalogInfo->execute([$categoryId, $typeId]);
            $catalogInfo = $catalogInfo->fetch();
            if (!$catalogInfo) {
                throw new RuntimeException("Choose a valid product type.");
            }
            if (!$catalogInfo["category_name"]) {
                throw new RuntimeException(
                    "Choose a valid product category and type.",
                );
            }
            $sizeId = filter_var(
                $_POST["size_id"] ?? null,
                FILTER_VALIDATE_INT,
            );
            $colorId = filter_var(
                $_POST["color_id"] ?? null,
                FILTER_VALIDATE_INT,
            );
            $variantPrice = filter_var(
                $_POST["variant_price"] ?? null,
                FILTER_VALIDATE_FLOAT,
            );
            $stock = filter_var(
                $_POST["stock_quantity"] ?? null,
                FILTER_VALIDATE_INT,
            );
            if (
                $sizeId === false ||
                $sizeId < 1 ||
                $colorId === false ||
                $colorId < 1 ||
                $variantPrice === false ||
                $variantPrice < 0 ||
                $stock === false ||
                $stock < 0
            ) {
                throw new RuntimeException(
                    "Choose a size and color, then enter a valid variant price and starting stock.",
                );
            }
            $sku = clothing_sku(
                $catalogInfo["category_name"],
                $catalogInfo["type_name"],
                $name,
                $sizeId,
                $colorId,
            );
            $photos = $_FILES["photos"] ?? null;
            if (
                !is_array($photos) ||
                !isset($photos["name"]) ||
                !is_array($photos["name"]) ||
                !array_filter(
                    $photos["name"],
                    static fn($photoName) => $photoName !== "",
                )
            ) {
                throw new RuntimeException(
                    "Upload at least one product photo.",
                );
            }
            $pdo->beginTransaction();
            $uploadedPaths = [];
            try {
                $q = $pdo->prepare(
                    "INSERT INTO products(product_category_id,product_type_id,product_name,slug,description,base_price,is_active) VALUES(?,?,?,?,?,?,1)",
                );
                $q->execute([
                    $categoryId,
                    $typeId,
                    $name,
                    $slug,
                    $description,
                    $price,
                ]);
                $newPid = (int) $pdo->lastInsertId();

                $variant = $pdo->prepare(
                    "INSERT INTO product_variants(product_id,size_id,color_id,sku,price,stock_quantity,is_active) VALUES(?,?,?,?,?,?,1)",
                );
                $variant->execute([
                    $newPid,
                    $sizeId,
                    $colorId,
                    $sku,
                    $variantPrice,
                    $stock,
                ]);
                $variantId = (int) $pdo->lastInsertId();
                if ($stock > 0) {
                    $inventory = $pdo->prepare(
                        "INSERT INTO inventory_transactions(variant_id,changed_by,quantity_change,reason,reference_text) VALUES(?,?,?,'RESTOCK','Initial variant stock')",
                    );
                    $inventory->execute([
                        $variantId,
                        current_user()["id"],
                        $stock,
                    ]);
                }

                $image = $pdo->prepare(
                    "INSERT INTO product_images(product_id,image_path,alt_text,sort_order) VALUES(?,?,?,?)",
                );
                $imageCount = 0;
                foreach ($photos["name"] as $idx => $unused) {
                    $one = [
                        "name" => $photos["name"][$idx],
                        "type" => $photos["type"][$idx],
                        "tmp_name" => $photos["tmp_name"][$idx],
                        "error" => $photos["error"][$idx],
                        "size" => $photos["size"][$idx],
                    ];
                    if ($one["error"] === UPLOAD_ERR_NO_FILE) {
                        continue;
                    }
                    $path = upload_image($one, "products");
                    if ($path === null) {
                        throw new RuntimeException(
                            "Upload at least one product photo.",
                        );
                    }
                    $uploadedPaths[] = __DIR__ . "/../" . $path;
                    $image->execute([$newPid, $path, $name, $imageCount++]);
                }
                if ($imageCount === 0) {
                    throw new RuntimeException(
                        "Upload at least one product photo.",
                    );
                }
                $pdo->commit();
            } catch (Throwable $e) {
                if ($pdo->inTransaction()) {
                    $pdo->rollBack();
                }
                foreach ($uploadedPaths as $uploadedPath) {
                    if (is_file($uploadedPath) && !unlink($uploadedPath)) {
                        error_log(
                            "Could not remove failed product upload: " .
                                $uploadedPath,
                        );
                    }
                }
                throw $e;
            }
            flash("Product, initial variant, and photos created.");
        } elseif ($action === "edit") {
            $pid = (int) ($_POST["product_id"] ?? 0);
            $name = trim($_POST["product_name"] ?? "");
            $categoryId = (int) ($_POST["product_category_id"] ?? 0);
            $typeId = filter_var(
                $_POST["product_type_id"] ?? null,
                FILTER_VALIDATE_INT,
            );
            $price = filter_var(
                $_POST["base_price"] ?? null,
                FILTER_VALIDATE_FLOAT,
            );
            if (
                !$pid ||
                $name === "" ||
                !$categoryId ||
                $typeId === false ||
                $typeId < 1 ||
                $price === false ||
                $price < 0
            ) {
                throw new RuntimeException(
                    "Enter a product name, category, type, and valid price.",
                );
            }
            $slug =
                strtolower(
                    trim(preg_replace("/[^a-z0-9]+/i", "-", $name), "-"),
                ) .
                "-" .
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
                throw new RuntimeException(
                    "Choose a valid product category and type.",
                );
            }
            clothing_sku(
                $catalogInfo["category_name"],
                $catalogInfo["type_name"],
                $name,
                null,
                null,
            );
            $pdo->beginTransaction();
            try {
                $q = $pdo->prepare(
                    "UPDATE products SET product_category_id=?,product_type_id=?,product_name=?,slug=?,description=?,base_price=? WHERE product_id=?",
                );
                $q->execute([
                    $categoryId,
                    $typeId,
                    $name,
                    $slug,
                    trim($_POST["description"] ?? ""),
                    $price,
                    $pid,
                ]);
                $variants = $pdo->prepare(
                    "SELECT variant_id,size_id,color_id FROM product_variants WHERE product_id=?",
                );
                $variants->execute([$pid]);
                $saveSku = $pdo->prepare(
                    "UPDATE product_variants SET sku=? WHERE variant_id=?",
                );
                foreach ($variants->fetchAll() as $variant) {
                    $sku = clothing_sku(
                        $catalogInfo["category_name"],
                        $catalogInfo["type_name"],
                        $name,
                        $variant["size_id"] === null
                            ? null
                            : (int) $variant["size_id"],
                        $variant["color_id"] === null
                            ? null
                            : (int) $variant["color_id"],
                    );
                    $saveSku->execute([$sku, $variant["variant_id"]]);
                }
                $pdo->commit();
            } catch (Throwable $e) {
                if ($pdo->inTransaction()) {
                    $pdo->rollBack();
                }
                throw $e;
            }
            flash("Product updated.");
            redirect(
                APP_BASE . "/admin/products.php#update-product-panel",
            );
        } elseif ($action === "variant") {
            $pid = (int) ($_POST["product_id"] ?? 0);
            $price = filter_var($_POST["price"] ?? null, FILTER_VALIDATE_FLOAT);
            $stock = max(0, (int) ($_POST["stock_quantity"] ?? 0));
            if (!$pid || $price === false || $price < 0) {
                throw new RuntimeException(
                    "Select a product and enter a valid price.",
                );
            }
            $product = $pdo->prepare(
                "SELECT p.product_name,pc.category_name,pt.type_name FROM products p JOIN product_categories pc ON pc.product_category_id=p.product_category_id JOIN product_types pt ON pt.product_type_id=p.product_type_id WHERE p.product_id=? AND p.is_active=1",
            );
            $product->execute([$pid]);
            $product = $product->fetch();
            if (!$product) {
                throw new RuntimeException("Choose a valid product.");
            }
            $sizeValue = trim((string) ($_POST["size_id"] ?? ""));
            $colorValue = trim((string) ($_POST["color_id"] ?? ""));
            $sizeId =
                $sizeValue === ""
                    ? null
                    : filter_var($sizeValue, FILTER_VALIDATE_INT);
            $colorId =
                $colorValue === ""
                    ? null
                    : filter_var($colorValue, FILTER_VALIDATE_INT);
            if (
                $sizeId === false ||
                ($sizeId !== null && $sizeId < 1) ||
                $colorId === false ||
                ($colorId !== null && $colorId < 1)
            ) {
                throw new RuntimeException(
                    "Choose valid size and color options.",
                );
            }
            $sku = clothing_sku(
                $product["category_name"],
                $product["type_name"],
                $product["product_name"],
                $sizeId,
                $colorId,
            );
            $q = $pdo->prepare(
                "INSERT INTO product_variants(product_id,size_id,color_id,sku,price,stock_quantity,is_active) VALUES(?,?,?,?,?,?,1)",
            );
            $q->execute([$pid, $sizeId, $colorId, $sku, $price, $stock]);
            $variantId = (int) $pdo->lastInsertId();
            if ($stock > 0) {
                $i = $pdo->prepare(
                    "INSERT INTO inventory_transactions(variant_id,changed_by,quantity_change,reason,reference_text) VALUES(?,?,?,'RESTOCK','Initial variant stock')",
                );
                $i->execute([$variantId, current_user()["id"], $stock]);
            }
            flash("Variant created.");
        } elseif ($action === "restock") {
            $variantId = filter_var(
                $_POST["variant_id"] ?? null,
                FILTER_VALIDATE_INT,
            );
            $quantity = filter_var(
                $_POST["quantity"] ?? null,
                FILTER_VALIDATE_INT,
            );
            if (
                $variantId === false ||
                $variantId < 1 ||
                $quantity === false ||
                $quantity < 1 ||
                $quantity > 2147483647
            ) {
                throw new RuntimeException(
                    "Choose a variant and enter a positive quantity.",
                );
            }
            $pdo->beginTransaction();
            try {
                $variantQuery = $pdo->prepare(
                    "SELECT v.stock_quantity
                    FROM product_variants v
                    JOIN products p ON p.product_id=v.product_id
                    WHERE v.variant_id=? AND v.is_active=1 AND p.is_active=1
                    FOR UPDATE",
                );
                $variantQuery->execute([$variantId]);
                $currentStock = $variantQuery->fetchColumn();
                if ($currentStock === false) {
                    throw new RuntimeException(
                        "Choose an active product variant.",
                    );
                }
                if ($quantity > 4294967295 - (int) $currentStock) {
                    throw new RuntimeException(
                        "The restock quantity exceeds the maximum stock level.",
                    );
                }
                $saveStock = $pdo->prepare(
                    "UPDATE product_variants SET stock_quantity=stock_quantity+? WHERE variant_id=?",
                );
                $saveStock->execute([$quantity, $variantId]);
                $logStock = $pdo->prepare(
                    "INSERT INTO inventory_transactions(variant_id,changed_by,quantity_change,reason,reference_text) VALUES(?,?,?,'RESTOCK','Product restock')",
                );
                $logStock->execute([
                    $variantId,
                    current_user()["id"],
                    $quantity,
                ]);
                $pdo->commit();
            } catch (Throwable $e) {
                if ($pdo->inTransaction()) {
                    $pdo->rollBack();
                }
                throw $e;
            }
            flash("Product restocked.");
            redirect(
                APP_BASE . "/admin/products.php#restock-product-panel",
            );
        } elseif ($action === "archive") {
            $q = $pdo->prepare(
                "UPDATE products SET is_active=0 WHERE product_id=?",
            );
            $q->execute([(int) $_POST["product_id"]]);
            flash("Product archived.");
        }
        redirect("/clothing-store-backup/admin/products.php");
    } catch (Throwable $e) {
        $error =
            $e instanceof RuntimeException
                ? $e->getMessage()
                : "Could not save. Check duplicate SKU and database setup.";
    }
}
$cats = $pdo
    ->query(
        "SELECT product_category_id,category_name FROM product_categories WHERE is_active=1 ORDER BY category_name",
    )
    ->fetchAll();
$types = $pdo
    ->query(
        "SELECT product_type_id,type_name FROM product_types ORDER BY type_name",
    )
    ->fetchAll();
$products = $pdo
    ->query(
        "SELECT product_id,product_name FROM products WHERE is_active=1 ORDER BY product_name",
    )
    ->fetchAll();
$sizes = $pdo
    ->query("SELECT size_id,size_name FROM sizes ORDER BY size_id")
    ->fetchAll();
$colors = $pdo
    ->query("SELECT color_id,color_name FROM colors ORDER BY color_name")
    ->fetchAll();
$restockWhere = ["v.is_active=1", "p.is_active=1"];
$restockArgs = [];
foreach (
    [
        "product_category_id" => "p.product_category_id",
        "product_type_id" => "p.product_type_id",
        "size_id" => "v.size_id",
        "color_id" => "v.color_id",
    ]
    as $key => $column
) {
    if ($restockFilterIds[$key] === false) {
        $restockWhere[] = "1=0";
    } elseif ($restockFilterIds[$key] !== null) {
        $restockWhere[] = $column . "=?";
        $restockArgs[] = $restockFilterIds[$key];
    }
}
$restockQuery = $pdo->prepare(
    'SELECT v.variant_id,v.sku,v.stock_quantity,p.product_name,pc.category_name,pt.type_name,s.size_name,c.color_name
    FROM product_variants v
    JOIN products p ON p.product_id=v.product_id
    JOIN product_categories pc ON pc.product_category_id=p.product_category_id
    JOIN product_types pt ON pt.product_type_id=p.product_type_id
    LEFT JOIN sizes s ON s.size_id=v.size_id
    LEFT JOIN colors c ON c.color_id=v.color_id
    WHERE ' .
        implode(" AND ", $restockWhere) .
        '
    ORDER BY p.product_name,s.size_name,c.color_name',
);
$restockQuery->execute($restockArgs);
$restockVariants = $restockQuery->fetchAll();
$list = $pdo
    ->query(
        "SELECT p.product_id,p.product_name,p.description,p.product_category_id,p.product_type_id,p.base_price,pc.category_name,pt.type_name,(SELECT COUNT(*) FROM product_variants v WHERE v.product_id=p.product_id AND v.is_active=1) variants FROM products p JOIN product_categories pc ON pc.product_category_id=p.product_category_id JOIN product_types pt ON pt.product_type_id=p.product_type_id WHERE p.is_active=1 ORDER BY p.created_at DESC",
    )
    ->fetchAll();
$pageTitle = "Products";
require __DIR__ . "/../includes/admin_header.php";
?>

<h1 class="page-title">Products</h1>
<?php if ($error): ?>

<div class="notice error"><?= e($error) ?></div>
<?php endif; ?>

<div class="product-tabs" role="tablist" aria-label="Product management">
  <button
    type="button"
    class="product-tab active"
    id="add-product-tab"
    role="tab"
    aria-controls="add-product-panel"
    aria-selected="true"
    data-product-tab="add-product-panel"
  >Add new product</button>
  <button
    type="button"
    class="product-tab"
    id="update-product-tab"
    role="tab"
    aria-controls="update-product-panel"
    aria-selected="false"
    data-product-tab="update-product-panel"
  >Update product</button>
  <button
    type="button"
    class="product-tab"
    id="restock-product-tab"
    role="tab"
    aria-controls="restock-product-panel"
    aria-selected="false"
    data-product-tab="restock-product-panel"
  >Restock Product</button>
</div>

<section
  class="product-tab-panel"
  id="add-product-panel"
  role="tabpanel"
  aria-labelledby="add-product-tab"
  data-product-panel
>
  <form class="form-card product-create-form" method="post" enctype="multipart/form-data">
    <h2>Add new product</h2>
    <input type="hidden" name="csrf" value="<?= e(
        csrf_token(),
    ) ?>" />
    <input type="hidden" name="action" value="product" />
    <label for="new-product-name">Name</label>
    <input id="new-product-name" name="product_name" required>
    <label for="new-product-category">Product category</label>
    <select id="new-product-category" name="product_category_id" required>
      <option value="">Choose a category</option>
      <?php foreach ($cats as $c): ?>
      <option value="<?= (int) $c["product_category_id"] ?>"><?= e(
          $c["category_name"],
      ) ?></option>
      <?php endforeach; ?>
    </select>
    <label for="new-product-type">Type</label>
    <select id="new-product-type" name="product_type_id" required>
      <option value="">Choose a type</option>
      <?php foreach ($types as $t): ?>
      <option value="<?= (int) $t["product_type_id"] ?>"><?= e(
          $t["type_name"],
      ) ?></option>
      <?php endforeach; ?>
    </select>
    <label for="new-product-price">Base price</label>
    <input id="new-product-price" name="base_price" type="number" min="0" step=".01" required>
    <label for="new-product-description">Description</label>
    <textarea id="new-product-description" name="description" required></textarea>
    <h2>Initial size/color variant</h2>
    <label for="new-product-size">Size</label>
    <select id="new-product-size" name="size_id" required>
      <option value="">Choose a size</option>
      <?php foreach ($sizes as $s): ?>
      <option value="<?= (int) $s["size_id"] ?>"><?= e(
          $s["size_name"],
      ) ?></option>
      <?php endforeach; ?>
    </select>
    <label for="new-product-color">Color</label>
    <select id="new-product-color" name="color_id" required>
      <option value="">Choose a color</option>
      <?php foreach ($colors as $c): ?>
      <option value="<?= (int) $c["color_id"] ?>"><?= e(
          $c["color_name"],
      ) ?></option>
      <?php endforeach; ?>
    </select>
    <label for="new-product-variant-price">Variant price</label>
    <input id="new-product-variant-price" name="variant_price" type="number" min="0" step=".01" required>
    <label for="new-product-stock">Starting stock</label>
    <input id="new-product-stock" name="stock_quantity" type="number" min="0" step="1" required>
    <label for="new-product-photos">Product photos</label>
    <input id="new-product-photos" type="file" name="photos[]" multiple accept="image/jpeg,image/png,image/webp,image/gif" required>
    <button type="submit">Create product</button>
  </form>
</section>

<section
  class="product-tab-panel"
  id="update-product-panel"
  role="tabpanel"
  aria-labelledby="update-product-tab"
  data-product-panel
  hidden
>
<form class="form-card product-edit-form" method="post" id="product-edit-form">
  <h2>Edit selected product</h2>
  <p id="product-edit-prompt">Select a product from the table below to load its details.</p>
  <input type="hidden" name="csrf" value="<?= e(csrf_token()) ?>">
  <input type="hidden" name="action" value="edit">
  <input type="hidden" name="product_id" id="edit-product-id" value="">
  <label for="edit-product-name">Name</label>
  <input id="edit-product-name" name="product_name" required disabled>
  <label for="edit-product-description">Description</label>
  <textarea id="edit-product-description" name="description" required disabled></textarea>
  <label for="edit-product-category">Product category</label>
  <select id="edit-product-category" name="product_category_id" required disabled>
    <option value="">Choose a category</option>
    <?php foreach ($cats as $category): ?>
      <option value="<?= (int) $category["product_category_id"] ?>"><?= e($category["category_name"]) ?></option>
    <?php endforeach; ?>
  </select>
  <label for="edit-product-type">Type</label>
  <select id="edit-product-type" name="product_type_id" required disabled>
    <option value="">Choose a type</option>
    <?php foreach ($types as $type): ?>
      <option value="<?= (int) $type["product_type_id"] ?>"><?= e($type["type_name"]) ?></option>
    <?php endforeach; ?>
  </select>
  <label for="edit-product-price">Base price</label>
  <input id="edit-product-price" name="base_price" type="number" step="0.01" min="0" required disabled>
  <button type="submit" id="save-product-edit" disabled>Save changes</button>
</form>
<div class="update-product-toolbar">
  <div class="search">
    <svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/></svg>
    <label for="q" class="sr-only">Search products to update</label>
    <input
      id="q"
      type="search"
      placeholder="Search products by name, category, type, description…"
      data-table-filter
    >
  </div>
</div>
<div class="table-wrap">
  <table>
    <thead>
      <tr>
        <th>Product</th>
        <th>Category / type</th>
        <th>Price</th>
        <th>Variants</th>
        <th>Actions</th>
      </tr>
    </thead>
    <tbody>
      <?php foreach ($list as $p): ?>

      <tr data-search="<?= e(
          implode(" ", [
              $p["product_id"],
              $p["product_name"],
              $p["description"] ?? "",
              $p["category_name"],
              $p["type_name"],
              $p["base_price"],
          ]),
      ) ?>"
        data-product-id="<?= (int) $p["product_id"] ?>"
        data-product-name="<?= e($p["product_name"]) ?>"
        data-product-description="<?= e($p["description"] ?? "") ?>"
        data-product-category="<?= (int) $p["product_category_id"] ?>"
        data-product-type="<?= (int) $p["product_type_id"] ?>"
        data-product-price="<?= e($p["base_price"]) ?>"
        data-selectable-product
        tabindex="0"
        aria-label="<?= e("Select " . $p["product_name"] . " to edit") ?>"
      >
        <td>
          <strong><?= e($p["product_name"]) ?></strong>
        </td>
        <td><?= e($p["category_name"] . " / " . $p["type_name"]) ?></td>
        <td>₱<?= number_format((float) $p["base_price"], 2) ?></td>
        <td><?= (int) $p["variants"] ?></td>
        <td>
          <form method="post" class="inline-form">
            <input type="hidden" name="csrf" value="<?= e(
                csrf_token(),
            ) ?>" /><input type="hidden" name="action" value="archive" /><input type="hidden" name="product_id" value="<?= (int) $p[
    "product_id"
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
</section>

<section
  class="product-tab-panel"
  id="restock-product-panel"
  role="tabpanel"
  aria-labelledby="restock-product-tab"
  data-product-panel
  hidden
>
  <div class="update-product-toolbar">
    <div class="search">
      <svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/></svg>
      <label for="restock-search" class="sr-only">Search products to restock</label>
      <input
        id="restock-search"
        type="search"
        placeholder="Search products, options, or SKU…"
        data-table-filter
      >
    </div>
  </div>
  <form class="row" method="get" action="<?= e(APP_BASE . "/admin/products.php#restock-product-panel") ?>">
    <label>Category<select name="product_category_id">
      <option value="">All categories</option>
      <?php foreach ($cats as $category): ?>
        <option value="<?= (int) $category["product_category_id"] ?>" <?= $restockFilterIds["product_category_id"] === (int) $category["product_category_id"] ? "selected" : "" ?>><?= e($category["category_name"]) ?></option>
      <?php endforeach; ?>
    </select></label>
    <label>Type<select name="product_type_id">
      <option value="">All types</option>
      <?php foreach ($types as $type): ?>
        <option value="<?= (int) $type["product_type_id"] ?>" <?= $restockFilterIds["product_type_id"] === (int) $type["product_type_id"] ? "selected" : "" ?>><?= e($type["type_name"]) ?></option>
      <?php endforeach; ?>
    </select></label>
    <label>Size<select name="size_id">
      <option value="">All sizes</option>
      <?php foreach ($sizes as $size): ?>
        <option value="<?= (int) $size["size_id"] ?>" <?= $restockFilterIds["size_id"] === (int) $size["size_id"] ? "selected" : "" ?>><?= e($size["size_name"]) ?></option>
      <?php endforeach; ?>
    </select></label>
    <label>Color<select name="color_id">
      <option value="">All colors</option>
      <?php foreach ($colors as $color): ?>
        <option value="<?= (int) $color["color_id"] ?>" <?= $restockFilterIds["color_id"] === (int) $color["color_id"] ? "selected" : "" ?>><?= e($color["color_name"]) ?></option>
      <?php endforeach; ?>
    </select></label>
    <button>Filter</button>
    <a class="button secondary" href="<?= e(APP_BASE . "/admin/products.php#restock-product-panel") ?>">Clear filters</a>
  </form>
  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>Product / option</th>
          <th>SKU</th>
          <th>On hand</th>
          <th>Restock</th>
        </tr>
      </thead>
      <tbody>
        <?php foreach ($restockVariants as $variant): ?>
          <tr data-search="<?= e(implode(" ", [
              $variant["product_name"],
              $variant["category_name"],
              $variant["type_name"],
              $variant["size_name"] ?? "One size",
              $variant["color_name"] ?? "Default",
              $variant["sku"],
          ])) ?>">
            <td><?= e($variant["product_name"] . " / " . ($variant["size_name"] ?? "One size") . " / " . ($variant["color_name"] ?? "Default")) ?></td>
            <td><?= e($variant["sku"]) ?></td>
            <td><?= (int) $variant["stock_quantity"] ?></td>
            <td>
              <form class="row" method="post" action="<?= e(APP_BASE . "/admin/products.php#restock-product-panel") ?>">
                <input type="hidden" name="csrf" value="<?= e(csrf_token()) ?>">
                <input type="hidden" name="action" value="restock">
                <input type="hidden" name="variant_id" value="<?= (int) $variant["variant_id"] ?>">
                <label class="sr-only" for="restock-quantity-<?= (int) $variant["variant_id"] ?>">Quantity to add for <?= e($variant["product_name"]) ?></label>
                <input id="restock-quantity-<?= (int) $variant["variant_id"] ?>" type="number" min="1" max="2147483647" name="quantity" placeholder="Qty" required>
                <button type="submit">Restock Product</button>
              </form>
            </td>
          </tr>
        <?php endforeach; ?>
        <?php if (!$restockVariants): ?>
          <tr><td colspan="4" class="empty-note">No active product variants match these filters.</td></tr>
        <?php endif; ?>
      </tbody>
    </table>
  </div>
</section>
<?php require __DIR__ . "/../includes/admin_footer.php"; ?>
