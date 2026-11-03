<?php

declare(strict_types=1);
if (session_status() !== PHP_SESSION_ACTIVE) {
    $cookieParams = session_get_cookie_params();
    $cookieParams["httponly"] = true;
    $cookieParams["samesite"] = "Lax";
    session_set_cookie_params($cookieParams);
    ini_set("session.use_strict_mode", "1");
    session_start();
}
require_once __DIR__ . "/../config/database.php";
$configuredBase = getenv("CLOTHING_APP_BASE");
$projectRoot = realpath(__DIR__ . "/..");
$documentRootValue = $_SERVER["DOCUMENT_ROOT"] ?? "";
$documentRoot = $documentRootValue !== ""
    ? realpath($documentRootValue)
    : false;
$computedBase = null;
if ($configuredBase !== false && trim($configuredBase) !== "") {
    $computedBase = trim($configuredBase);
} elseif ($projectRoot !== false && $documentRoot !== false) {
    $projectRoot = rtrim(str_replace("\\", "/", $projectRoot), "/");
    $documentRoot = rtrim(str_replace("\\", "/", $documentRoot), "/");
    if (strncasecmp($projectRoot, $documentRoot, strlen($documentRoot)) === 0) {
        $relativeRoot = substr($projectRoot, strlen($documentRoot));
        if ($relativeRoot === "" || str_starts_with($relativeRoot, "/")) {
            $computedBase = $relativeRoot;
        }
    }
}
$computedBase = $computedBase ?? "/clothing-store-backup";
$computedBase = "/" . trim(str_replace("\\", "/", $computedBase), "/");
define("APP_BASE", $computedBase === "/" ? "" : $computedBase);
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
    static $accountChecked = false;
    if (!current_user()) {
        flash("Please sign in to continue.", "error");
        redirect(APP_BASE . "/user/login.php");
    }
    if ($accountChecked) {
        return;
    }
    global $pdo;
    $account = $pdo->prepare(
        "SELECT s.status_name,u.role_name
        FROM users u
        JOIN account_statuses s ON s.status_id=u.status_id
        WHERE u.user_id=?",
    );
    $account->execute([current_user()["id"]]);
    $account = $account->fetch();
    if (!$account || $account["status_name"] !== "Active") {
        $_SESSION = [];
        session_destroy();
        session_id("");
        session_start();
        flash("Your account has been deactivated.", "error");
        redirect(APP_BASE . "/user/login.php");
    }
    $_SESSION["user"]["role"] = $account["role_name"];
    $accountChecked = true;
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
    return preg_replace_callback(
        '/\b(?:nigga|fuck(?:ing|ed|er|s)?|f\*ck|fuuck|shit(?:ty|s|ting)?|sh1t|bitch(?:es|y)?|assholes?|bastards?|damn(?:ed|ing|s)?|cunts?|bobos?|gagos?|tangina)\b/iu',
        static fn(array $match): string => str_repeat(
            "*",
            mb_strlen($match[0]),
        ),
        $text,
    ) ?? $text;
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

function restock_expense_amount(string $basePrice, int $quantity): string
{
    if (
        !preg_match('/^(\d{1,8})(?:\.(\d{1,2}))?$/D', $basePrice, $matches) ||
        $quantity < 1
    ) {
        throw new RuntimeException("Invalid restock expense amount.");
    }

    $basePriceCents =
        (int) $matches[1] * 100 +
        (int) str_pad($matches[2] ?? "", 2, "0");
    $maxExpenseCents = 9999999999;
    if (
        $basePriceCents > 0 &&
        $quantity >
            intdiv(
                $maxExpenseCents * 10 + 4,
                $basePriceCents * 9,
            )
    ) {
        throw new RuntimeException(
            "The restock expense exceeds the maximum allowed amount.",
        );
    }

    $expenseCents = intdiv($basePriceCents * 9 * $quantity + 5, 10);
    return intdiv($expenseCents, 100) .
        "." .
        str_pad(
            (string) ($expenseCents % 100),
            2,
            "0",
            STR_PAD_LEFT,
        );
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
    string $productName,
    ?int $sizeId,
    ?int $colorId,
): string {
    $categoryPrefix = match ($categoryName) {
        "Men's Clothing" => "MC",
        "Women's Clothing" => "WC",
        default => "X",
    };
    $typePrefix = match ($typeName) {
        "Top" => "TP",
        "Bottom" => "BTM",
        "Headwear" => "HW",
        default => "X",
    };
    if (
        preg_match_all(
            '/(?:^|\s)[^\p{L}\p{N}]*([\p{L}\p{N}])/u',
            trim($productName),
            $wordInitials,
        ) === false ||
        empty($wordInitials[1])
    ) {
        throw new RuntimeException(
            "The product name must contain a letter or number to generate its SKU.",
        );
    }
    $nameInitials = strtoupper(implode("", $wordInitials[1]));

    return sprintf(
        "%s-%s-%s-%d-%d",
        $categoryPrefix,
        $nameInitials,
        $typePrefix,
        $colorId ?? 0,
        $sizeId ?? 7,
    );
}

function price_label(float $min, float $max): string
{
    $text = "₱" . number_format($min, 2);
    return $min < $max ? "From " . $text : $text;
}

if (current_user()) {
    require_login();
}
