<?php
require_once __DIR__ . '/includes/functions.php';

$id = (int) ($_GET['id'] ?? 0);
$s = $pdo->prepare(
    'SELECT p.*,c.category_name,t.type_name
    FROM products p
    JOIN product_categories c ON c.product_category_id=p.product_category_id
    LEFT JOIN product_types t ON t.product_type_id=p.product_type_id
    WHERE p.product_id=? AND p.is_active=1',
);
$s->execute([$id]);
$p = $s->fetch();

if (!$p) {
    http_response_code(404);
    exit('Product not found.');
}

$v = $pdo->prepare(
    'SELECT pv.variant_id,pv.size_id,pv.color_id,pv.price,pv.stock_quantity,pv.sku,sz.size_name,co.color_name
    FROM product_variants pv
    LEFT JOIN sizes sz ON sz.size_id=pv.size_id
    LEFT JOIN colors co ON co.color_id=pv.color_id
    WHERE pv.product_id=? AND pv.is_active=1
    ORDER BY sz.size_id,co.color_id',
);
$v->execute([$id]);
$variants = $v->fetchAll();
$im = $pdo->prepare(
    'SELECT image_path,alt_text
    FROM product_images
    WHERE product_id=?
    ORDER BY sort_order,image_id',
);
$im->execute([$id]);
$images = $im->fetchAll();
$image = $images[0] ?? null;
$reviewError = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_POST['action'] ?? '') === 'review') {
    csrf_check();
    require_login();
    $rating = (int) ($_POST['rating'] ?? 0);
    $review = moderate_review(trim($_POST['review_text'] ?? ''));

    if ($rating < 1 || $rating > 5 || $review === '') {
        $reviewError = 'Choose a rating and write a review.';
    } else {
        $can = $pdo->prepare(
            "SELECT oi.order_item_id
            FROM order_items oi
            JOIN orders o ON o.order_id=oi.order_id
            JOIN order_statuses os ON os.order_status_id=o.order_status_id
            WHERE o.user_id=?
                AND oi.variant_id IN (
                    SELECT variant_id FROM product_variants WHERE product_id=?
                )
                AND os.status_name IN ('Processing','Packed','Shipped','Delivered','Completed')
            LIMIT 1",
        );
        $can->execute([current_user()['id'], $id]);
        $orderItem = $can->fetchColumn();

        if (!$orderItem) {
            $reviewError = 'You can review this product after purchasing it.';
        } else {
            $save = $pdo->prepare(
                'INSERT INTO product_reviews(product_id,user_id,order_item_id,rating,review_text)
                VALUES(?,?,?,?,?)
                ON DUPLICATE KEY UPDATE
                    rating=VALUES(rating),
                    review_text=VALUES(review_text),
                    updated_at=CURRENT_TIMESTAMP',
            );
            $save->execute([$id, current_user()['id'], $orderItem, $rating, $review]);
            flash('Review saved.');
            redirect(APP_BASE . '/product.php?id=' . $id . '#reviews');
        }
    }
}

$reviews = $pdo->prepare(
    'SELECT pr.rating,pr.review_text,pr.created_at,u.first_name,u.last_name
    FROM product_reviews pr
    JOIN users u ON u.user_id=pr.user_id
    WHERE pr.product_id=?
    ORDER BY pr.created_at DESC',
);
$reviews->execute([$id]);
$reviews = $reviews->fetchAll();

if (
    $_SERVER['REQUEST_METHOD'] === 'POST' &&
    in_array($_POST['action'] ?? '', ['add_to_cart', 'checkout'], true)
) {
    csrf_check();
    require_login();
    $variant = (int) ($_POST['variant_id'] ?? 0);
    $qty = filter_var($_POST['quantity'] ?? null, FILTER_VALIDATE_INT);
    $action = $_POST['action'];
    if ($qty === false || $qty < 1 || $qty > 99) {
        flash('Choose a quantity between 1 and 99.', 'error');
        redirect(APP_BASE . '/product.php?id=' . $id);
    }
    $check = $pdo->prepare(
        'SELECT variant_id,stock_quantity
        FROM product_variants
        WHERE variant_id=? AND product_id=? AND is_active=1',
    );
    $check->execute([$variant, $id]);
    $row = $check->fetch();

    if (!$row) {
        flash('Please select an available option and quantity.', 'error');
        redirect(APP_BASE . '/product.php?id=' . $id);
    }
    $cartQuantity = $pdo->prepare(
        'SELECT quantity FROM cart_items WHERE user_id=? AND variant_id=?',
    );
    $cartQuantity->execute([current_user()['id'], $variant]);
    $alreadyInCart = (int) ($cartQuantity->fetchColumn() ?: 0);
    if ($qty + $alreadyInCart > (int) $row['stock_quantity']) {
        flash('The requested quantity exceeds the available stock.', 'error');
        redirect(APP_BASE . '/product.php?id=' . $id);
    }

    $up = $pdo->prepare(
        'INSERT INTO cart_items(user_id,variant_id,quantity)
        VALUES(?,?,?)
        ON DUPLICATE KEY UPDATE quantity=quantity+VALUES(quantity)',
    );
    $up->execute([current_user()['id'], $variant, $qty]);
    if ($action === 'checkout') {
        redirect(APP_BASE . '/checkout.php');
    }
    flash('Added to your cart.');
    redirect(APP_BASE . '/cart.php');
}

$pageTitle = $p['product_name'];
require __DIR__ . '/includes/header.php';
?>

<div class="pdp">
    <div class="gallery">
        <div class="product-image">
            <?php if ($image): ?>
                <img
                    data-main-img
                    src="<?= APP_BASE . '/' . e($image['image_path']) ?>"
                    alt="<?= e($image['alt_text'] ?? $p['product_name']) ?>"
                />
            <?php else: ?>
                Product image
            <?php endif; ?>
        </div>

        <?php if (count($images) > 1): ?>
            <div class="thumbs" aria-label="Product photos">
                <?php foreach ($images as $index => $galleryImage): ?>
                    <button
                        type="button"
                        data-thumb="<?= APP_BASE . '/' . e($galleryImage['image_path']) ?>"
                        aria-current="<?= $index === 0 ? 'true' : 'false' ?>"
                        aria-label="Show photo <?= $index + 1 ?>"
                    >
                        <img
                            src="<?= APP_BASE . '/' . e($galleryImage['image_path']) ?>"
                            alt=""
                        />
                    </button>
                <?php endforeach; ?>
            </div>
        <?php endif; ?>
    </div>

    <section class="pdp-info">
        <div class="eyebrow"><?= e($p['category_name'] . ($p['type_name'] ? ' / ' . $p['type_name'] : '')) ?></div>
        <h1 class="page-title"><?= e($p['product_name']) ?></h1>
        <div class="price">₱<?= number_format((float) $p['base_price'], 2) ?></div>
        <p><?= nl2br(e($p['description'] ?? '')) ?></p>
        <?php if ($variants): ?>
            <?php
            $availableSizes = [];
            $availableColors = [];
            $variantOptions = [];
            foreach ($variants as $variantOption) {
                $sizeKey = (string) ($variantOption['size_id'] ?? 0);
                $colorKey = (string) ($variantOption['color_id'] ?? 0);
                $availableSizes[$sizeKey] = $variantOption['size_name'] ?? 'One size';
                $availableColors[$colorKey] = $variantOption['color_name'] ?? 'Default';
                $variantOptions[$sizeKey . ':' . $colorKey] = [
                    'id' => (int) $variantOption['variant_id'],
                    'stock' => (int) $variantOption['stock_quantity'],
                ];
            }
            ?>
            <form method="post" data-variant-options="<?= e(
                json_encode($variantOptions, JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT),
            ) ?>">
                <input type="hidden" name="csrf" value="<?= e(csrf_token()) ?>" />
                <input type="hidden" name="variant_id" value="" />
                <label for="size-option">Size</label>
                <select id="size-option" name="size_option" required>
                    <option value="">Select size</option>
                    <?php foreach ($availableSizes as $sizeId => $sizeName): ?>
                        <option value="<?= e($sizeId) ?>"><?= e($sizeName) ?></option>
                    <?php endforeach; ?>
                </select>
                <label for="color-option">Color</label>
                <select id="color-option" name="color_option" required>
                    <option value="">Select color</option>
                    <?php foreach ($availableColors as $colorId => $colorName): ?>
                        <option value="<?= e($colorId) ?>"><?= e($colorName) ?></option>
                    <?php endforeach; ?>
                </select>
                <p class="muted" data-variant-stock aria-live="polite">Select a size and color.</p>
                <label>Quantity</label>
                <input type="number" name="quantity" min="1" value="1" max="99" />
                <div class="pdp-actions">
                    <button type="submit" name="action" value="add_to_cart" disabled>Add to cart</button>
                    <button type="submit" name="action" value="checkout" disabled>Checkout</button>
                </div>
            </form>
            <script>
                document.querySelectorAll('[data-variant-options]').forEach(function (form) {
                    var options = JSON.parse(form.dataset.variantOptions);
                    var size = form.querySelector('[name="size_option"]');
                    var color = form.querySelector('[name="color_option"]');
                    var variant = form.querySelector('[name="variant_id"]');
                    var stockMessage = form.querySelector('[data-variant-stock]');
                    var buttons = form.querySelectorAll('button[type="submit"]');

                    function updateVariant() {
                        var selected = options[size.value + ':' + color.value];
                        variant.value = selected ? selected.id : '';
                        buttons.forEach(function (button) {
                            button.disabled = !selected || selected.stock < 1;
                        });
                        stockMessage.textContent = !size.value || !color.value
                            ? 'Select a size and color.'
                            : !selected
                                ? 'This size and color combination is unavailable.'
                                : selected.stock < 1
                                    ? 'Out of stock.'
                                    : selected.stock + ' in stock.';
                    }

                    size.addEventListener('change', updateVariant);
                    color.addEventListener('change', updateVariant);
                });
            </script>
        <?php else: ?>
            <p class="muted">Options are currently unavailable.</p>
        <?php endif; ?>
    </section>
</div>

<section id="reviews">
    <h2>Customer reviews</h2>
    <?php if ($reviewError): ?>
        <div class="notice error"><?= e($reviewError) ?></div>
    <?php endif; ?>
    <?php if (!$reviews): ?>
        <p class="muted">No reviews yet.</p>
    <?php endif; ?>
    <?php foreach ($reviews as $r): ?>
        <article class="review">
            <b><?= e($r['first_name'] . ' ' . $r['last_name']) ?></b>
            <span class="stars" aria-label="<?= (int) $r['rating'] ?> out of 5">
                <?= str_repeat('★', (int) $r['rating']) ?>
            </span>
            <p><?= nl2br(e($r['review_text'])) ?></p>
            <small><?= e($r['created_at']) ?></small>
        </article>
    <?php endforeach; ?>

    <?php if (current_user()): ?>
        <form class="form-card" style="margin-left: 0" method="post">
            <input type="hidden" name="csrf" value="<?= e(csrf_token()) ?>" />
            <input type="hidden" name="action" value="review" />
            <label>Rating (1-5)</label>
            <select name="rating">
                <option value="5">5 - Excellent</option>
                <option value="4">4 - Good</option>
                <option value="3">3 - Average</option>
                <option value="2">2 - Poor</option>
                <option value="1">1 - Bad</option>
            </select>
            <label>Your review</label>
            <textarea name="review_text"></textarea>
            <button>Submit / update review</button>
        </form>
    <?php else: ?>
        <p>
            <a href="<?= APP_BASE ?>/user/login.php">Sign in</a>
            to review a product you purchased.
        </p>
    <?php endif; ?>
</section>

<?php require __DIR__ . '/includes/footer.php'; ?>
