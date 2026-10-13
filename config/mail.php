<?php
// Configure these environment variables with your Mailtrap sandbox SMTP credentials.
return ['host'=>getenv('MAILTRAP_HOST') ?: 'sandbox.smtp.mailtrap.io','port'=>(int)(getenv('MAILTRAP_PORT') ?: 2525),'username'=>getenv('MAILTRAP_USERNAME') ?: '','password'=>getenv('MAILTRAP_PASSWORD') ?: '', 'from_email'=>getenv('MAIL_FROM_EMAIL') ?: 'store@example.test','from_name'=>getenv('MAIL_FROM_NAME') ?: 'Wearwell Clothing'];
