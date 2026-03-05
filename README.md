# printables

OpenSCAD で記述された 3D モデルを統合管理するモノレポ。  
共通ライブラリを複数のプロジェクトで共有しながら、統一されたビルドワークフローで各プロジェクトをビルド・デプロイできます。

---

## ディレクトリ構成

```
printables/
├── .github/
│   └── workflows/
│       ├── build.yml              # CI/CD：変更検知 → バンドル → アーティファクトのアップロード
│       └── deploy-site.yml        # カタログサイトのビルド → GitHub Pages デプロイ
├── libs/
│   ├── BOSL2/                     # BOSL2 ライブラリ（git submodule）
│   └── common.scad                # 共通 OpenSCAD ユーティリティモジュール
├── projects/
│   └── example-box/               # サンプルプロジェクト（パラメトリック収納ボックス）
│       ├── project.json           # プロジェクトメタデータ（名前・バージョン・作者など）
│       └── main.scad              # メイン OpenSCAD ソースファイル
├── scripts/
│   ├── build.sh                   # ローカルビルド用ヘルパースクリプト
│   ├── bundle.py                  # バンドラー：use/include を展開して単一 .scad に統合
│   └── generate_catalog.py        # カタログサイト生成スクリプト
├── site/
│   ├── index.html                 # カタログサイトの HTML テンプレート
│   └── style.css                  # カタログサイトのスタイルシート
├── dist/                          # ビルド出力（git 管理対象外）
├── _site/                         # カタログサイト出力（git 管理対象外）
└── .gitignore
```

---

## 新しいプロジェクトの追加方法

1. `projects/` 以下にディレクトリを作成します：

   ```
   projects/my-model/
   ├── project.json
   └── main.scad
   ```

2. `main.scad` から共通ライブラリを参照します：

   ```openscad
   use <../../libs/common.scad>
   ```

3. `project.json` にメタデータを記入します：

   ```json
   {
       "name": "my-model",
       "description": "モデルの説明",
       "version": "1.0.0",
       "author": "your-name",
       "tags": ["tag1", "tag2"],
       "publish": true
   }
   ```

変更をプッシュすると、CI ワークフローが新規・変更されたプロジェクトを自動検知し、  
単一の自己完結型 `.scad` ファイルをビルドしてダウンロード可能なアーティファクトとして保存します。

---

## 共通ライブラリ（`libs/`）

再利用可能な OpenSCAD モジュールや関数は `libs/` に配置します。  
バンドル時に自動的に検索パスに含まれるため、以下のように参照できます：

```openscad
use <../../libs/common.scad>   // 相対パス（OpenSCAD GUI でも動作します）
```

`libs/common.scad` が提供するモジュール：

| モジュール | 説明 |
|---|---|
| `rounded_box(size, r, fn)` | 角を丸めた直方体ボックス |
| `cylinder_with_hole(h, r_outer, r_inner, fn)` | 中空円筒（チューブ） |
| `chamfer_box(size, chamfer)` | 上端にチャンファーを付けたボックス |
| `screw_hole(d, h, countersink, fn)` | 垂直方向のネジ穴 |

---

## ローカルビルド

### 全プロジェクトをビルド

```bash
bash scripts/build.sh
```

### 特定のプロジェクトをビルド

```bash
bash scripts/build.sh example-box
```

ビルド成果物は `dist/<プロジェクト名>.scad` に出力されます。

---

## CI/CD ワークフロー

`.github/workflows/build.yml` は `projects/`・`libs/`・`scripts/` へのプッシュや  
プルリクエスト時に自動実行されます。

| ステップ | 内容 |
|---|---|
| **detect-changes** | 再ビルドが必要なプロジェクトを検出します。`libs/` または `scripts/` に変更がある場合は**全プロジェクト**を再ビルドします。 |
| **build** | 対象プロジェクトをマトリックスで並列実行し、各プロジェクトの単一自己完結型 `.scad` ファイルを生成します。 |
| **summary** | ワークフロー実行ページに Markdown 形式のビルド結果サマリーを書き出します。 |

バンドル済み `.scad` ファイルは GitHub Actions アーティファクトとしてアップロードされ、  
MakerWorld・Printables・Thingiverse などのサイトへ直接アップロードして公開できます。

**Actions → Build 3D Models → Run workflow** の UI から特定プロジェクトのみを手動ビルドすることも可能です。

### カタログサイト（GitHub Pages）

`.github/workflows/deploy-site.yml` は Build 3D Models ワークフロー完了時（`workflow_run`）、
`site/` やワークフローファイル自体への変更時、および手動実行（`workflow_dispatch`）で自動実行されます。
最新の成功ビルドからアーティファクトをダウンロードし、プレビュー画像とバンドル済み `.scad` を含む
プロジェクトごとの zip アーカイブを作成してカタログサイトに組み込み、GitHub Pages にデプロイします。

| ステップ | 内容 |
|---|---|
| **build** | ビルドアーティファクトをダウンロードし、`site/` のテンプレートとプロジェクトメタデータから `_site/index.html` を生成します。各プロジェクトカードにはダウンロードボタン（zip アーカイブ）が含まれます。 |
| **deploy** | 生成されたサイトを GitHub Pages にデプロイします。 |

#### ローカルプレビュー

```bash
python scripts/generate_catalog.py --output-dir _site --repo-root .
# ダウンロードボタン付きで生成する場合（事前にビルドアーティファクトを配置）:
# python scripts/generate_catalog.py --output-dir _site --repo-root . --images-dir _site/images --downloads-dir _site/downloads
# 生成された _site/index.html をブラウザで開いてください
```

> **初回セットアップ**: GitHub Pages を有効にするには **Settings → Pages → Source → GitHub Actions** を選択してください。
