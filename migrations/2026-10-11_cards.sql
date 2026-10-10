-- 名刺（オーナーだけが見る。取引先には出さない）。入れ方は README。
-- id は名刺を読み取ったアプリ側の id（例：ScanSnap Home の名刺の id）。同じ名刺を二度入れない・直した分を上書きするために使う。
-- Atrium で消した名刺は deleted_at だけ残す（画像は消す）。次の取り込みで戻ってこないようにするため。
CREATE TABLE cards (
  id               TEXT PRIMARY KEY,
  company          TEXT NOT NULL DEFAULT '',
  company_kana     TEXT NOT NULL DEFAULT '',
  name             TEXT NOT NULL DEFAULT '',
  name_kana        TEXT NOT NULL DEFAULT '',
  department       TEXT NOT NULL DEFAULT '',
  job_title        TEXT NOT NULL DEFAULT '',
  scanned_on       TEXT,
  source_modified  TEXT NOT NULL,
  image_key        TEXT,
  pdf_key          TEXT,
  created_at       TEXT NOT NULL,
  updated_at       TEXT NOT NULL,
  deleted_at       TEXT
);
