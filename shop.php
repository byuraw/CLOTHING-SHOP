<?php
require_once __DIR__ . '/includes/functions.php';

$term = trim($_GET['q'] ?? '');
$filterError = '';
$filters = [];
foreach (
    [
        'category' => 'category',
        'product_type_id' => 'type',
        'size_id' => 'size',
        'color_id' => 'color',
    ] as $key => $label
) {
    $rawValue = $_GET[$key] ?? '';
    $value = is_scalar($rawValue) ? trim((string) $rawValue) : null;
    if ($value === null) {
        $filterError = 'Choose a valid ' . $label . ' filter.';
        $filters[$key] = false;
    } elseif ($value === '' || ($key === 'category' && $value === '0')) {
        $filters[$key] = null;
    } else {
        $filterId = filter_var($value, FILTER_VALIDATE_INT);
        if ($filterId === false || $filterId < 1) {
            $filterError = 'Choose a valid ' . $label . ' filter.';
            $filters[$key] = false;
        } else {
            $filters[$key] = $filterId;
        }
    }
}
$sql = 'SELECT p.product_id,p.product_name,p.base_price,pi.image_path,c.category_name
    FROM products p
    JOIN product_categories c ON c.product_category_id=p.product_category_id
    LEFT JOIN product_images pi ON pi.product_id=p.product_id AND pi.sort_order=0
    WHERE p.is_active=1';
$args = [];
$where = [];

if ($term !== '') {
    $where[] = '(p.product_name LIKE ? OR p.description LIKE ?)';
    $args[] = "%$term%";
    $args[] = "%$term%";
}

foreach (
    [
        'category' => 'p.product_category_id',
        'product_type_id' => 'p.product_type_id',
    ] as $key => $column
) {
    if ($filters[$key] === false) {
        $where[] = '1=0';
    } elseif ($filters[$key] !== null) {
        $where[] = $column . '=?';
        $args[] = $filters[$key];
    }
}

$variantConditions = [];
foreach (['size_id' => 'v.size_id', 'color_id' => 'v.color_id'] as $key => $column) {
    if ($filters[$key] === false) {
        $where[] = '1=0';
    } elseif ($filters[$key] !== null) {
        $variantConditions[] = $column . '=?';
        $args[] = $filters[$key];
    }
}
if ($variantConditions) {
    $where[] =
        'EXISTS (SELECT 1 FROM product_variants v WHERE v.product_id=p.product_id AND v.is_active=1 AND ' .
        implode(' AND ', $variantConditions) .
        ')';
}

$sql .= $where ? ' AND ' . implode(' AND ', $where) : '';
$sql .= ' ORDER BY p.created_at DESC';
$s = $pdo->prepare($sql);
$s->execute($args);
$products = $s->fetchAll();
$categories = $pdo
    ->query(
        'SELECT product_category_id AS category_id,category_name
        FROM product_categories
        WHERE is_active=1
        ORDER BY category_name',
    )
    ->fetchAll();
$types = $pdo->query('SELECT product_type_id,type_name FROM product_types ORDER BY type_name')->fetchAll();
$sizes = $pdo->query('SELECT size_id,size_name FROM sizes ORDER BY size_id')->fetchAll();
$colors = $pdo->query('SELECT color_id,color_name FROM colors ORDER BY color_name')->fetchAll();
$pageTitle = 'Shop';
require __DIR__ . '/includes/header.php';
?>

<div class="section-head">
    <h1 class="page-title">Shop</h1>
</div>
<p><a class="button secondary" href="<?= e(APP_BASE . '/index.php') ?>">Back to home</a></p>
<form method="get" class="row">
    <div class="shop-search-field">
        <input name="q" value="<?= e($term) ?>" placeholder="Search clothing" aria-label="Search clothing" />
    </div>
    <select name="category">
        <option value="">All categories</option>
        <?php foreach ($categories as $c): ?>
            <option
                value="<?= (int) $c['category_id'] ?>"
                <?= $filters['category'] === (int) $c['category_id'] ? 'selected' : '' ?>
            >
                <?= e($c['category_name']) ?>
            </option>
        <?php endforeach; ?>
    </select>
    <select name="product_type_id">
        <option value="">All types</option>
        <?php foreach ($types as $type): ?>
            <option value="<?= (int) $type['product_type_id'] ?>" <?= $filters['product_type_id'] === (int) $type['product_type_id'] ? 'selected' : '' ?>>
                <?= e($type['type_name']) ?>
            </option>
        <?php endforeach; ?>
    </select>
    <select name="size_id">
        <option value="">All sizes</option>
        <?php foreach ($sizes as $size): ?>
            <option value="<?= (int) $size['size_id'] ?>" <?= $filters['size_id'] === (int) $size['size_id'] ? 'selected' : '' ?>>
                <?= e($size['size_name']) ?>
            </option>
        <?php endforeach; ?>
    </select>
    <select name="color_id">
        <option value="">All colors</option>
        <?php foreach ($colors as $color): ?>
            <option value="<?= (int) $color['color_id'] ?>" <?= $filters['color_id'] === (int) $color['color_id'] ? 'selected' : '' ?>>
                <?= e($color['color_name']) ?>
            </option>
        <?php endforeach; ?>
    </select>
    <button>Filter</button>
    <a class="button secondary" href="<?= e(APP_BASE . '/shop.php') ?>">Clear filters</a>
</form>

<?php if ($filterError): ?>
    <div class="notice error"><?= e($filterError) ?></div>
<?php endif; ?>

<div class="grid">
    <?php foreach ($products as $p): ?>
        <article class="card">
            <a href="<?= APP_BASE . '/product.php?id=' . (int) $p['product_id'] ?>">
                <div class="product-image">
                    <?php if ($p['image_path']): ?>
                        <img src="<?= APP_BASE . '/' . e($p['image_path']) ?>" alt="" />
                    <?php else: ?>
                        Product image
                    <?php endif; ?>
                </div>
                <span class="muted"><?= e($p['category_name']) ?></span>
                <h3><?= e($p['product_name']) ?></h3>
            </a>
            <div class="price">₱<?= number_format((float) $p['base_price'], 2) ?></div>
        </article>
    <?php endforeach; ?>
</div>

<?php if (!$products): ?>
    <div class="empty">No products found. Try another search.</div>
<?php endif; ?>

<?php require __DIR__ . '/includes/footer.php'; ?>
