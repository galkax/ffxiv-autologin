# FFXIV AutoLogin

FFXIV の起動時にユーザ名とパスワードを自動入力する AutoHotkey スクリプトです。

## 必要なもの
- [AutoHotkey](https://www.autohotkey.com/) (v1.1 推奨)
- PowerShell 5.1以上

## セットアップ（初回のみ）

1. PowerShell を開いてこのフォルダに移動:
```powershell
cd D:\git\ffxiv-autologin
```

2. 資格情報を Windows Credential Manager に保存:
```powershell
powershell -ExecutionPolicy Bypass -File .\store-ffxiv-credential.ps1
```
ダイアログが表示されるので、FFXIV のユーザ名とパスワードを入力してください。

## 使い方

スクリプトをダブルクリックするか、以下を実行:
```powershell
start .\ffxiv_autologin.ahk
```

## ファイル一覧
| ファイル | 説明 |
|----------|------|
| `ffxiv_autologin.ahk` | メインスクリプト（AHK） |
| `store-ffxiv-credential.ps1` | 資格情報を保存するヘルパー |
| `get-ffxiv-credential.ps1` | 資格情報を取得するヘルパー |

## 注意
- パスワードは Windows Credential Manager に安全に保存されます。
- 一時ファイル `ffxiv_creds.tmp` はスクリプト実行後に自動削除されます。
