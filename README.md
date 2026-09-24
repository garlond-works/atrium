# Atrium — 取引先ポータル

取引先ごとに「応接室」を用意して、資料・やりとり・お願いごとを一か所にまとめるポータルです。
Cloudflare（Workers・D1・R2・Access）の上で動きます。サーバーの管理は要りません。

この版は **素組み（ベアボーン）** です。ロゴや会社名は入っていないので、自分のものに差し替えて使ってください。

> Originally built by [GARLOND WORKS](https://garlondworks.com)

---

## できること

Atrium は3つの部屋でできています。名前は古代ローマの邸宅から借りました（主人が客を迎える広間＝アトリウム、その奥に主人の書斎）。

| 部屋 | 誰が入れるか | 中身 |
|---|---|---|
| **執務室（Office）** | あなただけ | 全取引先の横断ビュー／予定／タスク／取引先ごとの台帳と内部メモ |
| **取引先の台帳** | あなただけ | 作りかけの資料・内部限定の資料。ここで作って、完成したものだけを応接室に出す |
| **応接室（Guest Room）** | あなたと、招いた取引先 | 案件ごとの資料・伝言・やること・メモ・お知らせ |

- 取引先は **アカウントを作らずに** 入れます。メールアドレスを入れると確認コードが届く方式です（Cloudflare Access の One-time PIN）
- 資料は案件に結びつけて置けます。取引先も資料を置けて、自分が置いたものは自分で引き取れます
- 「いまどちらが動く番か」（先方／こちら）を案件ごとに持てます
- 見た目は「やわらか／クール」の2種類を、右上で切り替えられます
- **相談ロボ（任意）**：取引先が、応接室の資料をもとに AI へ質問できます（Workers AI）

## 必要なもの

- Cloudflare のアカウント（無料プランで動きます）
- Node.js 18 以降
- 独自ドメインは不要です（`<名前>.<サブドメイン>.workers.dev` で動きます）

人数について：入室の判定に使う Cloudflare Zero Trust は、**無料プランで50ユーザーまで** です（あなたと、招いた取引先の人を合わせた数）。それを超える場合は Cloudflare の有料プランが必要です。

---

## 導入のしかた

### 1. ダウンロードする

```bash
git clone https://github.com/garlond-works/atrium.git
cd atrium
npm install
npx wrangler login
```

### 2. データベース（D1）を作る

```bash
npx wrangler d1 create atrium
```

表示された `database_id` を、`wrangler.jsonc` の `"paste-your-database-id-here"` に貼ります。そのあと表を作ります。

```bash
npm run db:init
npm run db:seed   # 見本の取引先「サンプル商事」を入れる（入れなくても動きます）
```

### 3. 資料の置き場（R2）を作る

```bash
npx wrangler r2 bucket create atrium-documents
```

R2 を初めて使うときは、Cloudflare のダッシュボードで R2 を有効にする操作が必要な場合があります。

### 4. 自分の情報を入れる

`wrangler.jsonc` の `vars` を書き換えます。

| 項目 | 入れるもの |
|---|---|
| `OWNER_EMAIL` | あなたのメールアドレス。このアドレスで入った人だけが執務室を開けます |
| `ORG_NAME` | 画面と相談ロボが名乗る会社名 |
| `ORG_ABOUT` | 相談ロボに伝える会社の説明（1文・空でもよい） |
| `ACCESS_TEAM_DOMAIN` | 手順 6 で確認します |
| `ACCESS_AUD` | 手順 6 で確認します |

ロゴは `public/logo.svg` を差し替えてください（右上に 40×40 で出ます）。

### 5. 公開する

```bash
npm run deploy
```

表示された `https://atrium.<サブドメイン>.workers.dev` があなたの Atrium です。
**この時点ではまだ誰も入れません**（Access の設定がないと、すべて止まる作りです）。

### 6. 入口の鍵（Cloudflare Access）をかける

Atrium は、入口の本人確認をすべて Cloudflare Access に任せています。

1. Cloudflare のダッシュボードで **Zero Trust** を開きます（初回はチーム名を決める画面が出ます）
2. **Access → Applications → Add an application → Self-hosted** を選びます
3. **Application domain** に、手順 5 の `atrium.<サブドメイン>.workers.dev` を入れます
4. **Policies（ポリシー）** を1つ作ります
   - Action：**Allow**
   - Include：**Emails** に、あなたのアドレスを入れます（取引先のアドレスは、招くときに足していきます）
5. **Login methods** で **One-time PIN** を有効にします
6. 保存したら、アプリケーションの画面で次の2つを控えます
   - **Application Audience (AUD) Tag** → `wrangler.jsonc` の `ACCESS_AUD`
   - チームのドメイン（`<チーム名>.cloudflareaccess.com`。Zero Trust の **Settings** に出ています）→ `ACCESS_TEAM_DOMAIN`
7. もう一度 `npm run deploy` します

`https://atrium.<サブドメイン>.workers.dev` を開いて、メールアドレス → 確認コードで執務室に入れたら完了です。

---

## 取引先を招くとき

1. 執務室の「取引先」から取引先を登録します（応接室が1つできます）
2. 取引先のページで、招く人のメールアドレスを名簿に足します
3. **Cloudflare Access のポリシー（手順 6-4 の Emails）にも、同じアドレスを足します**
4. 「招待メール」を押すと、宛先・件名・本文が入ったメールの作成画面が開きます。送信はご自身で

> **3 を忘れやすいので注意してください。** Access は、ポリシーにないアドレスには確認コードを送りません。
> 断った記録もこちらには残らないので、「コードが届かない」と言われたら、まずここを確かめてください。

名簿から外すと、その人は応接室に入れなくなります（Access のポリシーからも外しておくと確実です）。

---

## 相談ロボを使う（任意）

最初は **オフ** です。使うときは `wrangler.jsonc` の次の行の `//` を外して、もう一度公開します。

```jsonc
"ai": { "binding": "AI" },
```

- AI は Cloudflare Workers AI（Gemma 4）を使います
- Workers AI には無料枠（1日 10,000 Neurons）があります。超えて使うには Workers の有料プランが必要で、使った分の料金がかかります
- 1つの応接室につき、1日20回までにしています（`src/index.js` の `ASK_PER_DAY`）
- ロボが読めるのは「その応接室で共有している資料」と「その場で渡したファイル」だけです。内部限定の資料や、ほかの応接室の資料は読みません
- 会話は記録され、あなた（執務室）からも読めます。取引先の画面にもそう書いてあります

---

## 手元で動かす

```bash
cp .dev.vars.example .dev.vars   # DEV_EMAIL に、手元で入ったことにするアドレスを書く
npm run db:init:local
npm run db:seed:local
npm run dev
```

`http://localhost:8787` で開きます。`DEV_EMAIL` は `localhost` のときだけ使われ、公開した Atrium では無視されます。
相談ロボは手元では動かない場合があります（Workers AI はリモート接続が必要なため）。

---

## 見た目を変える

- 色・書体・余白：`public/tokens.css`（デザインの約束）と `public/portal.css`
- 取引先ごとの色：執務室の取引先ページで12色から選べます
- ロゴ：`public/logo.svg`

---

## 設計の原則

コードのコメントに出てくる「設計の原則」は、次の7つです。

1. **権限は仕組みで守る。** アプリのコードで判定しない。入口の判定は Cloudflare Access、Atrium はその署名（JWT）を検証するだけ
2. **権限は空間の単位で切る。** ファイル単位で切り刻まない。応接室ごとに「誰が入れるか」を決める
3. **階層を捨ててメタデータで持つ。** フォルダを作らない。資料は取引先・案件・種別を属性として持つ
4. **一覧とプレビューを1画面に。** 「開く→違った→戻る」の往復をなくす
5. **公開版と下書きを分ける。** 作りかけは台帳で書き、完成したものだけを応接室に出す
6. **添付をやめ、1つの正本を参照させる。** ファイルの実体は R2 に1つだけ
7. **情報は向こうから来る。** 相手に探させない。新しい動きは開いた瞬間に目に入る

## 安全のための作り

- 入口は Cloudflare Access。Atrium は Access の署名つきの鍵（`cf-access-jwt-assertion`）を毎回検証し、`ACCESS_TEAM_DOMAIN`・`ACCESS_AUD` が未設定なら **すべて止まります**（開くより止まる）
- 版ごとのプレビュー URL は出さない設定です（`preview_urls: false`）
- 執務室は、オーナー以外には「存在しない（404）」と返します
- ほかの応接室を推測で開こうとしても、「無い」と「入れない」を区別せず 404 を返します（取引先の一覧が漏れないように）

---

## ライセンス

MIT License です。自由に使って、改造して、配ってかまいません。**無保証** で、サポートはしていません。

右下の「Originally built by GARLOND WORKS」は、残してもらえるとうれしいです（ライセンス上は消してもかまいません。`LICENSE` ファイルの著作権表示は残してください）。

使っているもの：
- フォント：Noto Sans JP・Be Vietnam Pro（Google Fonts・SIL Open Font License）
- PDF の読み取り（相談ロボ）：[pdf.js](https://github.com/mozilla/pdf.js)（Apache License 2.0・jsDelivr から読み込み）
- 祝日：[holidays-jp](https://github.com/holidays-jp/api)（執務室のカレンダー）
