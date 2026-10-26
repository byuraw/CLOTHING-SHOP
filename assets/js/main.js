(function () {
    // Search bar toggle
    var sBtn = document.querySelector("[data-search-toggle]"),
        sBar = document.getElementById("search-bar");
    if (sBtn && sBar) {
        sBtn.addEventListener("click", function () {
            sBar.classList.toggle("open");
            if (sBar.classList.contains("open")) {
                var i = sBar.querySelector("input");
                if (i) i.focus();
            }
        });
    }

    // Hero slider
    var slides = [].slice.call(document.querySelectorAll(".hero-slide"));
    if (slides.length) {
        var cur = 0;
        function show(n) {
            cur = (n + slides.length) % slides.length;
            slides.forEach(function (s, i) {
                s.classList.toggle("active", i === cur);
                s.setAttribute("aria-hidden", i === cur ? "false" : "true");
            });
        }
        var p = document.querySelector(".hero-arrow.prev"),
            n = document.querySelector(".hero-arrow.next");
        if (p)
            p.addEventListener("click", function () {
                show(cur - 1);
            });
        if (n)
            n.addEventListener("click", function () {
                show(cur + 1);
            });
        show(0);
        window.setInterval(function () {
            show(cur + 1);
        }, 3000);
    }

    // New-arrivals category tabs
    var tabs = [].slice.call(document.querySelectorAll("[data-tab]"));
    var cards = [].slice.call(document.querySelectorAll("[data-cat]"));
    tabs.forEach(function (t) {
        t.addEventListener("click", function () {
            tabs.forEach(function (x) {
                x.setAttribute("aria-selected", x === t ? "true" : "false");
            });
            var c = t.getAttribute("data-tab"),
                shown = 0;
            cards.forEach(function (card) {
                var ok =
                    (c === "all" || card.getAttribute("data-cat") === c) &&
                    shown < 8;
                card.hidden = !ok;
                if (ok) shown++;
            });
        });
    });

    // Product gallery thumbnails
    var main = document.querySelector("[data-main-img]");
    [].forEach.call(document.querySelectorAll("[data-thumb]"), function (b) {
        b.addEventListener("click", function () {
            if (main) {
                main.src = b.getAttribute("data-thumb");
            }
            [].forEach.call(
                document.querySelectorAll("[data-thumb]"),
                function (x) {
                    x.setAttribute("aria-current", x === b ? "true" : "false");
                },
            );
        });
    });
})();
