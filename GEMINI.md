# プロジェクト記憶・用語定義

## アムカラ / AMU KARA
ユーザーが「**アムカラ**」または「**AMU KARA**」と呼んだ場合は、以下のWebアプリケーションを指します。

- **ローカルパス:** `C:\Users\evoli\Downloads\amukara-pages`
- **GitHubリポジトリ:** `https://github.com/amfmu49-spec/amukara-pages`
- **公開URL (GitHub Pages):** `https://amfmu49-spec.github.io/amukara-pages/`
- **アプリ概要:**
  - 端末内（ブラウザ上の WebGPU / CPU WASM）で音声ファイルを「ボーカル」と「伴奏」に分離し、SRT形式の歌詞と連動してカラオケ表示・ミキサー再生を行う静的Webアプリ。
  - ビルドツール（Vite等）を使わない単一HTML構成（`index.html` + `assets/`）。
  - `assets/` 内にAIモデル（`model-inst-main.onnx`、約53MB）と ONNX Runtime Web（`ort.all.min.mjs`, `ort.wasm.min.mjs`, `ort-worker.js` 等）を同梱。
- **更新・デプロイ方法:**
  - `C:\Users\evoli\Downloads\amukara-pages\deploy.bat`（内部で `deploy.ps1` を実行）をダブルクリックするだけで、`main` ブランチへのコミット＆プッシュが行われ GitHub Pages が更新される。

