-- ゲストルームの資料：双方が、誰が置いた資料でもゴミ箱に入れられる／戻せる／完全に消せる。
-- ゴミ箱に入れる＝既存の withdrawn_at を使う（誰が入れたかを withdrawn_by に残す）。
-- 完全に消す＝R2 の実体と文字の控えを消し、purged_at を入れる（台帳の行・操作の記録は残す）。
ALTER TABLE documents ADD COLUMN withdrawn_by TEXT;
ALTER TABLE documents ADD COLUMN purged_at TEXT;
