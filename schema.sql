-- Atrium — データモデル（Cloudflare D1 / SQLite）
--
-- 設計の前提（README の「設計の原則」より）
--   原則1「権限は仕組みで守る」  → 入室可否はこのDBで判定しない。Cloudflare Access が判定する
--   原則3「階層を捨ててメタデータ」 → フォルダを表すテーブルは作らない。属性で絞り込む
--   原則5「公開版と下書きを分ける」 → room_id / published_at の NULL で表現する
--   原則6「1つの正本を参照させる」  → ファイルの実体は R2 に1つ。DBはその参照だけ持つ
--
-- 日時は ISO8601 文字列（UTC）で持つ。SQLite に日時型はない。

PRAGMA foreign_keys = ON;


-- ─────────────────────────────────────────────
-- 取引先（タブリヌム＝取引先の部屋の実体）
-- このテーブルの中身は応接室に出ない。内部台帳。
-- ─────────────────────────────────────────────
CREATE TABLE clients (
  id          TEXT PRIMARY KEY,
  name        TEXT NOT NULL,                      -- 株式会社サンプル商事
  short_name  TEXT,                               -- サンプル商事（一覧の表示用）
  status      TEXT NOT NULL DEFAULT 'active',     -- active（進行中）/ following（フォロー中）/ archived / deleted（執務室で消した。行は残し、部屋も閉じる）
  note        TEXT,                               -- 内部メモ。相手には見えない
  created_at  TEXT NOT NULL,
  updated_at  TEXT NOT NULL
);

CREATE INDEX idx_clients_status ON clients(status);


-- ─────────────────────────────────────────────
-- 応接室
-- slug が URL のパスになり、Cloudflare Access のアプリケーションパスと一致する。
-- ＝ 扉の位置。ここがズレると権限がズレるので、変更は慎重に。
-- 取引先ごとに1室が基本だが、案件ごとに分けたくなった時のために別テーブルにしてある。
-- ─────────────────────────────────────────────
CREATE TABLE rooms (
  id          TEXT PRIMARY KEY,
  client_id   TEXT NOT NULL REFERENCES clients(id),
  name        TEXT NOT NULL,                      -- 「サンプル商事 応接室」
  slug        TEXT NOT NULL UNIQUE,               -- /room/sample
  is_open     INTEGER NOT NULL DEFAULT 1,         -- 0 = 閉室（アプリ側の表示制御。扉の鍵とは別物）
  created_at  TEXT NOT NULL,
  -- 部屋の色。0-359 の色相ひとつだけ持つ（3色は CSS が明度3段で作る）。
  -- NULL = slug から自動で決まる（30度刻みの12択）。取引先のブランドカラーに
  -- 寄せたくなったら、ここに数値を入れれば手動で上書きできる。
  theme_hue   INTEGER,
  -- 部屋のメモ（2026-09-23 追加）。オーナーが書き、取引先が読む。更新は「お知らせ」に自動で出る
  memo            TEXT,
  memo_updated_at TEXT
);


-- ─────────────────────────────────────────────
-- 案件（2026-09-23 追加）
--
-- 仕事は「資料」でも「伝言」でもなく、用件の単位で動く。
-- 「見積もり自動化」という案件の中に、渡した依頼書があり、やりとりがあり、期日がある。
--
-- クライアントポータル製品（Basecamp・Moxo・SuiteDash・Assembly）の標準は
-- クライアント > 案件 > 中身 の3階層。Basecamp が理由を明記している：
--   「資料がタスクや議論の隣に置かれているから、常に文脈がある。
--     その資料を承認した決定のすぐ隣に、その資料がある」
--
-- ⚠️ これはフォルダではない。documents / messages / tasks は case_id という
--    属性を1つ持つだけで、階層には入らない（原則3「階層を捨ててメタデータで持つ」）。
--    NULL なら「どの案件にも属さない」＝その他の棚。既存の行は NULL のまま動く。
--
-- 扉は分けない。案件ごとに部屋を作ると Cloudflare Access のポリシーが
-- 案件の数だけ要り、50シートも食う。部屋は取引先ごとに1つのまま、中で案件が分かれる。
-- ─────────────────────────────────────────────
CREATE TABLE cases (
  id          TEXT PRIMARY KEY,
  room_id     TEXT NOT NULL REFERENCES rooms(id),
  title       TEXT NOT NULL,                      -- 「見積もり自動化」
  summary     TEXT,                               -- 一行の説明。相手にも見える
  status      TEXT NOT NULL DEFAULT 'open'
              CHECK (status IN ('open','waiting','done')),
  -- いまどちらが動く番か。セッション橋渡しノートの案件ボードで実際に使っている列。
  -- 共有する画面では「ボールを持っているのが誰か」が一目で分かることが効く。
  waiting_on  TEXT CHECK (waiting_on IN ('us','client')),
  due_on      TEXT,                               -- 'YYYY-MM-DD'
  sort_order  INTEGER NOT NULL DEFAULT 0,
  created_at  TEXT NOT NULL,
  closed_at   TEXT                                -- 終わった案件も消さない（記録）
);

CREATE INDEX idx_cases_room ON cases(room_id, status);


-- ─────────────────────────────────────────────
-- 応接室の名簿
--
-- ⚠️ これは認証に使わない。入室可否を決めるのは Cloudflare Access のポリシー。
--    アプリは Access が付ける JWT からメールアドレスを受け取るだけ。
--    この表の用途は「誰を招いたかを画面に出す」ことと「置いた人の表示名を引く」こと。
--
-- 運用上の注意：Access 側のポリシーとこの表は別管理になる。招待・解除のときは
-- 両方を更新する必要がある。ここは将来 Access API での自動化を検討する余地がある。
-- ─────────────────────────────────────────────
CREATE TABLE room_members (
  room_id       TEXT NOT NULL REFERENCES rooms(id),
  email         TEXT NOT NULL,
  display_name  TEXT,
  invited_at    TEXT NOT NULL,
  revoked_at    TEXT,                             -- 解除済み。行は消さない（誰がいたかの記録を残す）
  mailed_at     TEXT,                             -- 招待メールの下書きを開いた時刻（2026-09-23 追加。送信はメールソフト側）
  PRIMARY KEY (room_id, email)
);


-- ─────────────────────────────────────────────
-- 資料
--
-- フォルダはない。category と doc_type で絞り込む（原則3）。
--
-- room_id が NULL     = まだ応接室に出していない（＝下書き・内部資料）
-- room_id が NOT NULL = 応接室に出ている
-- この1カラムで原則5（公開版と下書きの分離）が成立する。
-- 「執務室で作って応接室に出す」は room_id を埋める UPDATE 一回。
--
-- uploaded_by_side は削除可否の判定に使う（応接室の既定ルール）：
--   'client' が置いたもの → その相手が引っ込められる
--   'us'     が置いたもの → 相手は触れない
-- ─────────────────────────────────────────────
CREATE TABLE documents (
  id                TEXT PRIMARY KEY,
  client_id         TEXT NOT NULL REFERENCES clients(id),
  room_id           TEXT REFERENCES rooms(id),
  title             TEXT NOT NULL,
  r2_key            TEXT NOT NULL,                -- R2 上の正本の位置（原則6）
  mime_type         TEXT,
  size_bytes        INTEGER,
  category          TEXT,                         -- 見積 / 提案 / 議事録 / 納品物 / 参考
  uploaded_by       TEXT NOT NULL,                -- メールアドレス
  uploaded_by_side  TEXT NOT NULL CHECK (uploaded_by_side IN ('us','client')),
  confidential      INTEGER NOT NULL DEFAULT 0,   -- 1 = 内部限定（原価・与信・下交渉など）
  case_id           TEXT REFERENCES cases(id),    -- どの案件のものか。NULL = その他の棚
  created_at        TEXT NOT NULL,
  updated_at        TEXT NOT NULL,
  withdrawn_at      TEXT,                         -- 引っ込めた。物理削除はしない

  -- 内部限定の資料は、応接室に出すこと自体を DB が拒否する。
  -- room_id を埋める UPDATE ひとつで原価や与信が相手に見える事故を、
  -- 運用の注意ではなく構造で止める（原則1）。
  -- 出す必要が生じたら、まず confidential を 0 に戻す明示的な操作が要る。
  CHECK (NOT (confidential = 1 AND room_id IS NOT NULL))
);

CREATE INDEX idx_documents_room     ON documents(room_id, withdrawn_at);
CREATE INDEX idx_documents_client   ON documents(client_id);
CREATE INDEX idx_documents_category ON documents(category);


-- ─────────────────────────────────────────────
-- お知らせ（原則7「情報は向こうから来る」）
-- published_at が NULL なら下書き。documents と同じパターン。
-- ─────────────────────────────────────────────
CREATE TABLE announcements (
  id            TEXT PRIMARY KEY,
  room_id       TEXT NOT NULL REFERENCES rooms(id),
  body          TEXT NOT NULL,
  is_pinned     INTEGER NOT NULL DEFAULT 0,       -- 1 = 開いた瞬間に前面に出す
  published_at  TEXT,
  created_at    TEXT NOT NULL
);

CREATE INDEX idx_announcements_room ON announcements(room_id, published_at);


-- ─────────────────────────────────────────────
-- 伝言（チャット形式）
--
-- UIは吹き出しの時系列。LINEに慣れた人がそのまま使える形にする。
-- ただし中身は商談用で、LINEにできないことを持たせる：
--
--   document_id が肝。資料を開いた状態で発言すると、その資料に紐づく。
--   後から「この提案書について何を話したか」で辿れる。
--   NULL なら応接室全体への普通の発言。
--
-- 発言は物理削除しない。取り消しても「取り消されました」と残す。
-- 商談の記録なので、消えた事実も記録のうち。
--
-- リアルタイム配信（WebSocket）は第一段階では使わない。
-- Worker レベルの Access が WebSocket に対応していないため、
-- 対応させるにはホスト名ベースの Access ＝ カスタムドメインが要る。
-- 商談のやりとりは秒単位で返し合うものではないので、まずポーリングで作る。
-- ─────────────────────────────────────────────
CREATE TABLE messages (
  id            TEXT PRIMARY KEY,
  room_id       TEXT NOT NULL REFERENCES rooms(id),
  body          TEXT NOT NULL,
  author_email  TEXT NOT NULL,
  author_side   TEXT NOT NULL CHECK (author_side IN ('us','client')),
  document_id   TEXT REFERENCES documents(id),
  case_id       TEXT REFERENCES cases(id),         -- どの案件の話か。NULL = 部屋全体への発言
  created_at    TEXT NOT NULL,
  withdrawn_at  TEXT
);

CREATE INDEX idx_messages_room ON messages(room_id, created_at);
CREATE INDEX idx_messages_doc  ON messages(document_id);

-- 既読について：
-- メッセージ単位の既読はまだ持たない。誰がいつ応接室を見たかは activity_log に残るので、
-- 「相手が来たかどうか」はそこで分かる。発言ごとの既読が本当に要ると分かってから足す。

-- ─────────────────────────────────────────────
-- 進捗
-- room_id が NULL なら内部進捗（相手に見せない）。documents と同じ考え方。
-- ─────────────────────────────────────────────
CREATE TABLE milestones (
  id          TEXT PRIMARY KEY,
  client_id   TEXT NOT NULL REFERENCES clients(id),
  room_id     TEXT REFERENCES rooms(id),
  title       TEXT NOT NULL,
  status      TEXT NOT NULL CHECK (status IN ('todo','doing','done')),
  due_on      TEXT,                               -- YYYY-MM-DD
  done_at     TEXT,
  case_id     TEXT REFERENCES cases(id),           -- どの案件のやることか。NULL = その他
  sort_order  INTEGER NOT NULL DEFAULT 0,
  created_at  TEXT NOT NULL,
  updated_at  TEXT NOT NULL
);

CREATE INDEX idx_milestones_room ON milestones(room_id, status);


-- ─────────────────────────────────────────────
-- 執務室の予定とタスク（2026-09-23 追加）
--
-- 予定は Atrium が正本。Google カレンダーへは「共有しますか？」で
-- 入力済みの Google 画面を開き、オーナーが保存する（API 連携はしない）。
-- だから後で Atrium 側を直しても Google 側は付いてこない。gcal_shared_at は
-- 「共有を押した」記録で、Google に今も同じ内容があることは保証しない。
--
-- タスクは2種類を1つの一覧に並べる：
--   todos      … 自分の用事。相手には見えない
--   milestones … 取引先と共有する「やること」（上の表）。応接室に出る
-- milestones は client_id が必須なので、自分の用事を入れる場所として todos を分けた。
-- ─────────────────────────────────────────────
CREATE TABLE events (
  id              TEXT PRIMARY KEY,
  title           TEXT NOT NULL,
  day             TEXT NOT NULL,                 -- 'YYYY-MM-DD'（日本時間の日付）
  start_time      TEXT,                          -- 'HH:MM'。NULL = 終日
  end_time        TEXT,
  place           TEXT,
  memo            TEXT,
  client_id       TEXT REFERENCES clients(id),   -- どの取引先の用件か。NULL = 自分の予定
  gcal_shared_at  TEXT,
  created_at      TEXT NOT NULL,
  updated_at      TEXT NOT NULL
);

CREATE INDEX idx_events_day ON events(day);

CREATE TABLE todos (
  id          TEXT PRIMARY KEY,
  title       TEXT NOT NULL,
  due_on      TEXT,
  client_id   TEXT REFERENCES clients(id),
  done_at     TEXT,
  created_at  TEXT NOT NULL,
  updated_at  TEXT NOT NULL
);

CREATE INDEX idx_todos_open ON todos(done_at, due_on);


-- ─────────────────────────────────────────────
-- 操作ログ
-- 共有スペースでは「誰がいつ何をしたか」が残っていないと、認識のズレを後から解けない。
-- 資料の削除を禁じる設計なので、記録も消さない。
-- ─────────────────────────────────────────────
CREATE TABLE activity_log (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  room_id      TEXT REFERENCES rooms(id),
  actor_email  TEXT NOT NULL,
  actor_side   TEXT NOT NULL CHECK (actor_side IN ('us','client')),
  action       TEXT NOT NULL,                     -- upload / publish / withdraw / view / announce
  target_type  TEXT,                              -- document / announcement / milestone
  target_id    TEXT,
  created_at   TEXT NOT NULL,
  seen_at      TEXT                               -- 執務室で「確認済み」にした時刻（2026-09-23 追加）。先方の動きから外れる
);

CREATE INDEX idx_activity_room ON activity_log(room_id, created_at);


-- ─────────────────────────────────────────────
-- 第二段階（全文検索）について
--
-- Done の第二段階に「ファイル名を覚えていなくても資料に到達できる」を置いている。
-- SQLite には FTS5 があるが、Cloudflare D1 で FTS5 が使えるかは【未検証】。
-- 実装に入る前に実機で確認する。使えない場合の代替は Vectorize か、
-- documents に抽出テキスト列を持って LIKE 検索する簡易版になる。
-- ここでは先回りしてテーブルを作らない。
-- ─────────────────────────────────────────────

-- 相談ロボ（Gemma 4）— 2026-09-23
-- 取引先にAIを触ってもらう入口。会話は残し、オーナーも読める（画面にそう書く）。

-- ロボとの会話。人ごと（room × email）に一本の流れ。
CREATE TABLE ask_messages (
  id            TEXT PRIMARY KEY,
  room_id       TEXT NOT NULL REFERENCES rooms(id),
  author_email  TEXT NOT NULL,                 -- 話しかけた人（ロボの返事にも同じ人を入れて流れをまとめる）
  author_side   TEXT NOT NULL CHECK (author_side IN ('us','client')),
  role          TEXT NOT NULL CHECK (role IN ('user','assistant')),
  body          TEXT NOT NULL,
  document_ids  TEXT,                          -- JSON 配列：この質問で読ませた部屋の資料
  file_name     TEXT,                          -- この質問に添えたファイルの名前
  file_text     TEXT,                          -- 添えたファイルを文字にしたもの（ファイル本体は保存しない）
  forwarded_at  TEXT,                          -- 「オーナーに伝える」を押した時刻
  created_at    TEXT NOT NULL
);
CREATE INDEX idx_ask_room ON ask_messages(room_id, author_email, created_at);

-- 部屋の資料を文字にしたものの控え。毎回変換し直さないため。
-- 資料が差し替わったら（updated_at が変わったら）作り直す。
CREATE TABLE document_texts (
  document_id        TEXT PRIMARY KEY REFERENCES documents(id),
  text               TEXT,
  error              TEXT,
  source_updated_at  TEXT NOT NULL,
  created_at         TEXT NOT NULL
);
