        </div>
    </div>
</div>
<script>
(function () {
    var filterInputs = Array.prototype.slice.call(document.querySelectorAll('[data-table-filter]'));
    var tabs = Array.prototype.slice.call(document.querySelectorAll('[data-product-tab]'));
    var panels = Array.prototype.slice.call(document.querySelectorAll('[data-product-panel]'));

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

    var pendingScroll = sessionStorage.getItem('product-delete-scroll');
    if (pendingScroll !== null) {
        sessionStorage.removeItem('product-delete-scroll');
        requestAnimationFrame(function () {
            window.scrollTo(0, Number(pendingScroll));
        });
    }

    document.querySelectorAll('form[data-preserve-scroll]').forEach(function (form) {
        form.addEventListener('submit', function () {
            sessionStorage.setItem('product-delete-scroll', String(window.scrollY));
        });
    });

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
