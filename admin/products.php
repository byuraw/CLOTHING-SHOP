<?php
require_once __DIR__ . "/../includes/functions.php";
require_admin();
$error = "";
$postString = static fn(string $key): string => is_string($_POST[$key] ?? null)
    ? $_POST[$key]
    : "";
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
            $pid = filter_var(
                $_POST["product_id"] ?? null,
                FILTER_VALIDATE_INT,
            );
            if ($pid === false || $pid < 1) {
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
                        trim($postString("alt_text")),
                        $count++,
                    ]);
                }
            }
            if ($count) {
                flash("Product photos uploaded.");
            } else {
                flash("Choose at least one photo.", "error");
            }
        } elseif ($action === "product") {
            $name = trim($postString("product_name"));
            $categoryId = filter_var(
                $_POST["product_category_id"] ?? null,
                FILTER_VALIDATE_INT,
            );
            $description = trim($postString("description"));
            $slug =
                strtolower(
                    trim(preg_replace("/[^a-z0-9]+/i", "-", $name), "-"),
                ) .
                "-" .
                bin2hex(random_bytes(2));
            if (
                $name === "" ||
                mb_strlen($name) > 180 ||
                $categoryId === false ||
                $categoryId < 1 ||
                $description === ""
            ) {
                throw new RuntimeException(
                    "Enter a product name of at most 180 characters, choose a category, and enter a description.",
                );
            }
            $typeValue = trim($postString("product_type_id"));
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
            $sizeId = filter_var($_POST["size_id"] ?? null, FILTER_VALIDATE_INT);
            $colorId = filter_var($_POST["color_id"] ?? null, FILTER_VALIDATE_INT);
            $priceInput = trim($postString("variant_price"));
            $priceValid =
                preg_match('/^\d+(?:\.\d{1,2})?$/D', $priceInput) === 1 &&
                strlen(ltrim(explode(".", $priceInput, 2)[0], "0")) <= 8;
            $variantPrice = $priceValid ? (float) $priceInput : false;
            $stock = filter_var(
                $_POST["stock_quantity"] ?? null,
                FILTER_VALIDATE_INT,
            );
            if (
                $sizeId === false ||
                $sizeId < 1 ||
                $colorId === false ||
                $colorId < 1 ||
                !$priceValid ||
                $stock === false ||
                $stock < 0 ||
                $stock > 4294967295
            ) {
                throw new RuntimeException(
                    "Choose a size and color, then enter a valid variant price and starting stock.",
                );
            }
            $optionCheck = $pdo->prepare(
                "SELECT
                    (SELECT COUNT(*) FROM sizes WHERE size_id=?) AS size_exists,
                    (SELECT COUNT(*) FROM colors WHERE color_id=?) AS color_exists",
            );
            $optionCheck->execute([$sizeId, $colorId]);
            $validOptions = $optionCheck->fetch();
            if (!$validOptions["size_exists"] || !$validOptions["color_exists"]) {
                throw new RuntimeException("Choose a valid size and color.");
            }
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
                    "INSERT INTO products(product_category_id,product_type_id,product_name,slug,description,is_active) VALUES(?,?,?,?,?,1)",
                );
                $q->execute([
                    $categoryId,
                    $typeId,
                    $name,
                    $slug,
                    $description,
                ]);
                $newPid = (int) $pdo->lastInsertId();
                $sku = clothing_sku(
                    $catalogInfo["category_name"],
                    $catalogInfo["type_name"],
                    $name,
                    $sizeId,
                    $colorId,
                );

                $variant = $pdo->prepare(
                    "INSERT INTO product_variants(product_id,size_id,color_id,sku,price,stock_quantity,is_active) VALUES(?,?,?,?,?,?,1)",
                );
                $variant->execute([
                    $newPid,
                    $sizeId,
                    $colorId,
                    $sku,
                    number_format($variantPrice, 2, ".", ""),
                    $stock,
                ]);
                if ($stock > 0) {
                    $expenseAmount = restock_expense_amount(
                        number_format($variantPrice, 2, ".", ""),
                        $stock,
                    );
                    $expense = $pdo->prepare(
                        "INSERT INTO expenses(recorded_by,expense_name,amount,expense_date,notes) VALUES(?,?,?,?,?)",
                    );
                    $expense->execute([
                        current_user()["id"],
                        "Adding Product",
                        $expenseAmount,
                        date("Y-m-d"),
                        'Adding "' . $name . '" on the store',
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
        } elseif ($action === "delete") {
            $pid = filter_var(
                $_POST["product_id"] ?? null,
                FILTER_VALIDATE_INT,
            );
            if ($pid === false || $pid < 1) {
                throw new RuntimeException("Choose a valid product.");
            }
            $pdo->beginTransaction();
            try {
                $product = $pdo->prepare(
                    "SELECT product_id FROM products WHERE product_id=? AND is_active=1 FOR UPDATE",
                );
                $product->execute([$pid]);
                if (!$product->fetchColumn()) {
                    throw new RuntimeException("Choose an active product.");
                }
                $pdo->prepare(
                    "UPDATE products SET is_active=0 WHERE product_id=?",
                )->execute([$pid]);
                $pdo->prepare(
                    "UPDATE product_variants SET is_active=0 WHERE product_id=?",
                )->execute([$pid]);
                $pdo->commit();
            } catch (Throwable $e) {
                if ($pdo->inTransaction()) {
                    $pdo->rollBack();
                }
                throw $e;
            }
            flash("Product deleted successfully and removed from the store.");
            redirect(
                APP_BASE . "/admin/products.php#delete-product-panel",
            );
        } elseif ($action === "edit") {
            $pid = (int) ($_POST["product_id"] ?? 0);
            $name = trim($postString("product_name"));
            $categoryId = filter_var(
                $_POST["product_category_id"] ?? null,
                FILTER_VALIDATE_INT,
            );
            $typeId = filter_var(
                $_POST["product_type_id"] ?? null,
                FILTER_VALIDATE_INT,
            );
            $description = trim($postString("description"));
            if (
                !$pid ||
                $name === "" ||
                mb_strlen($name) > 180 ||
                $categoryId === false ||
                $categoryId < 1 ||
                $typeId === false ||
                $typeId < 1 ||
                $description === ""
            ) {
                throw new RuntimeException(
                    "Enter a product name of at most 180 characters, choose a valid category and type, and enter a description.",
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
                INNER JOIN product_types ON product_type_id=?
                WHERE product_category_id=? AND is_active=1',
            );
            $catalogInfo->execute([$typeId, $categoryId]);
            $catalogInfo = $catalogInfo->fetch();
            if (!$catalogInfo) {
                throw new RuntimeException(
                    "Choose a valid product category and type.",
                );
            }
            $pdo->beginTransaction();
            try {
                $q = $pdo->prepare(
                    "UPDATE products SET product_category_id=?,product_type_id=?,product_name=?,slug=?,description=? WHERE product_id=?",
                );
                $q->execute([
                    $categoryId,
                    $typeId,
                    $name,
                    $slug,
                    $description,
                    $pid,
                ]);
                $variants = $pdo->prepare(
                    "SELECT variant_id,size_id,color_id FROM product_variants WHERE product_id=? FOR UPDATE",
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
            $pid = filter_var(
                $_POST["product_id"] ?? null,
                FILTER_VALIDATE_INT,
            );
            $priceInput = trim($postString("price"));
            $priceValid =
                preg_match('/^\d+(?:\.\d{1,2})?$/D', $priceInput) === 1 &&
                strlen(ltrim(explode(".", $priceInput, 2)[0], "0")) <= 8;
            $price = $priceValid ? (float) $priceInput : false;
            $stock = filter_var(
                $_POST["stock_quantity"] ?? null,
                FILTER_VALIDATE_INT,
            );
            if (
                $pid === false ||
                $pid < 1 ||
                !$priceValid ||
                $stock === false ||
                $stock < 0 ||
                $stock > 4294967295
            ) {
                throw new RuntimeException(
                    "Select a product and enter a valid price and starting stock.",
                );
            }
            $product = $pdo->prepare(
                "SELECT p.product_name,pc.category_name,pt.type_name FROM products p INNER JOIN product_categories pc ON pc.product_category_id=p.product_category_id INNER JOIN product_types pt ON pt.product_type_id=p.product_type_id WHERE p.product_id=? AND p.is_active=1",
            );
            $product->execute([$pid]);
            $product = $product->fetch();
            if (!$product) {
                throw new RuntimeException("Choose a valid product.");
            }
            $sizeValue = trim($postString("size_id"));
            $colorValue = trim($postString("color_id"));
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
            $optionCheck = $pdo->prepare(
                "SELECT
                    (SELECT COUNT(*) FROM sizes WHERE size_id=?) AS size_exists,
                    (SELECT COUNT(*) FROM colors WHERE color_id=?) AS color_exists",
            );
            $optionCheck->execute([$sizeId, $colorId]);
            $validOptions = $optionCheck->fetch();
            if (
                ($sizeId !== null && !$validOptions["size_exists"]) ||
                ($colorId !== null && !$validOptions["color_exists"])
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
            $q->execute([
                $pid,
                $sizeId,
                $colorId,
                $sku,
                number_format($price, 2, ".", ""),
                $stock,
            ]);
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
                    "SELECT v.stock_quantity,v.price,p.product_name
                    FROM product_variants v
                    INNER JOIN products p ON p.product_id=v.product_id
                    WHERE v.variant_id=? AND v.is_active=1 AND p.is_active=1
                    FOR UPDATE",
                );
                $variantQuery->execute([$variantId]);
                $currentStock = $variantQuery->fetch();
                if ($currentStock === false) {
                    throw new RuntimeException(
                        "Choose an active product variant.",
                    );
                }
                if (
                    $quantity >
                    4294967295 - (int) $currentStock["stock_quantity"]
                ) {
                    throw new RuntimeException(
                        "The restock quantity exceeds the maximum stock level.",
                    );
                }
                $expenseAmount = restock_expense_amount(
                    (string) $currentStock["price"],
                    $quantity,
                );
                $saveStock = $pdo->prepare(
                    "UPDATE product_variants SET stock_quantity=stock_quantity+? WHERE variant_id=?",
                );
                $saveStock->execute([$quantity, $variantId]);
                $expense = $pdo->prepare(
                    "INSERT INTO expenses(recorded_by,expense_name,amount,expense_date,notes) VALUES(?,?,?,?,?)",
                );
                $expense->execute([
                    current_user()["id"],
                    "Product restock",
                    $expenseAmount,
                    date("Y-m-d"),
                    "restock (" . $currentStock["product_name"] . ")",
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
        } elseif ($action === "delete_photo") {
            $imageId = filter_var(
                $_POST["image_id"] ?? null,
                FILTER_VALIDATE_INT,
            );
            if ($imageId === false || $imageId < 1) {
                throw new RuntimeException("Choose a valid product photo.");
            }
            $imageQuery = $pdo->prepare(
                "SELECT image_path FROM product_images WHERE image_id=?",
            );
            $imageQuery->execute([$imageId]);
            $imagePath = $imageQuery->fetchColumn();
            if ($imagePath === false) {
                throw new RuntimeException("Choose a valid product photo.");
            }
            $photoDirectory = realpath(__DIR__ . "/../uploads/products");
            $storedImagePath = str_replace("\\", "/", (string) $imagePath);
            if (!str_starts_with($storedImagePath, "uploads/products/")) {
                throw new RuntimeException(
                    "The product photo path is outside its upload folder.",
                );
            }
            $photoFile = $photoDirectory === false
                ? false
                : realpath(
                    $photoDirectory .
                        DIRECTORY_SEPARATOR .
                        basename($storedImagePath),
                );
            if (
                $photoDirectory === false ||
                $photoFile === false ||
                strncasecmp(
                    $photoFile,
                    rtrim($photoDirectory, DIRECTORY_SEPARATOR) .
                        DIRECTORY_SEPARATOR,
                    strlen(rtrim($photoDirectory, DIRECTORY_SEPARATOR) .
                        DIRECTORY_SEPARATOR),
                ) !== 0 ||
                !is_file($photoFile)
            ) {
                throw new RuntimeException(
                    "The product photo file is missing or outside its upload folder.",
                );
            }
            if (!unlink($photoFile)) {
                throw new RuntimeException("Could not delete the product photo file.");
            }
            $pdo->prepare(
                "DELETE FROM product_images WHERE image_id=?",
            )->execute([$imageId]);
            flash("Product photo deleted.");
        } elseif ($action === "main_photo") {
            $imageId = filter_var(
                $_POST["image_id"] ?? null,
                FILTER_VALIDATE_INT,
            );
            if ($imageId === false || $imageId < 1) {
                throw new RuntimeException("Choose a valid product photo.");
            }
            $imageQuery = $pdo->prepare(
                "SELECT product_id FROM product_images WHERE image_id=?",
            );
            $imageQuery->execute([$imageId]);
            $photoProductId = $imageQuery->fetchColumn();
            if ($photoProductId === false) {
                throw new RuntimeException("Choose a valid product photo.");
            }
            $imageIds = $pdo->prepare(
                "SELECT image_id FROM product_images
                WHERE product_id=?
                ORDER BY sort_order,image_id",
            );
            $imageIds->execute([$photoProductId]);
            $orderedImageIds = array_map(
                "intval",
                $imageIds->fetchAll(PDO::FETCH_COLUMN),
            );
            $pdo->beginTransaction();
            try {
                $saveOrder = $pdo->prepare(
                    "UPDATE product_images SET sort_order=? WHERE image_id=? AND product_id=?",
                );
                $saveOrder->execute([0, $imageId, $photoProductId]);
                $sortOrder = 1;
                foreach ($orderedImageIds as $orderedImageId) {
                    if ($orderedImageId !== (int) $imageId) {
                        $saveOrder->execute([
                            $sortOrder++,
                            $orderedImageId,
                            $photoProductId,
                        ]);
                    }
                }
                $pdo->commit();
            } catch (Throwable $e) {
                if ($pdo->inTransaction()) {
                    $pdo->rollBack();
                }
                throw $e;
            }
            flash("Main product photo updated.");
        }
        redirect(
            APP_BASE .
                "/admin/products.php" .
                (in_array(
                    $action,
                    ["images", "delete_photo", "main_photo"],
                    true,
                )
                    ? "#update-product-panel"
                    : ""),
        );
    } catch (Throwable $e) {
        $error =
            $e instanceof RuntimeException
                ? $e->getMessage()
                : "Could not save. Check duplicate SKU and database setup.";
    }
}
$postedAction = is_string($_POST["action"] ?? null) ? $_POST["action"] : "";
$postedProductId = filter_var(
    $_POST["product_id"] ?? null,
    FILTER_VALIDATE_INT,
);
$postedValue = static fn(string $key): string => is_scalar($_POST[$key] ?? null)
    ? (string) $_POST[$key]
    : "";
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
    INNER JOIN products p ON p.product_id=v.product_id
    INNER JOIN product_categories pc ON pc.product_category_id=p.product_category_id
    INNER JOIN product_types pt ON pt.product_type_id=p.product_type_id
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
        "SELECT p.product_id,p.product_name,p.description,p.product_category_id,p.product_type_id,
            (SELECT MIN(v2.price) FROM product_variants v2 WHERE v2.product_id=p.product_id AND v2.is_active=1) AS from_price,
            pc.category_name,pt.type_name,
            (SELECT COUNT(*) FROM product_variants v WHERE v.product_id=p.product_id AND v.is_active=1) variants
        FROM products p
        INNER JOIN product_categories pc ON pc.product_category_id=p.product_category_id
        INNER JOIN product_types pt ON pt.product_type_id=p.product_type_id
        WHERE p.is_active=1
        ORDER BY p.created_at DESC",
    )
    ->fetchAll();
$productImageQuery = $pdo->query(
    "SELECT image_id,product_id,image_path,alt_text,sort_order
    FROM product_images
    ORDER BY product_id,sort_order,image_id",
);
$productImages = [];
foreach ($productImageQuery->fetchAll() as $productImage) {
    $productImages[(int) $productImage["product_id"]][] = $productImage;
}
$deleteList = $pdo
    ->query(
        "SELECT p.product_id,p.product_name,p.description,p.product_category_id,v.price AS variant_price,
            pc.category_name,pt.type_name,v.size_id,v.color_id,
            COALESCE(s.size_name,'One size') size_name,
            COALESCE(c.color_name,'Default') color_name
        FROM products p
        INNER JOIN product_categories pc ON pc.product_category_id=p.product_category_id
        INNER JOIN product_types pt ON pt.product_type_id=p.product_type_id
        LEFT JOIN product_variants v ON v.product_id=p.product_id AND v.is_active=1
        LEFT JOIN sizes s ON s.size_id=v.size_id
        LEFT JOIN colors c ON c.color_id=v.color_id
        WHERE p.is_active=1
        ORDER BY p.created_at DESC,p.product_name,s.size_name,c.color_name",
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
    id="delete-product-tab"
    role="tab"
    aria-controls="delete-product-panel"
    aria-selected="false"
    data-product-tab="delete-product-panel"
  >Delete product</button>
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
  <form class="form-card product-create-form" method="post" enctype="multipart/form-data" novalidate>
    <h2>Add new product</h2>
    <input type="hidden" name="csrf" value="<?= e(
        csrf_token(),
    ) ?>" />
    <input type="hidden" name="action" value="product" />
    <label for="new-product-name">Name</label>
    <input id="new-product-name" name="product_name" value="<?= e($postedAction === "product" ? $postedValue("product_name") : "") ?>">
    <label for="new-product-category">Product category</label>
    <select id="new-product-category" name="product_category_id">
      <option value="">Choose a category</option>
      <?php foreach ($cats as $c): ?>
      <option value="<?= (int) $c["product_category_id"] ?>" <?= $postedAction === "product" && $postedValue("product_category_id") === (string) $c["product_category_id"] ? "selected" : "" ?>><?= e(
          $c["category_name"],
      ) ?></option>
      <?php endforeach; ?>
    </select>
    <label for="new-product-type">Type</label>
    <select id="new-product-type" name="product_type_id">
      <option value="">Choose a type</option>
      <?php foreach ($types as $t): ?>
      <option value="<?= (int) $t["product_type_id"] ?>" <?= $postedAction === "product" && $postedValue("product_type_id") === (string) $t["product_type_id"] ? "selected" : "" ?>><?= e(
          $t["type_name"],
      ) ?></option>
      <?php endforeach; ?>
    </select>
    <label for="new-product-description">Description</label>
    <textarea id="new-product-description" name="description"><?= e($postedAction === "product" ? $postedValue("description") : "") ?></textarea>
    <h2>Initial size/color variant</h2>
    <label for="new-product-size">Size</label>
    <select id="new-product-size" name="size_id">
      <option value="">Choose a size</option>
      <?php foreach ($sizes as $s): ?>
      <option value="<?= (int) $s["size_id"] ?>" <?= $postedAction === "product" && $postedValue("size_id") === (string) $s["size_id"] ? "selected" : "" ?>><?= e(
          $s["size_name"],
      ) ?></option>
      <?php endforeach; ?>
    </select>
    <label for="new-product-color">Color</label>
    <select id="new-product-color" name="color_id">
      <option value="">Choose a color</option>
      <?php foreach ($colors as $c): ?>
      <option value="<?= (int) $c["color_id"] ?>" <?= $postedAction === "product" && $postedValue("color_id") === (string) $c["color_id"] ? "selected" : "" ?>><?= e(
          $c["color_name"],
      ) ?></option>
      <?php endforeach; ?>
    </select>
    <label for="new-product-variant-price">Price</label>
    <input id="new-product-variant-price" name="variant_price" type="text" value="<?= e($postedAction === "product" ? $postedValue("variant_price") : "") ?>">
    <label for="new-product-stock">Starting stock</label>
    <input id="new-product-stock" name="stock_quantity" type="text" value="<?= e($postedAction === "product" ? $postedValue("stock_quantity") : "") ?>">
    <label for="new-product-photos">Product photos</label>
    <input id="new-product-photos" type="file" name="photos[]" multiple accept="image/jpeg,image/png,image/webp,image/gif">
    <button type="submit">Create product</button>
  </form>

  <form class="form-card" method="post" novalidate>
    <h2>Add variant</h2>
    <input type="hidden" name="csrf" value="<?= e(csrf_token()) ?>">
    <input type="hidden" name="action" value="variant">
    <label for="variant-product">Product</label>
    <select id="variant-product" name="product_id">
      <option value="">Choose a product</option>
      <?php foreach ($products as $product): ?>
        <option value="<?= (int) $product["product_id"] ?>" <?= $postedAction === "variant" && $postedValue("product_id") === (string) $product["product_id"] ? "selected" : "" ?>><?= e($product["product_name"]) ?></option>
      <?php endforeach; ?>
    </select>
    <label for="variant-size">Size</label>
    <select id="variant-size" name="size_id">
      <option value="">One size</option>
      <?php foreach ($sizes as $size): ?>
        <option value="<?= (int) $size["size_id"] ?>" <?= $postedAction === "variant" && $postedValue("size_id") === (string) $size["size_id"] ? "selected" : "" ?>><?= e($size["size_name"]) ?></option>
      <?php endforeach; ?>
    </select>
    <label for="variant-color">Color</label>
    <select id="variant-color" name="color_id">
      <option value="">Default color</option>
      <?php foreach ($colors as $color): ?>
        <option value="<?= (int) $color["color_id"] ?>" <?= $postedAction === "variant" && $postedValue("color_id") === (string) $color["color_id"] ? "selected" : "" ?>><?= e($color["color_name"]) ?></option>
      <?php endforeach; ?>
    </select>
    <label for="variant-price">Price</label>
    <input id="variant-price" type="text" name="price" value="<?= e($postedAction === "variant" ? $postedValue("price") : "") ?>">
    <label for="variant-stock">Starting stock</label>
    <input id="variant-stock" type="text" name="stock_quantity" value="<?= e($postedAction === "variant" ? $postedValue("stock_quantity") : "") ?>">
    <button type="submit">Add variant</button>
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
<div class="update-product-toolbar">
  <div class="search">
    <svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/></svg>
    <label for="update-product-search" class="sr-only">Search products to update</label>
    <input
      id="update-product-search"
      type="search"
      placeholder="Search products by name, category, type, description…"
      data-table-filter
    >
  </div>
</div>
<div class="table-wrap">
  <table class="product-edit-table">
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
      <?php
      $editFormId = "edit-product-" . (int) $p["product_id"];
      $restoreEdit = $postedAction === "edit" &&
          $postedProductId === (int) $p["product_id"];
      ?>
      <tr data-search="<?= e(
          implode(" ", [
              $p["product_id"],
              $p["product_name"],
              $p["description"] ?? "",
              $p["category_name"],
              $p["type_name"],
              $p["from_price"] ?? "",
          ]),
      ) ?>">
        <td>
          <form method="post" id="<?= e($editFormId) ?>" novalidate>
            <input type="hidden" name="csrf" value="<?= e(csrf_token()) ?>">
            <input type="hidden" name="action" value="edit">
            <input type="hidden" name="product_id" value="<?= (int) $p["product_id"] ?>">
          </form>
          <label class="sr-only" for="<?= e($editFormId) ?>-name">Product name</label>
          <input
            id="<?= e($editFormId) ?>-name"
            form="<?= e($editFormId) ?>"
            name="product_name"
            value="<?= e($restoreEdit ? $postedValue("product_name") : $p["product_name"]) ?>"
          >
          <label class="sr-only" for="<?= e($editFormId) ?>-description">Product description</label>
          <textarea
            id="<?= e($editFormId) ?>-description"
            form="<?= e($editFormId) ?>"
            name="description"
          ><?= e($restoreEdit ? $postedValue("description") : ($p["description"] ?? "")) ?></textarea>
          <?php foreach ($productImages[(int) $p["product_id"]] ?? [] as $productImage): ?>
            <div>
              <img
                src="<?= APP_BASE . "/" . e($productImage["image_path"]) ?>"
                alt="<?= e($productImage["alt_text"] ?? $p["product_name"]) ?>"
                width="80"
              >
              <?= (int) $productImage["sort_order"] === 0 ? "Main photo" : "" ?>
              <form method="post" novalidate>
                <input type="hidden" name="csrf" value="<?= e(csrf_token()) ?>">
                <input type="hidden" name="image_id" value="<?= (int) $productImage["image_id"] ?>">
                <button type="submit" name="action" value="main_photo">Make main photo</button>
                <button type="submit" name="action" value="delete_photo" class="danger">Delete photo</button>
              </form>
            </div>
          <?php endforeach; ?>
          <form class="row" method="post" enctype="multipart/form-data" novalidate>
            <input type="hidden" name="csrf" value="<?= e(csrf_token()) ?>">
            <input type="hidden" name="action" value="images">
            <input type="hidden" name="product_id" value="<?= (int) $p["product_id"] ?>">
            <label class="sr-only" for="<?= e($editFormId) ?>-photos">Upload additional product photos</label>
            <input id="<?= e($editFormId) ?>-photos" type="file" name="photos[]" multiple accept="image/jpeg,image/png,image/webp,image/gif">
            <label class="sr-only" for="<?= e($editFormId) ?>-alt">Photo description</label>
            <input id="<?= e($editFormId) ?>-alt" type="text" name="alt_text" placeholder="Photo description" value="<?= $postedAction === "images" && $postedProductId === (int) $p["product_id"] ? e($postedValue("alt_text")) : "" ?>">
            <button type="submit">Upload photos</button>
          </form>
        </td>
        <td>
          <label class="sr-only" for="<?= e($editFormId) ?>-category">Product category</label>
          <select
            id="<?= e($editFormId) ?>-category"
            form="<?= e($editFormId) ?>"
            name="product_category_id"
          >
            <?php foreach ($cats as $category): ?>
              <option
                value="<?= (int) $category["product_category_id"] ?>"
                <?= ($restoreEdit ? $postedValue("product_category_id") === (string) $category["product_category_id"] : (int) $p["product_category_id"] === (int) $category["product_category_id"]) ? "selected" : "" ?>
              ><?= e($category["category_name"]) ?></option>
            <?php endforeach; ?>
          </select>
          <label class="sr-only" for="<?= e($editFormId) ?>-type">Product type</label>
          <select
            id="<?= e($editFormId) ?>-type"
            form="<?= e($editFormId) ?>"
            name="product_type_id"
          >
            <?php foreach ($types as $type): ?>
              <option
                value="<?= (int) $type["product_type_id"] ?>"
                <?= ($restoreEdit ? $postedValue("product_type_id") === (string) $type["product_type_id"] : (int) $p["product_type_id"] === (int) $type["product_type_id"]) ? "selected" : "" ?>
              ><?= e($type["type_name"]) ?></option>
            <?php endforeach; ?>
          </select>
        </td>
        <td>
          <?= $p["from_price"] !== null ? e(price_label((float) $p["from_price"], (float) $p["from_price"])) : "—" ?>
        </td>
        <td><?= (int) $p["variants"] ?></td>
        <td><button type="submit" form="<?= e($editFormId) ?>">Update</button></td>
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
  id="delete-product-panel"
  role="tabpanel"
  aria-labelledby="delete-product-tab"
  data-product-panel
  hidden
>
  <div class="update-product-toolbar">
    <div class="search">
      <svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/></svg>
      <label for="delete-product-search" class="sr-only">Search products to delete</label>
      <input
        id="delete-product-search"
        type="search"
        placeholder="Search products by name, category, type, description…"
        data-table-filter
      >
    </div>
  </div>
  <div class="row product-delete-filters">
    <label for="delete-category-filter">Category
      <select id="delete-category-filter" data-product-filter="category">
        <option value="">All categories</option>
        <?php foreach ($cats as $category): ?>
          <option value="<?= (int) $category["product_category_id"] ?>"><?= e($category["category_name"]) ?></option>
        <?php endforeach; ?>
      </select>
    </label>
    <label for="delete-size-filter">Size
      <select id="delete-size-filter" data-product-filter="size">
        <option value="">All sizes</option>
        <?php foreach ($sizes as $size): ?>
          <option value="<?= (int) $size["size_id"] ?>"><?= e($size["size_name"]) ?></option>
        <?php endforeach; ?>
      </select>
    </label>
    <label for="delete-color-filter">Color
      <select id="delete-color-filter" data-product-filter="color">
        <option value="">All colors</option>
        <?php foreach ($colors as $color): ?>
          <option value="<?= (int) $color["color_id"] ?>"><?= e($color["color_name"]) ?></option>
        <?php endforeach; ?>
      </select>
    </label>
  </div>
  <div class="table-wrap">
    <table>
      <thead>
        <tr>
          <th>Product</th>
          <th>Category / type</th>
          <th>Size</th>
          <th>Color</th>
          <th>Price</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <?php foreach ($deleteList as $p): ?>
          <tr
            data-search="<?= e(implode(" ", [
                $p["product_id"],
                $p["product_name"],
                $p["description"] ?? "",
                $p["category_name"],
                $p["type_name"],
                $p["size_name"],
                $p["color_name"],
                $p["variant_price"] ?? "",
            ])) ?>"
            data-category="<?= (int) $p["product_category_id"] ?>"
            data-variant-options="<?= (int) ($p["size_id"] ?? 0) ?>:<?= (int) ($p["color_id"] ?? 0) ?>"
          >
            <td><strong><?= e($p["product_name"]) ?></strong></td>
            <td><?= e($p["category_name"] . " / " . $p["type_name"]) ?></td>
            <td><?= e($p["size_name"]) ?></td>
            <td><?= e($p["color_name"]) ?></td>
            <td><?= $p["variant_price"] !== null ? "₱" . number_format((float) $p["variant_price"], 2) : "—" ?></td>
            <td>
              <form method="post" novalidate data-preserve-scroll onsubmit="return confirm('Are you sure you want to delete this product? It will no longer be available for purchase.');">
                <input type="hidden" name="csrf" value="<?= e(csrf_token()) ?>">
                <input type="hidden" name="action" value="delete">
                <input type="hidden" name="product_id" value="<?= (int) $p["product_id"] ?>">
                <button type="submit" class="danger">Delete</button>
              </form>
            </td>
          </tr>
        <?php endforeach; ?>
        <?php if (!$deleteList): ?>
          <tr><td colspan="6" class="empty-note">No products available to delete.</td></tr>
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
  <form class="row" method="get" action="<?= e(APP_BASE . "/admin/products.php#restock-product-panel") ?>" novalidate>
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
              <form class="row" method="post" action="<?= e(APP_BASE . "/admin/products.php#restock-product-panel") ?>" novalidate>
                <input type="hidden" name="csrf" value="<?= e(csrf_token()) ?>">
                <input type="hidden" name="action" value="restock">
                <input type="hidden" name="variant_id" value="<?= (int) $variant["variant_id"] ?>">
                <label class="sr-only" for="restock-quantity-<?= (int) $variant["variant_id"] ?>">Quantity to add for <?= e($variant["product_name"]) ?></label>
                <input id="restock-quantity-<?= (int) $variant["variant_id"] ?>" type="text" name="quantity" placeholder="Qty" value="<?= $postedAction === "restock" && $postedValue("variant_id") === (string) $variant["variant_id"] ? e($postedValue("quantity")) : "" ?>">
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
