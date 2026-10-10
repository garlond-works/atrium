-- ゲストルームの資料に、短い説明（任意）を添えられるようにする。双方が書ける・直せる。
ALTER TABLE documents ADD COLUMN note TEXT;
