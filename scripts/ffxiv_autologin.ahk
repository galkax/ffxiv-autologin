; FFXIV Auto Login - Credential Manager 連携版
; 使い方:
; 1) 一度だけ `store-ffxiv-credential.ps1` を実行して Credential Manager に資格情報を保存してください。
; 2) このスクリプトを実行すると、PowerShell を呼んで保存済み資格情報を取得し、ログインフォームに自動入力します。

scriptDir := A_ScriptDir
; NOTE: If you see garbled Japanese text (mojibake), save this file as "UTF-8 with BOM".
; AutoHotkey (Unicode) expects a BOM-aware UTF-8 file for correct non-ASCII handling.
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

; 簡易検証（ログ出力を削除）
nonAscii := false
Loop, Parse, username
{
    if (Asc(A_LoopField) > 127) {
        nonAscii := true
        break
    }
}
if (nonAscii) {
    MsgBox, 48, 注意, ユーザー名に非ASCII文字が含まれています（エンコーディングに注意）。
}
if (StrLen(username) = 0 || StrLen(password) = 0) {
    MsgBox, 16, エラー, 資格情報が空です。スクリプトを中止します。
    ExitApp
}

; （オプション）より詳しいバイト列ログが必要ならコメント解除して下さい（パスワードは出力しません）

; 起動
Run, %exePath%, , , pid

timeout := 60
WinWait, ahk_exe %windowExe%, , %timeout%
if ErrorLevel
{
    MsgBox, 16, エラー, ウィンドウが見つかりませんでした（タイムアウト）。`exePath` と `windowExe` を確認してください。
    ExitApp
}

; ウィンドウが完全にロードされるまで待機（コントロールベース）
WinActivate, ahk_exe %windowExe%
Sleep, 1000

; ログイン画面が完全に表示されるのを待つ（PixelSearch を優先、ダメならコントロールをフォールバック）
; 座標と色は環境に合わせて調整してください（例では 800,470 と緑色のサンプルを使用）
LOGIN_DETECT_X := 800
LOGIN_DETECT_Y := 470
; 近似色（サンプル画像に基づく例）。色が違う場合は Window Spy で確認して置き換えてください。
LOGIN_DETECT_COLOR := 0x7CF13B
LOGIN_DETECT_VARIATION := 40  ; 許容差（0-255）。環境により調整してください。

maxWait := 30  ; 秒
elapsed := 0
CoordMode, Pixel, Screen
Loop {
    if (elapsed >= maxWait) {
        MsgBox, 16, Error, Login screen load timed out.
        ExitApp
    }

    ; 1) 画像マッチを最優先（login_button.png を置くと有効）
    imgPath := scriptDir "\\..\\assets\\login_button.png"
    if FileExist(imgPath) {
        ImageSearch, ix, iy, 0, 0, A_ScreenWidth, A_ScreenHeight, %imgPath%
        if (ErrorLevel = 0) {
            break
        }
    }

    ; 2) 観測済み色による高速判定
    PixelGetColor, sampledColor, %LOGIN_DETECT_X%, %LOGIN_DETECT_Y%, RGB
    observedColors := ["0xF9FBFA", "0xB66010", "0x251500"]
    StringUpper, sampledColor, sampledColor
    matched := false
    for index, col in observedColors {
        StringUpper, col, col
        if (col = sampledColor) {
            matched := true
            break
        }
    }
    if (matched) {
        break
    }

    ; 3) 指定座標周辺の色を検索（小さい領域でマッチを許容）
    x1 := LOGIN_DETECT_X - 6
    y1 := LOGIN_DETECT_Y - 6
    x2 := LOGIN_DETECT_X + 6
    y2 := LOGIN_DETECT_Y + 6
    PixelSearch, px, py, x1, y1, x2, y2, %LOGIN_DETECT_COLOR%, %LOGIN_DETECT_VARIATION%, Fast RGB
    if (ErrorLevel = 0) {
        break
    }

    ; 4) コントロールフォールバック
    ControlGet, ctrlExists, Enabled, , Edit1, ahk_exe %windowExe%
    if (ctrlExists) {
        break
    }

    Sleep, 1000
    elapsed += 1
}

; さらに安定させるため少し待機
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

; --- ここから: ログイン後に表示される「プレイ」ボタンを待ってクリック ---
; プレイボタン画像があれば ImageSearch で検出してクリックします。
playImg := scriptDir "\\..\\assets\\play_button.png"
if FileExist(playImg) {
    CoordMode, Mouse, Screen
    ; 画面全体を検索（必要に応じて範囲を絞ってください）
    playWait := 30
    pElapsed := 0
    foundPlay := false
    Loop {
        if (pElapsed >= playWait) {
            break
        }
        ImageSearch, px, py, 0, 0, A_ScreenWidth, A_ScreenHeight, %playImg%
        if (ErrorLevel = 0) {
            foundPlay := true
            ; 画像の左上が (px,py) に入る。画像中央付近をクリックする。
            ; 元のキャプチャに合わせたオフセット（中央付近）を使用。
            clickX := px + 100
            clickY := py + 18
            WinActivate, ahk_exe %windowExe%
            Sleep, 120
            CoordMode, Mouse, Screen
            MouseMove, %clickX%, %clickY%, 0
            Sleep, 80
            Click
            Sleep, 300
            break
        }
        Sleep, 500
        pElapsed += 0.5
    }

    ; ImageSearch がタイムアウトして見つからない場合は、
    ; 指定座標 (850,470) を1回だけクリックしてみる（フォールバック）。
    if (!foundPlay) {
        WinActivate, ahk_exe %windowExe%
        Sleep, 120
        CoordMode, Mouse, Screen
        MouseMove, 850, 470, 0
        Sleep, 80
        Click
        Sleep, 300
    }
}

ExitApp
