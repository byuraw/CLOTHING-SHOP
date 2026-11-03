<?php

header("Content-Type: text/html; charset=UTF-8");
echo "<!doctype html><html><head><meta charset=\"UTF-8\"><title>Mailtrap test</title></head><body><pre>";

if (!in_array($_SERVER["REMOTE_ADDR"] ?? "", ["127.0.0.1", "::1"], true)) {
    http_response_code(403);
    echo "This SMTP debug test is available only from localhost.";
    exit("</pre></body></html>");
}

try {
    $autoload = __DIR__ . "/vendor/autoload.php";
    if (!is_file($autoload)) {
        throw new RuntimeException("Composer dependencies are missing.");
    }
    require_once $autoload;
    $cfg = require __DIR__ . "/config/mail.php";
    if (($cfg["username"] ?? "") === "" || ($cfg["password"] ?? "") === "") {
        throw new RuntimeException("Mailtrap credentials are missing.");
    }

    $mail = new \PHPMailer\PHPMailer\PHPMailer(true);
    $mail->isSMTP();
    $mail->SMTPDebug = 2;
    $mail->Debugoutput = static function (string $message): void {
        echo htmlspecialchars($message, ENT_QUOTES, "UTF-8");
        flush();
    };
    $mail->Host = $cfg["host"];
    $mail->SMTPAuth = true;
    $mail->Username = $cfg["username"];
    $mail->Password = $cfg["password"];
    $mail->Port = $cfg["port"];
    $mail->SMTPSecure =
        \PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_STARTTLS;
    $mail->setFrom($cfg["from_email"], $cfg["from_name"]);
    $mail->addAddress("test@example.com");
    $mail->Subject = "Wearwell Mailtrap SMTP test";
    $mail->Body = "This is a test email from Wearwell.";
    $mail->send();
    echo "\nSent";
} catch (Throwable $error) {
    echo "\n" . htmlspecialchars($error->getMessage(), ENT_QUOTES, "UTF-8");
}

echo "</pre></body></html>";
