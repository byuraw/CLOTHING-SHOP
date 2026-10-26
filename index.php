<?php
require_once __DIR__ . "/includes/functions.php";

$search = trim($_GET["q"] ?? "");
$base = "
    SELECT
        p.product_id,
        p.product_name,
        p.base_price,
        c.product_category_id AS category_id,
        c.category_name,
        (
            SELECT pi.image_path
            FROM product_images pi
            WHERE pi.product_id = p.product_id
            ORDER BY pi.sort_order
            LIMIT 1
        ) AS image_path,
        (
            SELECT ROUND(AVG(r.rating))
            FROM product_reviews r
            WHERE r.product_id = p.product_id
        ) AS rating
    FROM products p
    JOIN product_categories c ON c.product_category_id = p.product_category_id
    WHERE p.is_active = 1 AND c.is_active = 1
";

if ($search !== "") {
    $q = $pdo->prepare(
        $base .
            " AND (p.product_name LIKE ? OR p.description LIKE ?) ORDER BY p.created_at DESC LIMIT 24",
    );
    $q->execute(["%" . $search . "%", "%" . $search . "%"]);
} else {
    $q = $pdo->query($base . " ORDER BY p.created_at DESC LIMIT 40");
}

$products = $q->fetchAll();
$categories = $pdo
    ->query(
        "SELECT product_category_id AS category_id, category_name FROM product_categories WHERE is_active = 1 ORDER BY category_name",
    )
    ->fetchAll();
$isHome = $search === "";
$pageTitle = "Home";
$fullWidth = $isHome;
$bodyClass = $isHome ? "home" : "";

require __DIR__ . "/includes/header.php";

function hero_image(int $n): string
{
    return APP_BASE . "/uploads/clothing-store-model($n).png";
}

function product_card(array $p, bool $hidden = false): void
{
    ?>
    <article class="card" data-cat="<?= (int) $p[
        "category_id"
    ] ?>"<?= $hidden ? " hidden" : "" ?>>
        <a href="/clothing-store-backup/product.php?id=<?= (int) $p[
            "product_id"
        ] ?>">
            <div class="product-image">
                <?php if ($p["image_path"]): ?>
                    <img
                        src="/clothing-store-backup/<?= e($p["image_path"]) ?>"
                        alt="<?= e($p["product_name"]) ?>"
                        loading="lazy"
                    >
                <?php else: ?>
                    Product image
                <?php endif; ?>
            </div>
            <div class="card-info">
                <div class="card-cat"><?= e($p["category_name"]) ?></div>
                <h3><?= e($p["product_name"]) ?></h3>
                <div class="price">₱<?= number_format(
                    (float) $p["base_price"],
                    2,
                ) ?></div>
                <?php if ($p["rating"]): ?>
                    <div class="stars" aria-label="Rated <?= (int) $p[
                        "rating"
                    ] ?> out of 5">
                        <?= str_repeat("★", (int) $p["rating"]) ?>
                    </div>
                <?php endif; ?>
            </div>
        </a>
    </article>
    <?php
}
?>

<?php if ($isHome): ?>
    <section class="hero-slider" aria-roledescription="carousel" aria-label="Featured">
        <div class="hero-slide active" aria-hidden="false">
            <img class="hero-image" src="<?= e(hero_image(1)) ?>" alt="" aria-hidden="true">
            <div class="hero-copy">
                <small>New season collection</small>
                <h1>Style made for every day</h1>
                <a class="button light" href="/clothing-store-backup/shop.php">Discover now</a>
            </div>
        </div>
        <div class="hero-slide" aria-hidden="true">
            <img class="hero-image" src="<?= e(hero_image(2)) ?>" alt="" aria-hidden="true">
            <div class="hero-copy">
                <small>Made to move</small>
                <h2>Find your new favorites</h2>
                <a class="button light" href="#new">Shop new arrivals</a>
            </div>
        </div>
        <div class="hero-slide" aria-hidden="true">
            <img class="hero-image" src="<?= e(hero_image(3)) ?>" alt="" aria-hidden="true">
            <div class="hero-copy">
                <small>Everyday essentials</small>
                <h2>Make room for more style</h2>
                <a class="button light" href="/clothing-store-backup/shop.php">Shop the collection</a>
            </div>
        </div>
        <button type="button" class="hero-arrow prev" aria-label="Previous slide">
            <svg viewBox="0 0 24 24"><path d="m15 5-7 7 7 7"/></svg>
        </button>
        <button type="button" class="hero-arrow next" aria-label="Next slide">
            <svg viewBox="0 0 24 24"><path d="m9 5 7 7-7 7"/></svg>
        </button>
    </section>

    <?php if ($notice): ?>
        <div class="wrap home-notice">
            <div class="notice <?= e($notice[1]) ?>"><?= e($notice[0]) ?></div>
        </div>
    <?php endif; ?>

    <section class="arrivals wrap" id="new">
        <h2>New arrivals</h2>
        <?php if ($categories): ?>
            <div class="tabs" role="tablist">
                <button type="button" role="tab" data-tab="all" aria-selected="true">All</button>
                <?php foreach ($categories as $c): ?>
                    <button
                        type="button"
                        role="tab"
                        data-tab="<?= (int) $c["category_id"] ?>"
                        aria-selected="false"
                    >
                        <?= e($c["category_name"]) ?>
                    </button>
                <?php endforeach; ?>
            </div>
        <?php endif; ?>

        <div class="grid">
            <?php foreach ($products as $i => $p): ?>
                <?php product_card($p, $i >= 8); ?>
            <?php endforeach; ?>
        </div>

        <?php if (!$products): ?>
            <div class="empty">No products yet. Add some from the admin panel.</div>
        <?php endif; ?>
    </section>

    <?php
    $tiles = array_slice($categories, 0, 4);
    if (count($tiles) >= 1): ?>
        <section class="wrap promos" aria-label="Shop by category">
            <?php $t = $tiles[0]; ?>
            <a class="promo tall a" href="/clothing-store-backup/shop.php?category=<?= (int) $t[
                "category_id"
            ] ?>">
                <small>Shop by category</small>
                <h3><?= e($t["category_name"]) ?></h3>
                <span class="button">Shop now</span>
            </a>

            <?php if (isset($tiles[1])): ?>
                <?php $t = $tiles[1]; ?>
                <a class="promo b" href="/clothing-store-backup/shop.php?category=<?= (int) $t[
                    "category_id"
                ] ?>">
                    <small>Shop by category</small>
                    <h3><?= e($t["category_name"]) ?></h3>
                    <span class="button">Shop now</span>
                </a>
            <?php endif; ?>

            <div class="promo-bottom">
                <?php if (isset($tiles[2])): ?>
                    <?php $t = $tiles[2]; ?>
                    <a class="promo c" href="/clothing-store-backup/shop.php?category=<?= (int) $t[
                        "category_id"
                    ] ?>">
                        <small>Shop by category</small>
                        <h3><?= e($t["category_name"]) ?></h3>
                        <span class="button">Shop now</span>
                    </a>
                <?php endif; ?>

                <a class="promo blue" href="/clothing-store-backup/shop.php">
                    <h3>Free shipping</h3>
                    <div class="big">₱0</div>
                    <span class="button">Shop now</span>
                </a>
            </div>
        </section>
    <?php endif;
    ?>
<?php else: ?>
    <div class="wrap" style="margin:44px auto">
        <div class="section-head">
            <h1 class="page-title">Search results for “<?= e($search) ?>”</h1>
            <a href="<?= APP_BASE ?>/index.php">Clear search</a>
        </div>
        <div class="grid shop-grid">
            <?php foreach ($products as $p): ?>
                <?php product_card($p); ?>
            <?php endforeach; ?>
        </div>
        <?php if (!$products): ?>
            <div class="empty">No products match your search. Try another word.</div>
        <?php endif; ?>
    </div>
<?php endif; ?>

<?php require __DIR__ . "/includes/footer.php"; ?>
