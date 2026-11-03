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
   data. Importing it replaces tables with the same names, so back up an
   existing database first. `database/schema.sql` is for an empty database.
3. For an existing installation that needs the legacy cleanup, run
   `database/upgrade_legacy_cleanup.sql` against that database before using
   the updated application. For an existing installation, run
   [database/drop_base&#95;price.sql](database/drop%5Fbase%5Fprice.sql) after
   reading its STEP 1 comment. Also run
   `database/migration_qa_fixes.sql` to add the order details view and review
   uniqueness for this release.
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

To refresh the snapshot from the current local XAMPP database, run this from the
project root after making database changes:

```bat
C:\xampp\mysql\bin\mysqldump.exe --protocol=TCP --host=127.0.0.1 --user=root --single-transaction --routines --triggers --events --hex-blob --default-character-set=utf8mb4 --no-tablespaces --databases clothing_store_fixed --result-file="database\clothing_store_backup.sql"
```

The snapshot contains account and order data; keep it private and share it only
with devices that should have access to that data. It does not bundle uploaded
images; copy the project's `uploads/` directory separately when moving devices.

## Folder structure

```text
admin/       Admin dashboard, products, orders, inventory, and reports
assets/      CSS, JavaScript, and image assets
config/      Database and Mailtrap configuration
database/    Schema, database backup, and migrations
includes/    Shared functions, page layouts, and email templates
uploads/     Uploaded product images and profile photos
user/        Customer registration, login, profile, and address pages
```
