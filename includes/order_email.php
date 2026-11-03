<?php

function build_order_email_html(
    array $order,
    array $items,
    array $details,
    bool $confirmation = false,
): string {
    $date = date("F j, Y, g:i A", strtotime($order["placed_at"]));
    $statusColors = [
        "Pending" => "#f59e0b",
        "Processing" => "#3b82f6",
        "Packed" => "#8b5cf6",
        "Shipped" => "#06b6d4",
        "Delivered" => "#10b981",
        "Completed" => "#16a34a",
        "Cancelled" => "#ef4444",
    ];
    $statusColor = $statusColors[$order["status_name"]] ?? "#6b7280";
    $html =
        '<!DOCTYPE html><html><head><meta charset="UTF-8"></head>' .
        '<body style="margin:0;padding:24px 12px;background:#f4f4f5;font-family:Arial,Helvetica,sans-serif;color:#111827;">' .
        '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="border-collapse:collapse;"><tr><td align="center">' .
        '<table role="presentation" width="600" cellpadding="0" cellspacing="0" border="0" style="width:100%;max-width:600px;background:#ffffff;border:1px solid #e4e4e7;border-collapse:collapse;">' .
        '<tr><td style="padding:20px 24px;background:#111827;color:#ffffff;font-size:20px;font-weight:bold;">Wearwell Clothing</td></tr>' .
        '<tr><td style="padding:24px;">' .
        '<p style="margin:0 0 12px;line-height:1.5;">Hello ' .
        htmlspecialchars($order["first_name"], ENT_QUOTES, "UTF-8") .
        ($confirmation
            ? ', we received your order.'
            : ', your order status has been updated.') .
        "</p>" .
        '<p style="margin:0 0 20px;"><span style="display:inline-block;padding:6px 12px;border-radius:999px;background:' .
        $statusColor .
        ';color:#ffffff;font-size:13px;font-weight:bold;">' .
        htmlspecialchars($order["status_name"], ENT_QUOTES, "UTF-8") .
        '</span></p>' .
        '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin:0 0 20px;border-collapse:collapse;background:#f9fafb;"><tr><td style="padding:12px;border:1px solid #e4e4e7;line-height:1.6;">' .
        '<strong>Order number:</strong> ' .
        htmlspecialchars($order["order_number"], ENT_QUOTES, "UTF-8") .
        '<br><strong>Order date:</strong> ' .
        htmlspecialchars($date, ENT_QUOTES, "UTF-8") .
        '<br><strong>Status:</strong> ' .
        htmlspecialchars($order["status_name"], ENT_QUOTES, "UTF-8") .
        '</td></tr></table>' .
        '<table width="100%" cellpadding="0" cellspacing="0" border="0" style="border-collapse:collapse;font-size:14px;">' .
        '<thead><tr style="background:#f9fafb;"><th align="left" style="padding:10px 8px;border-bottom:1px solid #e4e4e7;">Product</th><th align="center" style="padding:10px 8px;border-bottom:1px solid #e4e4e7;">Qty</th><th align="right" style="padding:10px 8px;border-bottom:1px solid #e4e4e7;">Unit price</th><th align="right" style="padding:10px 8px;border-bottom:1px solid #e4e4e7;">Subtotal</th></tr></thead><tbody>';
    foreach ($items as $item) {
        $options = [];
        if ($item["size_snapshot"] !== null && $item["size_snapshot"] !== "") {
            $options[] = $item["size_snapshot"];
        }
        if ($item["color_snapshot"] !== null && $item["color_snapshot"] !== "") {
            $options[] = $item["color_snapshot"];
        }
        $html .=
            '<tr><td style="padding:10px 8px;border-bottom:1px solid #e4e4e7;">' .
            htmlspecialchars(
                $item["product_name_snapshot"],
                ENT_QUOTES,
                "UTF-8",
            ) .
            ($options
                ? '<br><span style="font-size:12px;color:#6b7280;">' .
                    htmlspecialchars(
                        implode(" / ", $options),
                        ENT_QUOTES,
                        "UTF-8",
                    ) .
                    "</span>"
                : "") .
            '</td><td align="center" style="padding:10px 8px;border-bottom:1px solid #e4e4e7;">' .
            (int) $item["quantity"] .
            '</td><td align="right" style="padding:10px 8px;border-bottom:1px solid #e4e4e7;">₱' .
            number_format((float) $item["unit_price"], 2) .
            '</td><td align="right" style="padding:10px 8px;border-bottom:1px solid #e4e4e7;">₱' .
            number_format((float) $item["line_total"], 2) .
            "</td></tr>";
    }
    $html .=
        '</tbody></table><table role="presentation" align="right" cellpadding="0" cellspacing="0" border="0" style="margin:16px 0 20px;border-collapse:collapse;"><tr><td style="padding:4px 16px 4px 0;">Subtotal</td><td align="right" style="padding:4px 0;">₱' .
        number_format((float) $order["subtotal"], 2) .
        '</td></tr><tr><td style="padding:4px 16px 4px 0;">Shipping</td><td align="right" style="padding:4px 0;">' .
        ((float) $order["shipping_fee"] === 0.0
            ? "Free"
            : "₱" . number_format((float) $order["shipping_fee"], 2)) .
        '</td></tr><tr><td style="padding:8px 16px 4px 0;font-size:17px;font-weight:bold;border-top:1px solid #e4e4e7;">Grand total</td><td align="right" style="padding:8px 0 4px;font-size:17px;font-weight:bold;border-top:1px solid #e4e4e7;">₱' .
        number_format((float) $order["total_amount"], 2) .
        "</td></tr></table><div style=\"clear:both;\"></div>";
    if ($details["recipient_name"] !== null) {
        $address = [
            $details["address_line1"],
            trim(
                $details["city"] .
                    ", " .
                    $details["province"] .
                    " " .
                    $details["postal_code"],
                ", ",
            ),
        ];
        $html .=
            '<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin:4px 0 20px;border-collapse:collapse;background:#f9fafb;"><tr><td style="padding:14px;border:1px solid #e4e4e7;line-height:1.6;"><strong>Delivery address</strong><br>' .
            htmlspecialchars(
                $details["recipient_name"],
                ENT_QUOTES,
                "UTF-8",
            ) .
            "<br>" .
            htmlspecialchars($details["phone"], ENT_QUOTES, "UTF-8") .
            "<br>" .
            htmlspecialchars(
                implode(", ", array_filter($address)),
                ENT_QUOTES,
                "UTF-8",
            ) .
            "</td></tr></table>";
    }
    if ($details["amount"] !== null) {
        $html .=
            '<p style="margin:0 0 18px;font-size:14px;"><strong>Amount paid:</strong> ₱' .
            number_format((float) $details["amount"], 2) .
            " (" .
            htmlspecialchars(
                ucfirst($details["payment_status"]),
                ENT_QUOTES,
                "UTF-8",
            ) .
            ")</p>";
    }
    $html .=
        '<p style="margin:0;color:#6b7280;font-size:13px;line-height:1.5;">Thank you for shopping with Wearwell Clothing. A PDF receipt is attached to this email.</p></td></tr></table></td></tr></table></body></html>';

    return $html;
}

function build_order_receipt_html(
    array $order,
    array $items,
    array $details,
): string {
    $date = date("F j, Y, g:i A", strtotime($order["placed_at"]));
    $customerName = trim($order["first_name"] . " " . $order["last_name"]);
    $html =
        '<!DOCTYPE html><html><head><meta charset="UTF-8"><style>' .
        ' @page { margin: 30px; } body { font-family: "DejaVu Sans", sans-serif; color: #111827; font-size: 11px; } ' .
        'table { width: 100%; border-collapse: collapse; } .top td { padding: 0 0 18px; } .brand { font-size: 19px; font-weight: bold; } ' .
        '.title { text-align: right; font-size: 18px; font-weight: bold; letter-spacing: 2px; } .details td { width: 50%; vertical-align: top; padding: 12px; border: 1px solid #e4e4e7; line-height: 1.6; } ' .
        '.items { margin-top: 20px; } .items th { background: #f3f4f6; text-align: left; } .items th, .items td { padding: 9px 7px; border-bottom: 1px solid #e4e4e7; } ' .
        '.items tr:nth-child(even) td { background: #fafafa; } .right { text-align: right !important; } .center { text-align: center !important; } .muted { color: #6b7280; font-size: 9px; } ' .
        '.totals { width: 55%; margin: 16px 0 0 auto; } .totals td { padding: 5px 0; } .grand td { border-top: 1px solid #9ca3af; padding-top: 9px; font-size: 13px; font-weight: bold; } ' .
        '.footer { margin-top: 35px; text-align: center; color: #6b7280; font-size: 9px; } </style></head><body>' .
        '<table class="top"><tr><td class="brand">Wearwell Clothing</td><td class="title">RECEIPT</td></tr></table>' .
        '<table class="details"><tr><td><strong>Billed to</strong><br>' .
        htmlspecialchars($customerName, ENT_QUOTES, "UTF-8") .
        "<br>" .
        htmlspecialchars($order["email"], ENT_QUOTES, "UTF-8");
    if ($details["recipient_name"] !== null) {
        $address = [
            $details["address_line1"],
            trim(
                $details["city"] .
                    ", " .
                    $details["province"] .
                    " " .
                    $details["postal_code"],
                ", ",
            ),
        ];
        $html .=
            '<br><br><strong>Delivery address</strong><br>' .
            htmlspecialchars(
                $details["recipient_name"],
                ENT_QUOTES,
                "UTF-8",
            ) .
            "<br>" .
            htmlspecialchars($details["phone"], ENT_QUOTES, "UTF-8") .
            "<br>" .
            htmlspecialchars(
                implode(", ", array_filter($address)),
                ENT_QUOTES,
                "UTF-8",
            );
    }
    $html .=
        '</td><td><strong>Order number:</strong> ' .
        htmlspecialchars($order["order_number"], ENT_QUOTES, "UTF-8") .
        "<br><strong>Order date:</strong> " .
        htmlspecialchars($date, ENT_QUOTES, "UTF-8") .
        "<br><strong>Status:</strong> " .
        htmlspecialchars($order["status_name"], ENT_QUOTES, "UTF-8");
    if ($details["amount"] !== null) {
        $html .=
            "<br><strong>Payment status:</strong> " .
            htmlspecialchars(
                ucfirst($details["payment_status"]),
                ENT_QUOTES,
                "UTF-8",
            );
    }
    $html .= '</td></tr></table><table class="items"><thead><tr><th>Product</th><th class="center">Qty</th><th class="right">Unit price</th><th class="right">Subtotal</th></tr></thead><tbody>';
    foreach ($items as $item) {
        $options = [];
        if ($item["size_snapshot"] !== null && $item["size_snapshot"] !== "") {
            $options[] = $item["size_snapshot"];
        }
        if ($item["color_snapshot"] !== null && $item["color_snapshot"] !== "") {
            $options[] = $item["color_snapshot"];
        }
        $html .=
            '<tr><td>' .
            htmlspecialchars(
                $item["product_name_snapshot"],
                ENT_QUOTES,
                "UTF-8",
            ) .
            ($options
                ? '<br><span class="muted">' .
                    htmlspecialchars(
                        implode(" / ", $options),
                        ENT_QUOTES,
                        "UTF-8",
                    ) .
                    "</span>"
                : "") .
            '</td><td class="center">' .
            (int) $item["quantity"] .
            '</td><td class="right">₱' .
            number_format((float) $item["unit_price"], 2) .
            '</td><td class="right">₱' .
            number_format((float) $item["line_total"], 2) .
            "</td></tr>";
    }
    $html .=
        '</tbody></table><table class="totals"><tr><td>Subtotal</td><td class="right">₱' .
        number_format((float) $order["subtotal"], 2) .
        '</td></tr><tr><td>Shipping</td><td class="right">' .
        ((float) $order["shipping_fee"] === 0.0
            ? "Free"
            : "₱" . number_format((float) $order["shipping_fee"], 2)) .
        '</td></tr><tr class="grand"><td>Grand total</td><td class="right">₱' .
        number_format((float) $order["total_amount"], 2) .
        "</td></tr></table>";
    if ($details["amount"] !== null) {
        $html .=
            '<table class="totals"><tr><td><strong>Amount paid</strong></td><td class="right"><strong>₱' .
            number_format((float) $details["amount"], 2) .
            "</strong></td></tr></table>";
    }
    $html .=
        '<p class="footer">Thank you for shopping with Wearwell Clothing. This is a system-generated receipt.</p></body></html>';

    return $html;
}

function generate_receipt_pdf(PDO $pdo, int $orderId): array
{
    require_once __DIR__ . "/../vendor/autoload.php";
    $q = $pdo->prepare(
        "SELECT o.order_number,o.subtotal,o.shipping_fee,o.total_amount,o.placed_at,u.email,u.first_name,u.last_name,os.status_name
        FROM orders o
        JOIN users u ON u.user_id=o.user_id
        JOIN order_statuses os ON os.order_status_id=o.order_status_id
        WHERE o.order_id=?",
    );
    $q->execute([$orderId]);
    $o = $q->fetch();
    if (!$o) {
        throw new RuntimeException("The order details could not be loaded.");
    }
    $it = $pdo->prepare(
        "SELECT product_name_snapshot,size_snapshot,color_snapshot,quantity,unit_price,line_total
        FROM vw_order_transaction_details
        WHERE order_id=?
        ORDER BY order_item_id",
    );
    $it->execute([$orderId]);
    $items = $it->fetchAll();
    $detailsQuery = $pdo->prepare(
        "SELECT a.recipient_name,a.phone,a.address_line1,a.city,a.province,a.postal_code,
            p.amount,p.payment_status
        FROM orders o
        LEFT JOIN addresses a ON a.address_id=o.address_id AND a.user_id=o.user_id
        LEFT JOIN payments p ON p.payment_id=(
            SELECT latest.payment_id
            FROM payments latest
            WHERE latest.order_id=o.order_id
            ORDER BY latest.created_at DESC,latest.payment_id DESC
            LIMIT 1
        )
        WHERE o.order_id=?",
    );
    $detailsQuery->execute([$orderId]);
    $details = $detailsQuery->fetch();
    $pdfHtml = build_order_receipt_html($o, $items, $details);
    $dompdf = new \Dompdf\Dompdf();
    $dompdf->loadHtml($pdfHtml, "UTF-8");
    $dompdf->setPaper("A4");
    $dompdf->render();
    $safeOrderNumber = preg_replace(
        '/[^A-Za-z0-9._-]/',
        "_",
        (string) $o["order_number"],
    );
    return [
        "pdf" => $dompdf->output(),
        "filename" => "receipt-" . $safeOrderNumber . ".pdf",
        "order" => $o,
        "items" => $items,
        "details" => $details,
    ];
}

function send_order_status_email(PDO $pdo, int $orderId): void
{
    send_order_email($pdo, $orderId, false);
}

function send_order_confirmation_email(PDO $pdo, int $orderId): void
{
    send_order_email($pdo, $orderId, true);
}

function send_order_email(PDO $pdo, int $orderId, bool $confirmation): void
{
    $cfg = require __DIR__ . "/../config/mail.php";
    if ($cfg["username"] === "" || $cfg["password"] === "") {
        if ($confirmation) {
            error_log("Mailtrap credentials are missing; confirmation email skipped.");
            return;
        }
        throw new RuntimeException("Mailtrap credentials are missing.");
    }
    if (!is_file(__DIR__ . "/../vendor/autoload.php")) {
        if ($confirmation) {
            error_log("Composer dependencies are missing; confirmation email skipped.");
            return;
        }
        throw new RuntimeException("Composer dependencies are missing.");
    }
    require_once __DIR__ . "/../vendor/autoload.php";
    $receipt = generate_receipt_pdf($pdo, $orderId);
    $o = $receipt["order"];
    $items = $receipt["items"];
    $details = $receipt["details"];
    $html = build_order_email_html($o, $items, $details, $confirmation);
    $mail = new \PHPMailer\PHPMailer\PHPMailer(true);
    $mail->isSMTP();
    $mail->Host = $cfg["host"];
    $mail->SMTPAuth = true;
    $mail->Username = $cfg["username"];
    $mail->Password = $cfg["password"];
    $mail->Port = $cfg["port"];
    $mail->SMTPSecure = \PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_STARTTLS;
    $mail->setFrom($cfg["from_email"], $cfg["from_name"]);
    $mail->addAddress($o["email"], $o["first_name"]);
    $mail->isHTML(true);
    $mail->CharSet = "UTF-8";
    $mail->Subject =
        $confirmation
            ? "Order " . $o["order_number"] . " confirmed"
            : "Order " . $o["order_number"] . " status: " . $o["status_name"];
    $mail->Body = $html;
    $plainItems = [];
    foreach ($items as $item) {
        $itemLine =
            $item["product_name_snapshot"] .
            " x " .
            (int) $item["quantity"] .
            " | Unit price: ₱" .
            number_format((float) $item["unit_price"], 2) .
            " | Subtotal: ₱" .
            number_format((float) $item["line_total"], 2);
        $options = array_filter([
            $item["size_snapshot"],
            $item["color_snapshot"],
        ]);
        if ($options) {
            $itemLine .= " (" . implode(" / ", $options) . ")";
        }
        $plainItems[] = $itemLine;
    }
    $mail->AltBody =
        "Order number: " .
        $o["order_number"] .
        "\nOrder date: " .
        date("F j, Y, g:i A", strtotime($o["placed_at"])) .
        "\nStatus: " .
        $o["status_name"] .
        "\n\nItems:\n" .
        implode("\n", $plainItems) .
        "\n\nSubtotal: ₱" .
        number_format((float) $o["subtotal"], 2) .
        "\nShipping: " .
        ((float) $o["shipping_fee"] === 0.0
            ? "Free"
            : "₱" . number_format((float) $o["shipping_fee"], 2)) .
        "\nGrand total: ₱" .
        number_format((float) $o["total_amount"], 2);
    if ($details["recipient_name"] !== null) {
        $mail->AltBody .=
            "\n\nDelivery address:\n" .
            $details["recipient_name"] .
            "\n" .
            $details["phone"] .
            "\n" .
            $details["address_line1"] .
            "\n" .
            $details["city"] .
            ", " .
            $details["province"] .
            " " .
            $details["postal_code"];
    }
    if ($details["amount"] !== null) {
        $mail->AltBody .=
            "\nAmount paid: ₱" .
            number_format((float) $details["amount"], 2) .
            " (" .
            ucfirst($details["payment_status"]) .
            ")";
    }
    $mail->addStringAttachment(
        $receipt["pdf"],
        $receipt["filename"],
        "base64",
        "application/pdf",
    );
    $mail->send();
}
