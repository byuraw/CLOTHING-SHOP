<?php
require_once __DIR__ . "/../includes/functions.php";
require_admin();
$error = "";
$editExpense = null;
if ($_SERVER["REQUEST_METHOD"] === "POST") {
    csrf_check();
    $action = $_POST["action"] ?? "create";
    if ($action === "delete") {
        $expenseId = filter_var(
            $_POST["expense_id"] ?? null,
            FILTER_VALIDATE_INT,
        );
        if ($expenseId === false || $expenseId < 1) {
            flash("Choose a valid expense to delete.", "error");
            redirect(APP_BASE . "/admin/expenses.php");
        }
        $q = $pdo->prepare("DELETE FROM expenses WHERE expense_id=?");
        $q->execute([$expenseId]);
        if ($q->rowCount() !== 1) {
            flash("Expense record not found.", "error");
            redirect(APP_BASE . "/admin/expenses.php");
        }
        flash("Expense deleted.");
        redirect(APP_BASE . "/admin/expenses.php");
    }
    $name = trim($_POST["expense_name"] ?? "");
    $rawAmount = trim((string) ($_POST["amount"] ?? ""));
    $amount = filter_var($rawAmount, FILTER_VALIDATE_FLOAT);
    $date = trim((string) ($_POST["expense_date"] ?? ""));
    $dateObject = DateTimeImmutable::createFromFormat("!Y-m-d", $date);
    $validDate =
        $dateObject !== false && $dateObject->format("Y-m-d") === $date;
    if ($name !== "" && $amount !== false && $amount >= 0 && $validDate) {
        $notes = trim($_POST["notes"] ?? "") ?: null;
        if ($action === "update") {
            $expenseId = filter_var(
                $_POST["expense_id"] ?? null,
                FILTER_VALIDATE_INT,
            );
            if ($expenseId === false || $expenseId < 1) {
                $error = "Choose a valid expense to update.";
            } else {
                $q = $pdo->prepare(
                    "UPDATE expenses SET expense_name=?,amount=?,expense_date=?,notes=? WHERE expense_id=?",
                );
                $q->execute([$name, $amount, $date, $notes, $expenseId]);
                if ($q->rowCount() === 0) {
                    $check = $pdo->prepare(
                        "SELECT 1 FROM expenses WHERE expense_id=?",
                    );
                    $check->execute([$expenseId]);
                    if (!$check->fetchColumn()) {
                        $error = "Expense record not found.";
                    }
                }
                if ($error === "") {
                    flash("Expense updated.");
                    redirect(APP_BASE . "/admin/expenses.php");
                }
                $editExpense = [
                    "expense_id" => $expenseId,
                    "expense_name" => $name,
                    "amount" => $rawAmount,
                    "expense_date" => $date,
                    "notes" => $_POST["notes"] ?? "",
                ];
            }
        } elseif ($action === "create") {
            $q = $pdo->prepare(
                "INSERT INTO expenses(recorded_by,expense_name,amount,expense_date,notes) VALUES(?,?,?,?,?)",
            );
            $q->execute([
                current_user()["id"],
                $name,
                $amount,
                $date,
                $notes,
            ]);
            flash("Expense recorded.");
            redirect(APP_BASE . "/admin/expenses.php");
        } else {
            $error = "Choose a valid expense action.";
        }
    } else {
        $error = "Enter an expense name, a valid non-negative amount, and a valid date.";
        if ($action === "update") {
            $editExpense = [
                "expense_id" => (int) ($_POST["expense_id"] ?? 0),
                "expense_name" => $name,
                "amount" => $rawAmount,
                "expense_date" => $date,
                "notes" => $_POST["notes"] ?? "",
            ];
        }
    }
}
$editId = filter_var($_GET["edit"] ?? null, FILTER_VALIDATE_INT);
if ($editExpense === null && $editId !== false && $editId !== null && $editId > 0) {
    $q = $pdo->prepare(
        "SELECT expense_id,expense_name,amount,expense_date,notes FROM expenses WHERE expense_id=?",
    );
    $q->execute([$editId]);
    $editExpense = $q->fetch() ?: null;
    if ($editExpense === null) {
        $error = "Expense record not found.";
    }
}
$list = $pdo
    ->query(
        "SELECT expense_id,expense_name,amount,expense_date,notes FROM expenses ORDER BY expense_date DESC,expense_id DESC",
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
        <th>Actions</th>
      </tr>
    </thead>
    <tbody>
      <?php foreach ($list as $x): ?>

      <tr>
        <td><?= e($x["expense_date"]) ?></td>
        <td><?= e($x["expense_name"]) ?></td>
        <td><?= e($x["notes"] ?? "") ?></td>
        <td>₱<?= number_format((float) $x["amount"], 2) ?></td>
        <td>
          <a class="button secondary" href="<?= e(
              APP_BASE . "/admin/expenses.php?edit=" . (int) $x["expense_id"],
          ) ?>">Edit</a>
          <form method="post" class="inline-form" onsubmit="return confirm('Delete this expense record? This action cannot be undone.');">
            <input type="hidden" name="csrf" value="<?= e(csrf_token()) ?>">
            <input type="hidden" name="action" value="delete">
            <input type="hidden" name="expense_id" value="<?= (int) $x["expense_id"] ?>">
            <button type="submit" class="danger">Delete</button>
          </form>
        </td>
      </tr>
      <?php if (
          $editExpense &&
          (int) $editExpense["expense_id"] === (int) $x["expense_id"]
      ): ?>
      <tr>
        <td colspan="5">
          <form class="expense-edit-form" method="post">
            <input type="hidden" name="csrf" value="<?= e(csrf_token()) ?>" />
            <input type="hidden" name="action" value="update" />
            <input type="hidden" name="expense_id" value="<?= (int) $x[
                "expense_id"
            ] ?>" />
            <label>Expense name<input name="expense_name" value="<?= e(
                $editExpense["expense_name"],
            ) ?>" required /></label>
            <label>Amount<input type="number" name="amount" min="0" step=".01" value="<?= e(
                $editExpense["amount"],
            ) ?>" required /></label>
            <label>Date<input type="date" name="expense_date" value="<?= e(
                $editExpense["expense_date"],
            ) ?>" required /></label>
            <label>Notes<textarea name="notes"><?= e(
                $editExpense["notes"] ?? "",
            ) ?></textarea></label>
            <div class="expense-edit-actions">
              <button type="submit">Save changes</button>
              <a class="button secondary" href="<?= e(
                  APP_BASE . "/admin/expenses.php",
              ) ?>">Cancel</a>
            </div>
          </form>
        </td>
      </tr>
      <?php endif; ?>
      <?php endforeach; ?>
      <?php if (!$list): ?>
      <tr><td colspan="5" class="empty-note">No expenses recorded yet.</td></tr>
      <?php endif; ?>

    </tbody>
  </table>
</div>
<?php require __DIR__ . "/../includes/admin_footer.php"; ?>
