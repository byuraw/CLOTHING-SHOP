        </div>
    </div>
</div>
<script>
(function () {
    var filterInputs = Array.prototype.slice.call(document.querySelectorAll('[data-table-filter]'));
    var tabs = Array.prototype.slice.call(document.querySelectorAll('[data-product-tab]'));
    var panels = Array.prototype.slice.call(document.querySelectorAll('[data-product-panel]'));
    var productEditForm = document.getElementById('product-edit-form');

    function activateTab(tab) {
        tabs.forEach(function (item) {
            var active = item === tab;
            item.classList.toggle('active', active);
            item.setAttribute('aria-selected', active ? 'true' : 'false');
            item.setAttribute('tabindex', active ? '0' : '-1');
        });
        panels.forEach(function (panel) {
            panel.hidden = panel.id !== tab.getAttribute('data-product-tab');
        });
    }

    tabs.forEach(function (tab, index) {
        tab.addEventListener('click', function () {
            activateTab(tab);
        });
        tab.addEventListener('keydown', function (event) {
            var nextIndex = index;
            if (event.key === 'ArrowRight') nextIndex = (index + 1) % tabs.length;
            else if (event.key === 'ArrowLeft') nextIndex = (index + tabs.length - 1) % tabs.length;
            else if (event.key === 'Home') nextIndex = 0;
            else if (event.key === 'End') nextIndex = tabs.length - 1;
            else return;
            event.preventDefault();
            tabs[nextIndex].focus();
            activateTab(tabs[nextIndex]);
        });
    });

    if (productEditForm) {
        var editFields = {
            id: document.getElementById('edit-product-id'),
            name: document.getElementById('edit-product-name'),
            description: document.getElementById('edit-product-description'),
            category: document.getElementById('edit-product-category'),
            type: document.getElementById('edit-product-type'),
            price: document.getElementById('edit-product-price'),
            save: document.getElementById('save-product-edit')
        };

        function selectProduct(row) {
            editFields.id.value = row.getAttribute('data-product-id');
            editFields.name.value = row.getAttribute('data-product-name');
            editFields.description.value = row.getAttribute('data-product-description');
            editFields.category.value = row.getAttribute('data-product-category');
            editFields.type.value = row.getAttribute('data-product-type');
            editFields.price.value = row.getAttribute('data-product-price');
            editFields.name.disabled = false;
            editFields.description.disabled = false;
            editFields.category.disabled = false;
            editFields.type.disabled = false;
            editFields.price.disabled = false;
            editFields.save.disabled = false;
            document.querySelectorAll('#update-product-panel tr[data-product-id]').forEach(function (item) {
                item.classList.toggle('selected-product-row', item === row);
            });
            document.getElementById('product-edit-prompt').textContent =
                'Editing ' + editFields.name.value + '.';
        }

        var updatePanel = productEditForm.closest('[data-product-panel]');
        updatePanel.addEventListener('click', function (event) {
            var row = event.target.closest('tr[data-selectable-product]');
            if (!row || event.target.closest('button, a, input, select, textarea, form')) return;
            selectProduct(row);
        });
        updatePanel.addEventListener('keydown', function (event) {
            var row = event.target.closest('tr[data-selectable-product]');
            if (!row || event.target !== row || (event.key !== 'Enter' && event.key !== ' ')) return;
            event.preventDefault();
            selectProduct(row);
        });
    }

    var initialTab = document.getElementById(window.location.hash.slice(1));
    if (initialTab && initialTab.hasAttribute('data-product-panel')) {
        var initialTabButton = document.querySelector(
            '[data-product-tab="' + initialTab.id + '"]'
        );
        if (initialTabButton) activateTab(initialTabButton);
    }

    function filterPanel(panel) {
        var search = panel.querySelector('[data-table-filter]');
        var query = search ? search.value.trim().toLowerCase() : '';
        var category = panel.querySelector('[data-product-filter="category"]');
        var size = panel.querySelector('[data-product-filter="size"]');
        var color = panel.querySelector('[data-product-filter="color"]');
        var categoryId = category ? category.value : '';
        var sizeId = size ? size.value : '';
        var colorId = color ? color.value : '';

        panel.querySelectorAll('tbody tr').forEach(function (row) {
            var searchable = row.getAttribute('data-search') || row.textContent;
            var variantOptions = (row.getAttribute('data-variant-options') || '').split(',');
            var matchesVariant = (!sizeId && !colorId) || variantOptions.some(function (option) {
                var ids = option.split(':');
                return (!sizeId || ids[0] === sizeId) &&
                    (!colorId || ids[1] === colorId);
            });
            var matchesCategory = !categoryId ||
                row.getAttribute('data-category') === categoryId;
            row.style.display =
                (!query || searchable.toLowerCase().includes(query)) &&
                matchesCategory && matchesVariant
                    ? ''
                    : 'none';
        });

        if (productEditForm && panel.id === 'update-product-panel') {
            var selectedRow = panel.querySelector('tr.selected-product-row');
            if (selectedRow && selectedRow.style.display === 'none') {
                productEditForm.reset();
                document.getElementById('edit-product-id').value = '';
                ['edit-product-name', 'edit-product-description', 'edit-product-category', 'edit-product-type', 'edit-product-price', 'save-product-edit'].forEach(function (id) {
                    document.getElementById(id).disabled = true;
                });
                selectedRow.classList.remove('selected-product-row');
                document.getElementById('product-edit-prompt').textContent =
                    'Select a product from the table below to load its details.';
            }
        }
    }

    filterInputs.forEach(function (input) {
        input.addEventListener('input', function () {
            var panel = input.closest('[data-product-panel]');
            var target = panel || document.querySelector('[data-table-filter-target]');
            if (!target) return;
            var query = input.value.trim();
            if (panel) {
                if (query) {
                    tabs.forEach(function (tab) {
                        if (tab.getAttribute('data-product-tab') === panel.id) {
                            activateTab(tab);
                        }
                    });
                }
                filterPanel(panel);
                return;
            }
            target.querySelectorAll('tbody tr').forEach(function (row) {
                var searchable = row.getAttribute('data-search') || row.textContent;
                row.style.display = !query || searchable.toLowerCase().includes(query.toLowerCase())
                    ? ''
                    : 'none';
            });
        });
    });

    document.querySelectorAll('[data-product-filter]').forEach(function (filter) {
        filter.addEventListener('change', function () {
            var panel = filter.closest('[data-product-panel]');
            if (panel) filterPanel(panel);
        });
    });
})();
</script>
</body>
</html>
