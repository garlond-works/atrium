-- 先方の動きの「まだ確認していない」だけを持つ索引（2026-10-11）。
-- Office のホームは1分ごとに先方の動きを取り直す。索引が無いと毎回 activity_log を全部読み、記録が増えると
-- D1 の無料枠（1日 500万行の読み取り）に届く。確認済みの行は索引に入らないので、読むのはほぼ0行になる。
CREATE INDEX IF NOT EXISTS idx_activity_unseen ON activity_log(created_at) WHERE seen_at IS NULL AND actor_side = 'client';
