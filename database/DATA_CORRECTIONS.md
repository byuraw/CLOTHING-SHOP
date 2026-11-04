# Data corrections

The complete import includes the following corrected source rows:

| Table | Row IDs | Change | Reason |
|---|---|---|---|
| `product_images` | 1–5, 7–60 | Changed `sort_order` from 1 to 0. | Renumbered each product's images from zero; each has one image. |
| `payments` | 19, 31–38, 40–41 | Changed `payment_status` from `pending` to `paid`. | Each belongs to an order whose current status is `Completed`. |
| `payments` | 18 | Changed `payment_status` from `paid` to `refunded`. | Its order is `Cancelled`. |

No product variant SKU required correction: each is the output format of
`clothing_sku()` and the 206 SKUs whose base would otherwise collide include a
product-ID suffix to keep them unique. Prices and stock are nonnegative, every
product has a variant, inactive products have inactive variants, and slugs and
SKUs are unique.

The remaining integrity checks found no inconsistent order or line-item totals,
orders without items, invalid order/address ownership, duplicate payments,
invalid or duplicate reviews, missing completed-order sales, stale order
history, orphan inventory transactions, invalid expenses, or over-stock cart
quantities. No review text contained profanity. No data rows were removed.

## Upload files

No referenced image files are missing from `uploads/products/` or
`uploads/profiles/`. The profile image referenced by user 17,
`uploads/profiles/1eccd0004d15ee294ec0abdf6203956a.jpg`, exists.

## Personal-looking account emails

These accounts use personal email providers rather than the project's sample
`example.com` addresses. They were not changed:

- User 16: `justinesabalza0101@gmail.com`
- User 17: `johntaneo@gmail.com`

## Database design and amount reconciliation

The fresh-install SQL and existing-database migration remove these columns:

- `orders.shipping_fee`: shipping is no longer included in order totals.
- `addresses.created_at`, `expenses.created_at`, `users.updated_at`,
  `products.updated_at`, and `cart_items.updated_at`: these fields are not used
  by the application.

Line-item arithmetic already matched the line-item snapshots in the original
database: no `order_items.line_total` or `orders.subtotal` values needed
correction. The following order totals were changed to equal their subtotals:

| Table | ID | Old amount | New amount |
|---|---:|---:|---:|
| `orders` | 16 | 378.00 | 299.00 |
| `orders` | 17 | 827.00 | 748.00 |
| `orders` | 18 | 678.00 | 599.00 |
| `orders` | 19 | 1127.00 | 1048.00 |
| `orders` | 20 | 528.00 | 449.00 |
| `orders` | 21 | 977.00 | 898.00 |
| `orders` | 22 | 478.00 | 399.00 |
| `orders` | 23 | 1377.00 | 1298.00 |
| `orders` | 24 | 778.00 | 699.00 |
| `orders` | 25 | 1077.00 | 998.00 |

Sales are updated to their associated corrected order totals:

| Table | ID | Old amount | New amount |
|---|---:|---:|---:|
| `sales` | 9 | 827.00 | 748.00 |
| `sales` | 12 | 1077.00 | 998.00 |
| `sales` | 13 | 1377.00 | 1298.00 |
| `sales` | 22 | 1127.00 | 1048.00 |

Payments are updated to their associated corrected order totals:

| Table | ID | Old amount | New amount |
|---|---:|---:|---:|
| `payments` | 16 | 378.00 | 299.00 |
| `payments` | 17 | 827.00 | 748.00 |
| `payments` | 18 | 678.00 | 599.00 |
| `payments` | 19 | 1127.00 | 1048.00 |
| `payments` | 20 | 528.00 | 449.00 |
| `payments` | 21 | 977.00 | 898.00 |
| `payments` | 22 | 478.00 | 399.00 |
| `payments` | 23 | 1377.00 | 1298.00 |
| `payments` | 24 | 778.00 | 699.00 |
| `payments` | 25 | 1077.00 | 998.00 |
| `payments` | 36 | 1300.00 | 1266.00 |

The following columns are kept on purpose: `orders.customer_note` stores the
customer's order note; `order_items.sku_snapshot` preserves the purchased SKU;
`sales.notes` records sale context; `products.slug` is used for product URLs;
`product_categories.description` is category content; `addresses.is_default`
selects a preferred address; and `orders.updated_at` is maintained by the PHP
order-status update. The two unused, write-only audit tables have been removed.

No PHP files were changed. The dropped columns have no PHP references.
PHP-dependent or intentional fields listed above were not removed or changed.
