-- 先方の動きのうち、執務室の「先方の動き」に出さない動き（見た・取り出した・相談など）に「確認済み」の印を付ける（2026-10-11）。
-- これからの記録は src/index.js の log() が最初から印を付ける。印の無い行は idx_activity_unseen に溜まり続け、毎回読む行が増えるため。
UPDATE activity_log SET seen_at = created_at
 WHERE seen_at IS NULL AND action NOT IN ('upload', 'message', 'withdraw', 'purge');
