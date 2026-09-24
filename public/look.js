// 見た目の切り替え（やわらか／クール）。見る人が選び、その人のブラウザに覚える。
// <head> で読み込み、描く前に data-look を付ける（一瞬前の見た目が出るのを防ぐ）。
(function () {
  const KEY = "atrium-look";
  let look = "soft";
  try { if (localStorage.getItem(KEY) === "cool") look = "cool"; } catch {}
  document.documentElement.dataset.look = look;

  const LOOKS = [
    ["soft", "やわらか", '<path d="M12 4.5c1.8 0 3 1.4 3 3.1 1.6-.7 3.5.1 3.9 1.8.4 1.7-.7 3.1-2.2 3.5 1 1.3.9 3.2-.5 4.2-1.4 1-3.2.5-4.2-.7-1 1.2-2.8 1.7-4.2.7-1.4-1-1.5-2.9-.5-4.2-1.5-.4-2.6-1.8-2.2-3.5.4-1.7 2.3-2.5 3.9-1.8 0-1.7 1.2-3.1 3-3.1Z"/><circle cx="12" cy="12" r="2"/>'],
    ["cool", "クール", '<path d="M12 3.5 20 12l-8 8.5L4 12Z"/><path d="M4 12h16M12 3.5v17"/>'],
  ];
  function draw() {
    const box = document.getElementById("look");
    if (!box) return;
    const cur = document.documentElement.dataset.look;
    box.innerHTML = `<span class="look" role="group" aria-label="見た目">${LOOKS.map(([k, t, d]) =>
      `<button type="button" data-look-set="${k}" aria-pressed="${cur === k}" title="${t}">
        <svg class="ic" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round" aria-hidden="true">${d}</svg><span class="t">${t}</span></button>`).join("")}</span>`;
  }
  document.addEventListener("click", e => {
    const b = e.target.closest("[data-look-set]");
    if (!b) return;
    // スマホ幅では今の見た目のボタンだけが見えている。押したら反対側へ切り替える
    const next = b.getAttribute("aria-pressed") === "true" ? (b.dataset.lookSet === "cool" ? "soft" : "cool") : b.dataset.lookSet;
    document.documentElement.dataset.look = next;
    try { localStorage.setItem(KEY, next); } catch {}
    draw();
  });
  document.addEventListener("DOMContentLoaded", draw);
})();
