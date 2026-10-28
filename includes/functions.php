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

function log_inventory(
    PDO $pdo,
    int $variantId,
    ?int $userId,
    int $qty,
    string $reason,
    ?string $ref,
): void {
    $statement = $pdo->prepare(
        "INSERT INTO inventory_transactions(variant_id,changed_by,quantity_change,reason,reference_text) VALUES(?,?,?,?,?)",
    );
    $statement->execute([$variantId, $userId, $qty, $reason, $ref]);
}

function log_order_status(
    PDO $pdo,
    int $orderId,
    int $statusId,
    ?int $userId,
    ?string $note,
): void {
    $statement = $pdo->prepare(
        "INSERT INTO order_status_history(order_id,order_status_id,changed_by,note) VALUES(?,?,?,?)",
    );
    $statement->execute([$orderId, $statusId, $userId, $note]);
}

function clothing_sku(
    string $categoryName,
    string $typeName,
    int $productId,
    ?int $sizeId,
    ?int $colorId,
): string {
    $genderPrefix = match ($categoryName) {
        "Men's Clothing" => "M",
        "Women's Clothing" => "W",
        default => "X",
    };
    $typePrefix = match ($typeName) {
        "Top" => "T",
        "Bottom" => "B",
        "Headwear" => "H",
        default => "X",
    };

    return sprintf(
        "%s%s-%04d-%d-%d",
        $genderPrefix,
        $typePrefix,
        $productId,
        $sizeId ?? 7,
        $colorId ?? 0,
    );
}
