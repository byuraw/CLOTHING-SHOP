<?php

declare(strict_types=1);
if (session_status() !== PHP_SESSION_ACTIVE) {
    session_start();
}
require_once __DIR__ . "/../config/database.php";
define("APP_BASE", "/clothing-store-backup");
function e(mixed $value): string
{
    return htmlspecialchars((string) $value, ENT_QUOTES, "UTF-8");
}
function redirect(string $url): never
{
    header("Location: " . $url);
    exit();
}
function csrf_token(): string
{
    return $_SESSION["csrf"] ??= bin2hex(random_bytes(32));
}
function csrf_check(): void
{
    if (
        $_SERVER["REQUEST_METHOD"] === "POST" &&
        !hash_equals($_SESSION["csrf"] ?? "", (string) ($_POST["csrf"] ?? ""))
    ) {
        http_response_code(419);
        exit("Your form expired. Go back and try again.");
    }
}
function parse_filter_id(
    array $input,
    string $key,
    bool $zeroMeansEmpty = false,
): int|false|null {
    $rawValue = $input[$key] ?? "";
    $value = is_scalar($rawValue) ? trim((string) $rawValue) : null;
    if ($value === null) {
        return false;
    }
    if ($value === "" || ($zeroMeansEmpty && $value === "0")) {
        return null;
    }
    $id = filter_var($value, FILTER_VALIDATE_INT);
    return $id === false || $id < 1 ? false : $id;
}
function flash(string $message, string $type = "success"): void
{
    $_SESSION["flash"] = [$message, $type];
}
function current_user(): ?array
{
    return $_SESSION["user"] ?? null;
}
function require_login(): void
{
    if (!current_user()) {
        flash("Please sign in to continue.", "error");
        redirect(APP_BASE . "/user/login.php");
    }
}
function require_admin(): void
{
    require_login();
    if ((current_user()["role"] ?? "") !== "Admin") {
        http_response_code(403);
        exit("Administrator access required.");
    }
}

function cart_count(PDO $pdo): int
{
    if (!current_user()) {
        return (int) array_sum(
            array_map("intval", $_SESSION["guest_cart"] ?? []),
        );
    }
    $q = $pdo->prepare(
        "SELECT COALESCE(SUM(quantity),0) FROM cart_items WHERE user_id=?",
    );
    $q->execute([current_user()["id"]]);
    return (int) $q->fetchColumn();
}

function upload_image(array $file, string $folder): ?string
{
    if (($file["error"] ?? UPLOAD_ERR_NO_FILE) === UPLOAD_ERR_NO_FILE) {
        return null;
    }
    if (($file["error"] ?? UPLOAD_ERR_OK) !== UPLOAD_ERR_OK) {
        throw new RuntimeException("Image upload failed.");
    }
    if (($file["size"] ?? 0) > 5 * 1024 * 1024) {
        throw new RuntimeException("Image must be 5 MB or smaller.");
    }
    $info = @getimagesize($file["tmp_name"]);
    if (
        !$info ||
        !in_array(
            $info["mime"],
            ["image/jpeg", "image/png", "image/webp", "image/gif"],
            true,
        )
    ) {
        throw new RuntimeException("Use a JPG, PNG, WEBP, or GIF image.");
    }
    $ext = [
        "image/jpeg" => "jpg",
        "image/png" => "png",
        "image/webp" => "webp",
        "image/gif" => "gif",
    ][$info["mime"]];
    $dir = __DIR__ . "/../uploads/" . $folder;
    if (!is_dir($dir) && !mkdir($dir, 0775, true) && !is_dir($dir)) {
        throw new RuntimeException("Could not create upload folder.");
    }
    $name = bin2hex(random_bytes(16)) . "." . $ext;
    if (!move_uploaded_file($file["tmp_name"], $dir . "/" . $name)) {
        throw new RuntimeException("Could not save uploaded image.");
    }
    return "uploads/" . $folder . "/" . $name;
}

function moderate_review(string $text): string
{
    $words = ["fuck", "shit", "bitch", "asshole", "bastard", "damn"];
    foreach ($words as $word) {
        $text =
            preg_replace(
                "/\b" . preg_quote($word, "/") . "\b/iu",
                str_repeat("*", strlen($word)),
                $text,
            ) ?? $text;
    }
    return $text;
}

function clothing_sku(
    string $categoryName,
    string $typeName,
    string $productName,
    ?int $sizeId,
    ?int $colorId,
): string {
    $normalize = static fn(string $value): string => strtolower(
        preg_replace("/[^a-z0-9]/i", "", $value) ?? "",
    );
    $genderPrefix =
        [
            "mensclothing" => "M",
            "womensclothing" => "W",
        ][$normalize($categoryName)] ?? null;
    $typePrefix =
        [
            "top" => "T",
            "tops" => "T",
            "bottom" => "B",
            "bottoms" => "B",
            "headwear" => "H",
        ][$normalize($typeName)] ?? null;
    $catalog = [
        "MT" => [
            "Basic T-Shirt",
            "Polo Shirt",
            "Button-Down Shirt",
            "Hoodie",
            "Sweatshirt",
            "Tank Top",
            "Henley Shirt",
            "Flannel Shirt",
            "Long-Sleeve Shirt",
            "Knit Sweater",
        ],
        "MB" => [
            "Slim-Fit Jeans",
            "Straight-Leg Jeans",
            "Cargo Pants",
            "Chino Pants",
            "Jogger Pants",
            "Denim Shorts",
            "Bermuda Shorts",
            "Dress Pants",
            "Sweatpants",
            "Linen Trousers",
        ],
        "MH" => [
            "Baseball Cap",
            "Bucket Hat",
            "Beanie",
            "Fedora Hat",
            "Flat Cap",
            "Snapback Cap",
            "Trucker Hat",
            "Beret",
            "Panama Hat",
            "Fisherman Beanie",
        ],
        "WT" => [
            "Basic T-Shirt",
            "Crop Top",
            "Blouse",
            "Camisole",
            "Tank Top",
            "Off-Shoulder Top",
            "Halter Top",
            "Bodysuit",
            "Cardigan",
            "Knit Sweater",
        ],
        "WB" => [
            "Skinny Jeans",
            "Wide-Leg Jeans",
            "Cargo Pants",
            "High-Waisted Trousers",
            "Denim Shorts",
            "Mini Skirt",
            "Midi Skirt",
            "Maxi Skirt",
            "Leggings",
            "Palazzo Pants",
        ],
        "WH" => [
            "Baseball Cap",
            "Bucket Hat",
            "Beanie",
            "Beret",
            "Wide-Brim Sun Hat",
            "Fedora Hat",
            "Straw Hat",
            "Visor Cap",
            "Cloche Hat",
            "Newsboy Cap",
        ],
    ];
    if ($genderPrefix === null || $typePrefix === null) {
        throw new RuntimeException(
            "Choose a supported product category and type.",
        );
    }
    $prefix = $genderPrefix . $typePrefix;
    $productKey = $normalize($productName);
    foreach ($catalog[$prefix] as $index => $catalogName) {
        if ($normalize($catalogName) === $productKey) {
            return sprintf(
                "%s-%d-%d-%d",
                $prefix,
                $index + 1,
                $sizeId ?? 7,
                $colorId ?? 0,
            );
        }
    }
    throw new RuntimeException(
        "The product name does not match the selected clothing category's SKU catalog.",
    );
}
