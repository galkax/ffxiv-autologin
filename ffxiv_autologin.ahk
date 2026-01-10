; FFXIV Auto Login - Credential Manager 連携版
; 使い方:
; 1) 一度だけ `store-ffxiv-credential.ps1` を実行して Credential Manager に資格情報を保存してください。
; 2) このスクリプトを実行すると、PowerShell を呼んで保存済み資格情報を取得し、ログインフォームに自動入力します。

scriptDir := A_ScriptDir
exePath := "C:\Program Files (x86)\SquareEnix\FINAL FANTASY XIV - A Realm Reborn\boot\ffxivboot.exe"
windowExe := "ffxivboot.exe"

; PowerShell スクリプトで一時ファイルにユーザ名/パスワードを書き出させる
psGet := scriptDir "\get-ffxiv-credential.ps1"
RunWait, % "powershell -NoProfile -ExecutionPolicy Bypass -File """ psGet """" , , Hide

credsFile := scriptDir "\ffxiv_creds.tmp"
if !FileExist(credsFile)
{
    MsgBox, 16, エラー, 資格情報の取得に失敗しました。`store-ffxiv-credential.ps1` を実行しているか確認してください。
    ExitApp
}

FileReadLine, username, %credsFile%, 1
FileReadLine, password, %credsFile%, 2
FileDelete, %credsFile%

; 起動
Run, %exePath%, , , pid

timeout := 60
WinWait, ahk_exe %windowExe%, , %timeout%
if ErrorLevel
{
    MsgBox, 16, エラー, ウィンドウが見つかりませんでした（タイムアウト）。`exePath` と `windowExe` を確認してください。
    ExitApp
}

; ウィンドウが完全にロードされるまで待機
Sleep, 3000
WinActivate, ahk_exe %windowExe%
Sleep, 500

; クリップボード経由で貼り付け（SendInput が効かない場合の対策）
oldClip := ClipboardAll

; ユーザー名を貼り付け
Clipboard := username
Sleep, 100
Send, ^a
Sleep, 50
Send, ^v
Sleep, 300

; Tab でパスワード欄へ移動
Send, {Tab}
Sleep, 300

; パスワードを貼り付け
Clipboard := password
Sleep, 100
Send, ^a
Sleep, 50
Send, ^v
Sleep, 300

; クリップボードを復元
Clipboard := oldClip
oldClip := ""

; Enter でログイン
Send, {Enter}

ExitApp
