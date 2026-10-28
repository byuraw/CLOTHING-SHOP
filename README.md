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
2. Create and seed the database by importing `database/schema.sql` in MySQL.
   The schema creates and selects the `clothing_store_fixed` database.
   For an existing installation, run `database/upgrade_legacy_cleanup.sql`
   against that database before using the updated application.
3. To load the demo customer accounts and sample store data, import
   `database/migrations/006_sample_business_data.sql` after the schema.
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
6. Open the project through the local web server. Configure the application's
   base URL if the project is not hosted at the expected local path.

## Demo logins

The sample business-data script (`database/migrations/006_sample_business_data.sql`)
creates six customer accounts (`alex.reyes.demo@example.com`,
`mika.santos.demo@example.com`, `jordan.cruz.demo@example.com`,
`sam.garcia.demo@example.com`, `taylor.delacruz.demo@example.com`, and
`casey.mendoza.demo@example.com`) with the shared password `DemoPass123!`.

The schema creates `admin@example.com`, but does not document its plaintext
password. Set or reset the admin password before using that account; do not
assume a default password.

## Folder structure

```text
admin/       Admin dashboard, products, orders, inventory, and reports
assets/      CSS, JavaScript, and image assets
config/      Database and Mailtrap configuration
database/    Schema and sample-data migrations
includes/    Shared functions, page layouts, and email templates
uploads/     Uploaded product images and profile photos
user/        Customer registration, login, profile, and address pages
```
