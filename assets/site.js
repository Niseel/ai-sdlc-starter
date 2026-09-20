/* Landing page behavior. No dependencies. */
(function () {
  "use strict";

  var root = document.documentElement;
  var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  var $ = function (sel, ctx) { return (ctx || document).querySelector(sel); };
  var $$ = function (sel, ctx) { return Array.prototype.slice.call((ctx || document).querySelectorAll(sel)); };

  function store(key, value) {
    try {
      if (value === undefined) return localStorage.getItem(key);
      localStorage.setItem(key, value);
    } catch (e) { return null; }
  }

  /* ---- Repo + version ---------------------------------------------------- */
  // Priority: <meta name="repo" content="owner/repo">, then the GitHub Pages
  // URL (owner.github.io/repo/), else a placeholder the maintainer fills in.
  var repo = { owner: "OWNER", name: "ai-sdlc-starter" };
  var metaRepo = ($('meta[name="repo"]') || {}).content || "";
  if (/^[\w.-]+\/[\w.-]+$/.test(metaRepo)) {
    repo.owner = metaRepo.split("/")[0];
    repo.name = metaRepo.split("/")[1];
  } else if (/\.github\.io$/i.test(location.hostname)) {
    repo.owner = location.hostname.split(".")[0];
    var seg = location.pathname.split("/").filter(Boolean)[0];
    if (seg && !/\.html?$/i.test(seg)) repo.name = seg;
  }
  var version = ($("[data-version]") || {}).textContent || "0.1.0";

  function ghUrl(kind) {
    var base = "https://github.com/" + repo.owner + "/" + repo.name;
    return {
      repo: base,
      issues: base + "/issues",
      "new-issue": base + "/issues/new",
      releases: base + "/releases"
    }[kind] || base;
  }
  function rawUrl(file) {
    return "https://raw.githubusercontent.com/" + repo.owner + "/" + repo.name + "/v" + version + "/" + file;
  }
  function pagesUrl(file) {
    return "https://" + repo.owner.toLowerCase() + ".github.io/" + repo.name + "/" + file;
  }
  function scriptUrl(file) {
    return src === "pinned" ? rawUrl(file) : pagesUrl(file);
  }
  function applyRepoLinks() {
    $$("[data-gh]").forEach(function (a) { a.href = ghUrl(a.getAttribute("data-gh")); });
  }
  function applyVersion() {
    $$("[data-version]").forEach(function (el) { el.textContent = version; });
  }

  /* ---- Language ---------------------------------------------------------- */
  function setLang(lang) {
    root.setAttribute("data-lang", lang);
    root.lang = lang;
    store("lang", lang);
    $$("[data-set-lang]").forEach(function (b) {
      b.setAttribute("aria-selected", String(b.getAttribute("data-set-lang") === lang));
    });
  }
  $$("[data-set-lang]").forEach(function (b) {
    b.addEventListener("click", function () { setLang(b.getAttribute("data-set-lang")); });
  });
  setLang(root.getAttribute("data-lang") || "en");

  /* ---- Command builder --------------------------------------------------- */
  var os = store("os") || (/Win/i.test(navigator.platform || navigator.userAgent) ? "win" : "unix");
  var src = store("src") === "pinned" ? "pinned" : "short";
  var form = $("#builder");

  function readOptions() {
    var get = function (n) { return form ? form.elements[n] : null; };
    var nameEl = get("name");
    var name = nameEl ? nameEl.value.trim().replace(/[^A-Za-z0-9._-]/g, "-").replace(/^-+|-+$/g, "") : "my-app";
    return {
      name: name || "my-app",
      node: get("node") ? get("node").value : "latest",
      python: get("python") ? get("python").value : "",
      go: get("go") ? get("go").value : "",
      java: get("java") ? get("java").value : "",
      nogit: get("nogit") ? get("nogit").checked : false,
      force: get("force") ? get("force").checked : false
    };
  }

  // The script's own defaults: "node" alone means latest, "python" means 3.12,
  // "go" means 1.22, "java" means 21. Only pin when the choice differs.
  var RUNTIME_DEFAULTS = { node: "latest", python: "3.12", go: "1.22", java: "21" };

  function buildCommand(o, target) {
    var win = target === "win";
    var args = [o.name];
    var withList = [];
    ["node", "python", "go", "java"].forEach(function (r) {
      if (!o[r]) return;
      withList.push(o[r] === RUNTIME_DEFAULTS[r] ? r : r + "@" + o[r]);
    });
    if (withList.length) args.push((win ? "-With " : "-w ") + withList.join(","));
    if (o.nogit) args.push(win ? "-NoGit" : "--no-git");
    if (o.force) args.push(win ? "-Force" : "-f");
    var tail = args.join(" ");
    if (win) {
      return "irm " + scriptUrl("init.ps1") + " -OutFile init.ps1\n" +
        "powershell -ExecutionPolicy Bypass -File .\\init.ps1 " + tail;
    }
    return "curl -fsSL " + scriptUrl("init.sh") + " | bash -s -- " + tail;
  }

  function renderCommands() {
    var quick = $('[data-cmd="quick"]');
    var built = $('[data-cmd="built"]');
    if (quick) quick.textContent = buildCommand({ name: "my-app", node: "latest", python: "3.12" }, os);
    if (built) built.textContent = buildCommand(readOptions(), os);
    $$("[data-os]").forEach(function (b) {
      b.setAttribute("aria-selected", String(b.getAttribute("data-os") === os));
    });
    $$("[data-src]").forEach(function (b) {
      b.setAttribute("aria-selected", String(b.getAttribute("data-src") === src));
    });
    $$("[data-src-note]").forEach(function (el) {
      el.hidden = el.getAttribute("data-src-note") !== src;
    });
  }

  $$("[data-src]").forEach(function (b) {
    b.addEventListener("click", function () {
      src = b.getAttribute("data-src");
      store("src", src);
      renderCommands();
    });
  });

  $$("[data-os]").forEach(function (b) {
    b.addEventListener("click", function () {
      os = b.getAttribute("data-os");
      store("os", os);
      renderCommands();
    });
  });
  if (form) {
    form.addEventListener("input", renderCommands);
    form.addEventListener("change", renderCommands);
    form.addEventListener("submit", function (e) { e.preventDefault(); });
  }

  /* ---- Copy buttons ------------------------------------------------------ */
  function copyText(text) {
    if (navigator.clipboard && window.isSecureContext) return navigator.clipboard.writeText(text);
    return new Promise(function (resolve, reject) {
      var ta = document.createElement("textarea");
      ta.value = text;
      ta.setAttribute("readonly", "");
      ta.style.position = "fixed";
      ta.style.opacity = "0";
      document.body.appendChild(ta);
      ta.select();
      var ok = false;
      try { ok = document.execCommand("copy"); } catch (e) {}
      document.body.removeChild(ta);
      ok ? resolve() : reject(new Error("copy failed"));
    });
  }
  $$("[data-copy]").forEach(function (btn) {
    var label = $(".copy-btn__text", btn);
    var original = label ? label.innerHTML : "";
    var use = $("use", btn);
    btn.addEventListener("click", function () {
      var src = $(btn.getAttribute("data-copy"));
      if (!src) return;
      copyText(src.textContent).then(function () {
        btn.classList.add("is-copied");
        if (use) use.setAttribute("href", "#i-check");
        if (label) label.innerHTML = '<span class="en">Copied</span><span class="vi">Đã chép</span>';
        setTimeout(function () {
          btn.classList.remove("is-copied");
          if (use) use.setAttribute("href", "#i-copy");
          if (label) label.innerHTML = original;
        }, 1800);
      }).catch(function () {
        var range = document.createRange();
        range.selectNodeContents(src);
        var sel = window.getSelection();
        sel.removeAllRanges();
        sel.addRange(range);
      });
    });
  });

  /* ---- Loop stage tabs (arrow keys move between stages) ------------------ */
  var stageTabs = $$('.loop__stages [role="tab"]');
  function selectStage(tab, focus) {
    stageTabs.forEach(function (t) {
      var on = t === tab;
      t.setAttribute("aria-selected", String(on));
      t.tabIndex = on ? 0 : -1;
      var panel = document.getElementById(t.getAttribute("aria-controls"));
      if (panel) panel.hidden = !on;
    });
    if (focus) tab.focus();
  }
  stageTabs.forEach(function (tab, i) {
    tab.addEventListener("click", function () { selectStage(tab, false); });
    tab.addEventListener("keydown", function (e) {
      var next = null;
      if (e.key === "ArrowRight" || e.key === "ArrowDown") next = stageTabs[(i + 1) % stageTabs.length];
      if (e.key === "ArrowLeft" || e.key === "ArrowUp") next = stageTabs[(i - 1 + stageTabs.length) % stageTabs.length];
      if (e.key === "Home") next = stageTabs[0];
      if (e.key === "End") next = stageTabs[stageTabs.length - 1];
      if (next) { e.preventDefault(); selectStage(next, true); }
    });
  });

  /* ---- Nav background once scrolled -------------------------------------- */
  var nav = $(".nav");
  function onScroll() { if (nav) nav.classList.toggle("is-scrolled", window.scrollY > 12); }
  window.addEventListener("scroll", onScroll, { passive: true });
  onScroll();

  /* ---- Reveal on scroll, terminal replay, number count-up ---------------- */
  function typeTerminal(term) {
    var lines = $$(".t-line", term);
    term.classList.add("is-typing");
    lines.forEach(function (line, i) {
      setTimeout(function () { line.classList.add("is-shown"); }, 140 * i);
    });
  }
  function countUp(el) {
    var target = parseInt(el.getAttribute("data-count"), 10);
    if (!target || target < 3) return;
    var start = null;
    var dur = 900;
    function step(ts) {
      if (start === null) start = ts;
      var p = Math.min((ts - start) / dur, 1);
      el.textContent = String(Math.round(target * (1 - Math.pow(1 - p, 3))));
      if (p < 1) requestAnimationFrame(step);
    }
    requestAnimationFrame(step);
  }

  var revealEls = $$(".reveal");
  root.classList.add("has-reveal");
  if (reduceMotion || !("IntersectionObserver" in window)) {
    revealEls.forEach(function (el) { el.classList.add("is-visible"); });
  } else {
    var io = new IntersectionObserver(function (entries) {
      var batch = 0;
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        var el = entry.target;
        el.style.transitionDelay = Math.min(batch * 80, 320) + "ms";
        batch += 1;
        el.classList.add("is-visible");
        var term = $(".terminal", el);
        if (term) typeTerminal(term);
        $$("[data-count]", el).forEach(countUp);
        io.unobserve(el);
      });
    }, { rootMargin: "0px 0px -8% 0px", threshold: 0.12 });
    revealEls.forEach(function (el) { io.observe(el); });
  }

  /* ---- Init -------------------------------------------------------------- */
  applyRepoLinks();
  renderCommands();
  // On GitHub Pages the repo root is served, so VERSION is fetchable.
  if (location.protocol !== "file:" && window.fetch) {
    fetch("VERSION", { cache: "no-store" })
      .then(function (r) { return r.ok ? r.text() : null; })
      .then(function (t) {
        var v = (t || "").trim();
        if (/^\d+\.\d+\.\d+$/.test(v)) { version = v; applyVersion(); renderCommands(); }
      })
      .catch(function () {});
  }
})();
