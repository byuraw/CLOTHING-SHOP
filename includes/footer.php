<?php if (!empty($isAdminPage)): ?>
</main>
<footer class="admin-footer">&copy; <?= date(
    "Y",
) ?> Wearwell Clothing <span>Admin workspace</span></footer>
</div>
</div>
<?php else: ?>
</main>
<footer class="site-footer"><div class="footer-grid">
<div><a class="brand" href="/clothing-store-backup/index.php">Wearwell</a><p>Comfortable everyday style.</p></div>
<div><h4>Shop</h4><a href="/clothing-store-backup/shop.php">All products</a><a href="/clothing-store-backup/cart.php">Cart</a><a href="/clothing-store-backup/orders.php">My orders</a></div>
<div><h4>Account</h4><?php if (
    current_user()
): ?><a href="/clothing-store-backup/user/profile.php">Profile</a><a href="/clothing-store-backup/user/addresses.php">Addresses</a><a href="/clothing-store-backup/user/logout.php">Sign out</a><?php else: ?><a href="/clothing-store-backup/user/login.php">Sign in</a><a href="/clothing-store-backup/user/register.php">Create account</a><?php endif; ?></div>
</div><div class="footer-base">&copy; <?= date(
    "Y",
) ?> Wearwell Clothing</div></footer>
<?php endif; ?>
<script src="/clothing-store-backup/assets/js/main.js?v=<?= filemtime(
    __DIR__ . "/../assets/js/main.js",
) ?>"></script></body></html>