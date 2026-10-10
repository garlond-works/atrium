-- 執務室の自分用ノート（GarlondWorks だけが見る。取引先には出さない）。
-- 何枚でも作れる。取引先への結びつけは任意（client_id が NULL なら自分だけのメモ）。
CREATE TABLE notes (
  id          TEXT PRIMARY KEY,
  title       TEXT NOT NULL DEFAULT '',
  body        TEXT NOT NULL DEFAULT '',
  client_id   TEXT REFERENCES clients(id),
  created_at  TEXT NOT NULL,
  updated_at  TEXT NOT NULL
);
CREATE INDEX idx_notes_updated ON notes(updated_at);
