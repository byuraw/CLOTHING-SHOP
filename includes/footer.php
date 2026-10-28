<?php
require_once __DIR__ . "/functions.php";
if (!empty($isAdminPage)):
?>
</main>
<footer class="admin-footer">&copy; <?= date(
    "Y",
) ?> Wearwell Clothing <span>Admin workspace</span></footer>
</div>
</div>
<?php else: ?>
</main>
<footer class="site-footer"><div class="footer-grid">
<div><a class="brand" href="<?= APP_BASE ?>/index.php">Wearwell</a><p>Comfortable everyday style.</p></div>
<div><h4>Shop</h4><a href="<?= APP_BASE ?>/shop.php">All products</a><a href="<?= APP_BASE ?>/cart.php">Cart</a><a href="<?= APP_BASE ?>/orders.php">My orders</a></div>
<div><h4>Account</h4><?php if (
    current_user()
): ?><a href="<?= APP_BASE ?>/user/profile.php">Profile</a><a href="<?= APP_BASE ?>/user/addresses.php">Addresses</a><a href="<?= APP_BASE ?>/user/logout.php">Sign out</a><?php else: ?><a href="<?= APP_BASE ?>/user/login.php">Sign in</a><a href="<?= APP_BASE ?>/user/register.php">Create account</a><?php endif; ?></div>
</div><div class="footer-base">&copy; <?= date(
    "Y",
) ?> Wearwell Clothing</div></footer>
<?php endif; ?>
<script src="<?= APP_BASE ?>/assets/js/main.js?v=<?= filemtime(
    __DIR__ . "/../assets/js/main.js",
) ?>"></script></body></html>