# Wearwell

Wearwell is a PHP and MySQL clothing store with customer shopping features and an
admin panel for products, orders, inventory, and reports.

## Requirements

- PHP 8.1 or later with PDO MySQL enabled
- MySQL 8 or MariaDB (XAMPP is supported)
- Composer
- Apache or another PHP-capable web server

## Setup

1. Place the project in your web server's document root.
2. To restore the store on a new device, import
   `database/clothing_store_complete.sql` using phpMyAdmin or the MySQL client.
   It creates the `clothing_store_fixed` database, tables, view, triggers, and
   data. This import replaces existing tables; do not import it over a database
   you want to keep. It is the only full database import file provided.
3. For an existing installation, keep using its current database; this
   complete import is intended for restoring the store on a new device, not
   upgrading an existing database. To remove the shipping fee from existing
   order totals and drop the column, run
   `database/migration_remove_shipping_fee_from_order_transaction_details.sql`
   against that database. This also replaces the order transaction view
   without the shipping fee.
4. Install PHP dependencies from the project root:

   ```sh
   composer install
   ```

5. Configure the environment variables for your PHP/Apache process:

   ```text
   CLOTHING_DB_HOST=127.0.0.1
   CLOTHING_DB_NAME=clothing_store_fixed
   CLOTHING_DB_USER=root
   CLOTHING_DB_PASS=
   MAILTRAP_HOST=sandbox.smtp.mailtrap.io
   MAILTRAP_PORT=2525
   MAILTRAP_USERNAME=your-mailtrap-username
   MAILTRAP_PASSWORD=your-mailtrap-password
   MAIL_FROM_EMAIL=store@example.test
   MAIL_FROM_NAME=Wearwell Clothing
   ```

   Replace the Mailtrap credentials with values from your Mailtrap sandbox.
   The database defaults are suitable for a standard local XAMPP installation;
   set the variables explicitly in production.
6. Open the project through the local web server. The application computes its
   base path from the document root; set `CLOTHING_APP_BASE` only to override it.

## Mailtrap setup for XAMPP

From the project root, install the mail and PDF dependencies:

```bat
composer install
```

For local XAMPP testing, copy the Mailtrap credentials into
`config/mail.local.php`. This local file overrides the environment-variable
configuration in `config/mail.php` and is ignored by Git. Keep real credentials
out of tracked files. If `mail.local.php` is not present, configure these
environment variables for Apache and restart it:

```text
MAILTRAP_HOST=sandbox.smtp.mailtrap.io
MAILTRAP_PORT=2525
MAILTRAP_USERNAME=your-mailtrap-username
MAILTRAP_PASSWORD=your-mailtrap-password
MAIL_FROM_EMAIL=store@example.test
MAIL_FROM_NAME=Wearwell Clothing
```

Open `http://localhost/<project-folder>/test_mail.php` to send a plain test
message and view SMTP debug output. Delete `test_mail.php` after testing.

The SQL import does not bundle uploaded images; copy the project's `uploads/`
directory separately when moving devices.

## Folder structure

```text
admin/       Admin dashboard, products, orders, inventory, and reports
assets/      CSS, JavaScript, and image assets
config/      Database and Mailtrap configuration
database/    Database import, view migration, and data notes
includes/    Shared functions, page layouts, and email templates
uploads/     Uploaded product images and profile photos
user/        Customer registration, login, profile, and address pages
```
