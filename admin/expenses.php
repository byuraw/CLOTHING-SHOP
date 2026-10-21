<?php
require_once __DIR__ . "/../includes/functions.php";
require_admin();
$error = "";
if ($_SERVER["REQUEST_METHOD"] === "POST") {
    csrf_check();
    $name = trim($_POST["expense_name"] ?? "");
    $amount = (float) ($_POST["amount"] ?? 0);
    $date = $_POST["expense_date"] ?? date("Y-m-d");
    if ($name && $amount >= 0) {
        $q = $pdo->prepare(
            "INSERT INTO expenses(recorded_by,expense_name,amount,expense_date,notes) VALUES(?,?,?,?,?)",
        );
        $q->execute([
            current_user()["id"],
            $name,
            $amount,
            $date,
            trim($_POST["notes"] ?? "") ?: null,
        ]);
        flash("Expense recorded.");
        redirect("/clothing-store-backup/admin/expenses.php");
    } else {
        $error = "Enter an expense name and valid amount.";
    }
}
$list = $pdo
    ->query(
        "SELECT expense_name,amount,expense_date,notes FROM expenses ORDER BY expense_date DESC,expense_id DESC",
    )
    ->fetchAll();
$pageTitle = "Expenses";
require __DIR__ . "/../includes/admin_header.php";
?>

<h1 class="page-title">Expenses</h1>
<?php if ($error): ?>

<div class="notice error"><?= e($error) ?></div>
<?php endif; ?>

<form class="form-card" method="post">
  <input type="hidden" name="csrf" value="<?= e(
      csrf_token(),
  ) ?>" /><label>Expense name</label><input name="expense_name" /><label>Amount</label><input type="number" name="amount" min="0" step=".01" /><label
    >Date</label
  ><input type="date" name="expense_date" value="<?= date(
      "Y-m-d",
  ) ?>" /><label>Notes</label><textarea name="notes"></textarea><button>Record expense</button>
</form>
<div class="table-wrap">
  <table>
    <thead>
      <tr>
        <th>Date</th>
        <th>Expense</th>
        <th>Notes</th>
        <th>Amount</th>
      </tr>
    </thead>
    <tbody>
      <?php foreach ($list as $x): ?>

      <tr>
        <td><?= e($x["expense_date"]) ?></td>
        <td><?= e($x["expense_name"]) ?></td>
        <td><?= e($x["notes"] ?? "") ?></td>
        <td>₱<?= number_format((float) $x["amount"], 2) ?></td>
      </tr>
      <?php endforeach; ?>
      <?php if (!$list): ?>
      <tr><td colspan="4" class="empty-note">No expenses recorded yet.</td></tr>
      <?php endif; ?>

    </tbody>
  </table>
</div>
<?php require __DIR__ . "/../includes/admin_footer.php"; ?>
