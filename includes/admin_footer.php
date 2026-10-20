        </div>
    </div>
</div>
<script>
(function () {
    var input = document.querySelector('[data-table-filter]');
    if (!input) return;

    input.addEventListener('input', function () {
        var query = input.value.trim().toLowerCase();
        document.querySelectorAll('.content tbody tr').forEach(function (row) {
            row.style.display = !query || row.textContent.toLowerCase().includes(query)
                ? ''
                : 'none';
        });
    });
})();
</script>
</body>
</html>
