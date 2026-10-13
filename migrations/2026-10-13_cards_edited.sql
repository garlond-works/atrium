-- 名刺を Office の画面で手直しできるようにする（2026-10-13）。
-- 手で直した名刺には edited_at を付け、あとから README の手順で台帳に入れ直しても上書きしない。
-- すでに Atrium を使っている場合だけ、この1行を流してください（新しく作る場合は schema.sql に入っています）。
ALTER TABLE cards ADD COLUMN edited_at TEXT;
