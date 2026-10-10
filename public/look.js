// 見た目の切り替え（ライト／ダーク）。最初は端末の設定に合わせ、選んだらその人のブラウザに覚える。
// 色の土台は GarlondWorks のブランド（旧「クール」）。やわらかは 2026-10-10 にやめた（オーナー「自社ブランドカラーじゃない」）。
// data-look="cool" は CSS の土台の目印として残す。<head> で読み込み、描く前に付ける（一瞬前の見た目が出るのを防ぐ）。
(function () {
  const KEY = "atrium-theme";
  const root = document.documentElement;
  const mq = window.matchMedia("(prefers-color-scheme: dark)");
  root.dataset.look = "cool";
  try { localStorage.removeItem("atrium-look"); } catch {}   // やわらか／クールの頃の記憶
  const saved = () => { try { const v = localStorage.getItem(KEY); return v === "light" || v === "dark" ? v : null; } catch { return null; } };
  const apply = () => { root.dataset.theme = saved() || (mq.matches ? "dark" : "light"); };
  apply();

  const THEMES = [
    ["light", "ライト", '<circle cx="12" cy="12" r="4"/><path d="M12 2.5v2M12 19.5v2M2.5 12h2M19.5 12h2M5.3 5.3l1.4 1.4M17.3 17.3l1.4 1.4M5.3 18.7l1.4-1.4M17.3 6.7l1.4-1.4"/>'],
    ["dark", "ダーク", '<path d="M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5Z"/>'],
  ];
  function draw() {
    const box = document.getElementById("look");
    if (!box) return;
    const cur = root.dataset.theme;
    box.innerHTML = `<span class="look" role="group" aria-label="見た目">${THEMES.map(([k, t, d]) =>
      `<button type="button" data-look-set="${k}" aria-pressed="${cur === k}" title="${t}">
        <svg class="ic" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${d}</svg><span class="t">${t}</span></button>`).join("")}</span>`;
  }
  // 端末の設定が変わったら追いかける（自分で選んでいないときだけ）
  mq.addEventListener("change", () => { if (!saved()) { apply(); draw(); } });
  document.addEventListener("click", e => {
    const b = e.target.closest("[data-look-set]");
    if (!b) return;
    // スマホ幅では今の見た目のボタンだけが見えている。押したら反対側へ切り替える
    const next = b.getAttribute("aria-pressed") === "true" ? (b.dataset.lookSet === "dark" ? "light" : "dark") : b.dataset.lookSet;
    try { localStorage.setItem(KEY, next); } catch {}
    apply();
    draw();
  });
  document.addEventListener("DOMContentLoaded", draw);
})();
