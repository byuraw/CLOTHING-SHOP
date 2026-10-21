<?php
require_once __DIR__ . "/../includes/functions.php";
require_admin();
$error = "";
$filterIds = [];
foreach (
    [
        "product_category_id" => "category",
        "product_type_id" => "type",
        "size_id" => "size",
        "color_id" => "color",
    ]
    as $key => $label
) {
    $rawValue = $_GET[$key] ?? "";
    $value = is_scalar($rawValue) ? trim((string) $rawValue) : null;
    if ($value === null) {
        $error = "Choose a valid " . $label . " filter.";
        $filterIds[$key] = false;
        continue;
    }
    if ($value === "") {
        $filterIds[$key] = null;
        continue;
    }
    $filterId = filter_var($value, FILTER_VALIDATE_INT);
    if ($filterId === false || $filterId < 1) {
        $error = "Choose a valid " . $label . " filter.";
        $filterIds[$key] = false;
        continue;
    }
    $filterIds[$key] = $filterId;
}
if ($_SERVER["REQUEST_METHOD"] === "POST") {
    csrf_check();
    $variant = (int) ($_POST["variant_id"] ?? 0);
    $qty = (int) ($_POST["quantity"] ?? 0);
    if ($variant > 0 && $qty > 0) {
        $pdo->beginTransaction();
        try {
            $q = $pdo->prepare(
                "UPDATE product_variants SET stock_quantity=stock_quantity+? WHERE variant_id=?",
            );
            $q->execute([$qty, $variant]);
            $q = $pdo->prepare(
                "INSERT INTO inventory_transactions(variant_id,changed_by,quantity_change) VALUES(?,?,?)",
            );
            $q->execute([$variant, current_user()["id"], $qty]);
            $pdo->commit();
            flash("Stock restocked.");
            redirect("/clothing-store-backup/admin/inventory.php");
        } catch (Throwable $e) {
            $pdo->rollBack();
            $error = "Could not update inventory.";
        }
    } else {
        $error = "Choose a variant and enter a positive quantity.";
    }
}
$categories = $pdo
    ->query(
        "SELECT product_category_id,category_name FROM product_categories WHERE is_active=1 ORDER BY category_name",
    )
    ->fetchAll();
$types = $pdo
    ->query(
        "SELECT product_type_id,type_name FROM product_types ORDER BY type_name",
    )
    ->fetchAll();
$sizes = $pdo
    ->query("SELECT size_id,size_name FROM sizes ORDER BY size_id")
    ->fetchAll();
$colors = $pdo
    ->query("SELECT color_id,color_name FROM colors ORDER BY color_name")
    ->fetchAll();
$where = ["v.is_active=1"];
$args = [];
foreach (
    [
        "product_category_id" => "p.product_category_id",
        "product_type_id" => "p.product_type_id",
        "size_id" => "v.size_id",
        "color_id" => "v.color_id",
    ]
    as $key => $column
) {
    if ($filterIds[$key] === false) {
        $where[] = "1=0";
    } elseif ($filterIds[$key] !== null) {
        $where[] = $column . "=?";
        $args[] = $filterIds[$key];
    }
}
$q = $pdo->prepare(
    'SELECT v.variant_id,v.sku,v.stock_quantity,v.price,p.product_name,s.size_name,c.color_name
    FROM product_variants v
    JOIN products p ON p.product_id=v.product_id
    LEFT JOIN sizes s ON s.size_id=v.size_id
    LEFT JOIN colors c ON c.color_id=v.color_id
    WHERE ' .
        implode(" AND ", $where) .
        '
    ORDER BY p.product_name',
);
$q->execute($args);
$list = $q->fetchAll();
$pageTitle = "Inventory";
require __DIR__ . "/../includes/admin_header.php";
?>

<h1 class="page-title">Inventory</h1>
<?php if ($error): ?>

<div class="notice error"><?= e($error) ?></div>
<?php endif; ?>

<form class="row" method="get">
  <label>Category<select name="product_category_id">
    <option value="">All categories</option>
    <?php foreach ($categories as $category): ?>
    <option value="<?= (int) $category[
        "product_category_id"
    ] ?>" <?= $filterIds["product_category_id"] ===
(int) $category["product_category_id"]
    ? "selected"
    : "" ?>><?= e($category["category_name"]) ?></option>
    <?php endforeach; ?>
  </select></label>
  <label>Type<select name="product_type_id">
    <option value="">All types</option>
    <?php foreach ($types as $type): ?>
    <option value="<?= (int) $type["product_type_id"] ?>" <?= $filterIds[
    "product_type_id"
] === (int) $type["product_type_id"]
    ? "selected"
    : "" ?>><?= e($type["type_name"]) ?></option>
    <?php endforeach; ?>
  </select></label>
  <label>Size<select name="size_id">
    <option value="">All sizes</option>
    <?php foreach ($sizes as $size): ?>
    <option value="<?= (int) $size["size_id"] ?>" <?= $filterIds["size_id"] ===
(int) $size["size_id"]
    ? "selected"
    : "" ?>><?= e($size["size_name"]) ?></option>
    <?php endforeach; ?>
  </select></label>
  <label>Color<select name="color_id">
    <option value="">All colors</option>
    <?php foreach ($colors as $color): ?>
    <option value="<?= (int) $color["color_id"] ?>" <?= $filterIds[
    "color_id"
] === (int) $color["color_id"]
    ? "selected"
    : "" ?>><?= e($color["color_name"]) ?></option>
    <?php endforeach; ?>
  </select></label>
  <button>Filter</button>
  <a class="button secondary" href="<?= e(
      APP_BASE . "/admin/inventory.php",
  ) ?>">Clear filters</a>
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
      <?php foreach ($list as $x): ?>

      <tr>
        <td><?= e(
            $x["product_name"] .
                " / " .
                ($x["size_name"] ?? "One size") .
                " / " .
                ($x["color_name"] ?? "Default"),
        ) ?></td>
        <td><?= e($x["sku"]) ?></td>
        <td><?= (int) $x["stock_quantity"] ?></td>
        <td>
          <form class="row" method="post">
            <input type="hidden" name="csrf" value="<?= e(
                csrf_token(),
            ) ?>" /><input type="hidden" name="variant_id" value="<?= (int) $x[
    "variant_id"
] ?>" /><input
              type="number"
              min="1"
              name="quantity"
              placeholder="Qty"
            /><button>Restock</button>
          </form>
        </td>
      </tr>
      <?php endforeach; ?>
      <?php if (!$list): ?>
      <tr><td colspan="4" class="empty-note">No active product variants to manage yet.</td></tr>
      <?php endif; ?>

    </tbody>
  </table>
</div>
<?php require __DIR__ . "/../includes/admin_footer.php"; ?>
