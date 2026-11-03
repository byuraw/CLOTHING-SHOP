<?php
require_once __DIR__ . "/includes/functions.php";
require_once __DIR__ . "/includes/order_email.php";
require_login();

$rawId = $_GET["id"] ?? null;
$id = is_string($rawId) ? filter_var($rawId, FILTER_VALIDATE_INT) : false;
if ($id === false || $id < 1) {
    http_response_code(404);
    exit("Order not found.");
}

if ((current_user()["role"] ?? "") === "Admin") {
    $orderQuery = $pdo->prepare(
        "SELECT order_id FROM orders WHERE order_id=?",
    );
    $orderQuery->execute([$id]);
} else {
    $orderQuery = $pdo->prepare(
        "SELECT order_id FROM orders WHERE order_id=? AND user_id=?",
    );
    $orderQuery->execute([$id, current_user()["id"]]);
}
if (!$orderQuery->fetchColumn()) {
    http_response_code(404);
    exit("Order not found.");
}

try {
    $receipt = generate_receipt_pdf($pdo, $id);
} catch (Throwable $error) {
    error_log("Order receipt generation failed: " . $error->getMessage());
    http_response_code(500);
    header("Content-Type: text/plain; charset=UTF-8");
    exit("Receipt could not be generated.");
}
while (ob_get_level() > 0) {
    ob_end_clean();
}
header("Content-Type: application/pdf");
header(
    'Content-Disposition: attachment; filename="' .
        $receipt["filename"] .
        '"',
);
header("Content-Length: " . strlen($receipt["pdf"]));
echo $receipt["pdf"];
exit;
