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
