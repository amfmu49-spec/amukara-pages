# AMU KARA（GitHub Pages版）

曲を端末の中でボーカル／伴奏に分離するWebアプリ。分離モデルと実行ライブラリを全部同梱しているので、外部サーバーへの通信なしで動きます（モデルが読めなかった場合の予備としてのみ Hugging Face を参照）。

## 中身

- `index.html` … 本体
- `assets/` … モデル（model-inst-main.onnx、約53MB）、ONNX Runtime 一式、ヘッダー画像

**フォルダ構成は崩さず、そのまま全部**使ってください。

## 公開手順（GitHub Pages）

1. GitHub で新しいリポジトリを作る（名前は自由。例：`amukara`）
2. このフォルダの中身一式をリポジトリへ push する（絵muの時と同じ Git 経由）
   - ⚠️ 一番大きいファイルが約53MBあるため、**ブラウザからのアップロード（25MB上限）では入りません**。Git コマンド／GitHub Desktop 等で push してください
3. リポジトリの **Settings → Pages** で、公開元を `main` ブランチの `/(root)` に設定
4. 数分後に `https://amfmu49-spec.github.io/<リポジトリ名>/` で公開されます

## 更新の仕方

`index.html` か `assets/` のファイルを差し替えて push すれば、自動で公開側に反映されます。

## 注意

- 合計サイズは約88MBです（GitHub の上限内）
- 公開前に、自分の端末でページを開いて「最初の30秒」で分離が完走するか確認してください
