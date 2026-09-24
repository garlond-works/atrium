-- 見本データ（入れなくても動きます）。
-- 架空の取引先「サンプル商事」と、その Guest Room・案件・やること・伝言を1つずつ作ります。
-- 入れ方：npx wrangler d1 execute atrium --remote --file=seed.sql
-- 消したくなったら、執務室でサンプル商事を「消す」でOKです。

INSERT INTO clients (id, name, short_name, status, note, created_at, updated_at)
VALUES ('c-sample', '株式会社サンプル商事', 'サンプル商事', 'active', '見本の取引先です（内部メモは先方には見えません）', '2026-01-01T00:00:00.000Z', '2026-01-01T00:00:00.000Z');

INSERT INTO rooms (id, client_id, name, slug, is_open, created_at, theme_hue, memo, memo_updated_at)
VALUES ('r-sample', 'c-sample', 'サンプル商事 Guest Room', 'sample', 1, '2026-01-01T00:00:00.000Z', 210,
        'ようこそ Guest Room へ。資料・やりとり・お願いごとをここにまとめます。', '2026-01-01T00:00:00.000Z');

INSERT INTO cases (id, room_id, title, summary, status, waiting_on, due_on, sort_order, created_at)
VALUES ('k-sample', 'r-sample', '業務フローの整理', 'いまの仕事の流れを一枚にまとめる', 'open', 'client', NULL, 0, '2026-01-01T00:00:00.000Z');

INSERT INTO milestones (id, client_id, room_id, title, status, due_on, case_id, sort_order, created_at, updated_at)
VALUES ('m-sample', 'c-sample', 'r-sample', '今お使いの帳票を1枚ください', 'todo', NULL, 'k-sample', 0, '2026-01-01T00:00:00.000Z', '2026-01-01T00:00:00.000Z');

INSERT INTO messages (id, room_id, body, author_email, author_side, case_id, created_at)
VALUES ('g-sample', 'r-sample', 'はじめまして。こちらでやりとりさせてください。', 'owner', 'us', 'k-sample', '2026-01-01T00:00:00.000Z');
