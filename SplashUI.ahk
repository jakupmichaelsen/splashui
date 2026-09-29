#Requires AutoHotkey v2.0
#SingleInstance Force
#Include config.ahk

; Each panel owns its controls. Only one panel is open at a time.
App := SplashApp()
if A_Args.Length && A_Args[1] = "--self-test" {
    SelfTest()
    ExitApp()
}
App.Start()
if A_Args.Length && A_Args[1] = "--smoke-test"
    ExitApp()

class SplashApp {
    Window := 0
    Mode := ""
    DraftTimer := 0
    TestMode := false

    Start() {
        Hotkey("!F1", (*) => this.Menu("Commands", Commands))
        Hotkey("F1", (*) => this.Search())
        Hotkey("+F1", (*) => this.SelectionSearch())
        Hotkey("^!F11", (*) => this.Note(true))
        Hotkey("+!F11", (*) => this.Note(false))
        Hotkey("#F10", (*) => this.Menu("Lectio", LectioLinks))
        HotIf((*) => this.Window && WinActive("ahk_id " this.Window.Hwnd))
        Hotkey("^Enter", (*) => this.Accept())
        HotIf((*) => this.Mode = "menu" && this.Window && WinActive("ahk_id " this.Window.Hwnd))
        Hotkey("Down", (*) => this.Step(1))
        Hotkey("Up", (*) => this.Step(-1))
        HotIf()
        A_TrayMenu.Delete()
        A_TrayMenu.Add("Commands  ·  Alt+F1", (*) => this.Menu("Commands", Commands))
        A_TrayMenu.Add("Search  ·  F1", (*) => this.Search())
        A_TrayMenu.Add("Notes  ·  Ctrl+Alt+F11", (*) => this.Note(true))
        A_TrayMenu.Add("Resume saved note", (*) => this.Note(true, true))
        A_TrayMenu.Add("Edit configuration", (*) => Run('notepad.exe "' A_ScriptDir '\config.ahk"'))
        A_TrayMenu.Add("Reload", (*) => this.ReloadApp())
        A_TrayMenu.Add("Exit", (*) => ExitApp())
        A_IconTip := "SplashUI · Alt+F1 commands · F1 search"
        OnExit((*) => !this.Close())
    }

    ReloadApp() {
        if this.Close()
            Reload()
    }

    MonitorBounds(full := false) {
        n := Settings.Monitor
        if !IsInteger(n) {
            CoordMode("Mouse", "Screen")
            MouseGetPos(&x, &y)
            if n = "active" {
                try {
                    WinGetPos(&wx, &wy, &ww, &wh, "A")
                    x := wx + ww / 2, y := wy + wh / 2
                }
            }
            n := MonitorGetPrimary()
            Loop MonitorGetCount() {
                MonitorGet(A_Index, &l, &t, &r, &b)
                if x >= l && x < r && y >= t && y < b {
                    n := A_Index
                    break
                }
            }
        }
        if n < 1 || n > MonitorGetCount()
            n := MonitorGetPrimary()
        if full
            MonitorGet(n, &l, &t, &r, &b)
        else
            MonitorGetWorkArea(n, &l, &t, &r, &b)
        return {X: l, Y: t, W: r-l, H: b-t}
    }

    Begin(title, mode, full := false) {
        bounds := this.MonitorBounds(full)
        if !this.Close()
            return false
        this.Bounds := bounds
        this.Mode := mode
        this.Window := Gui("-Caption -Border +AlwaysOnTop -DPIScale", "SplashUI · " title)
        this.Window.BackColor := Settings.Background
        this.Window.MarginX := 0, this.Window.MarginY := 0
        this.Window.OnEvent("Escape", (*) => this.Close())
        this.Window.OnEvent("Close", (*) => this.Close())
        ; Geometry uses the same coordinate units as the monitor APIs.
        this.Scale := A_ScreenDPI / 96
        this.Window.SetFont("s" Settings.FontSize " c" Settings.Text, Settings.Font)
        return true
    }

    Heading(title, width, pad) {
        this.Window.SetFont("s20 c" Settings.Accent, Settings.Font)
        this.Window.AddText("x" pad " y" pad " w" width " h" Round(38*this.Scale), title)
        this.Window.SetFont("s" Settings.FontSize " c" Settings.Text, Settings.Font)
    }

    Hint(text, x, y, w) {
        this.Window.SetFont("s10 c" Settings.Text, Settings.Font)
        this.Window.AddText("x" x " y" y " w" w " h" Round(48*this.Scale), text)
    }

    Show(x, y, w, h, translucent := true) {
        this.Window.Show((this.TestMode ? "Hide " : "") "x" Round(x) " y" Round(y) " w" Round(w) " h" Round(h))
        if translucent
            WinSetTransparent(Max(80, Min(255, Settings.Opacity)), this.Window.Hwnd)
        this.Input.Focus()
    }

    DefaultButton() {
        this.Window.AddButton("x-200 y-200 w1 h1 Default", "OK").OnEvent("Click", (*) => this.Accept())
    }

    Menu(title, entries) {
        if !this.Begin(title, "menu")
            return
        b := this.Bounds, s := this.Scale, p := Round(24*s)
        w := Min(Round(520*s), b.W), h := b.H
        this.Heading(title, w-2*p, p)
        this.Input := this.Window.AddEdit("x" p " y" Round(78*s) " w" (w-2*p) " h" Round(36*s) " -E0x200 -Border Background" Settings.Background)
        this.List := this.Window.AddListBox("x" p " y" Round(132*s) " w" (w-2*p) " h" Max(60, h-Round(220*s)) " -E0x200 -Border Background" Settings.Background)
        this.Entries := entries
        this.Input.OnEvent("Change", (*) => this.Filter())
        this.List.OnEvent("DoubleClick", (*) => this.Accept())
        this.Hint("Type to filter · ↑ ↓ choose · Enter open · Esc close", p, h-Round(68*s), w-2*p)
        this.DefaultButton()
        this.Filter()
        this.Show(b.X, b.Y, w, h)
    }

    Filter() {
        this.Matches := [], labels := []
        query := Trim(this.Input.Value)
        for entry in this.Entries {
            if query = "" || InStr(entry.Label, query) {
                this.Matches.Push(entry)
                labels.Push(entry.Label)
            }
        }
        this.List.Delete()
        this.List.Add(labels.Length ? labels : ["No matching commands"])
        this.List.Choose(1)
    }

    Step(delta) {
        count := this.Matches.Length
        if count
            this.List.Choose(Mod(this.List.Value-1+delta+count, count)+1)
    }

    Search() {
        if !this.Begin("My search", "search")
            return
        b := this.Bounds, s := this.Scale, p := Round(30*s)
        w := Min(Round(700*s), b.W), h := Min(Round(240*s), b.H)
        this.Heading("My search", w-2*p, p)
        this.Input := this.Window.AddEdit("x" p " y" Round(88*s) " w" (w-2*p) " h" Round(40*s) " -E0x200 -Border Background" Settings.Background)
        this.Hint("d: Dictionary · t: Thesaurus · o: Ordnet · s: Sprotin`nn: Ngram · m: Maps · Enter search · Esc close", p, Round(150*s), w-2*p)
        this.DefaultButton()
        this.Show(b.X+b.W-w, b.Y+(b.H-h)/2, w, h)
    }

    Note(full := true, resume := false) {
        if !this.Begin(full ? "Notes" : "Quick note", "note", full)
            return
        b := this.Bounds, s := this.Scale
        w := full ? b.W : Min(Round(740*s), b.W)
        h := full ? b.H : Min(Round(500*s), b.H)
        p := Round(Min(full ? 150*s : 30*s, w/10, h/6))
        content := ""
        if resume && FileExist(Settings.DataDir "\draft.txt")
            content := FileRead(Settings.DataDir "\draft.txt", "UTF-8")
        else if full
            content := A_Clipboard
        this.Window.SetFont("s" Settings.NoteSize " c" Settings.Text, NoteFont())
        this.Input := this.Window.AddEdit("x" p " y" p " w" (w-2*p) " h" (h-2*p-Round(35*s)) " Multi WantTab WantReturn -E0x200 -Border -VScroll Background" Settings.Background, content)
        this.Hint("Ctrl+Enter copy & close · Esc save draft & close · Enter new line", p, h-p-Round(20*s), w-2*p)
        this.Input.OnEvent("Change", (*) => this.ScheduleDraft())
        this.Show(b.X, b.Y, w, h, false)
        SendMessage(0xB1, StrLen(content), StrLen(content), this.Input.Hwnd)
    }

    ScheduleDraft() {
        if this.DraftTimer
            SetTimer(this.DraftTimer, 0)
        this.DraftTimer := ObjBindMethod(this, "SaveDraft")
        SetTimer(this.DraftTimer, -750)
    }

    SaveDraft() {
        if this.Mode != "note" || !this.Window || this.TestMode
            return true
        try {
            DirCreate(Settings.DataDir)
            ; Replace only after writing successfully; retain the previous session too.
            path := Settings.DataDir "\draft.txt"
            if !this.HasOwnProp("BackedUp") {
                if FileExist(path)
                    FileCopy(path, Settings.DataDir "\previous-draft.txt", true)
                this.BackedUp := true
            }
            file := FileOpen(path ".tmp", "w", "UTF-8")
            file.Write(this.Input.Value)
            file.Close()
            FileMove(path ".tmp", path, true)
            return true
        } catch as err {
            MsgBox("Could not save the note. It remains open.`n`n" err.Message, "SplashUI")
            return false
        }
    }

    Accept() {
        if this.Mode = "note" {
            text := this.Input.Value
            if this.Close()
                A_Clipboard := text
        } else if this.Mode = "search" {
            query := Trim(this.Input.Value)
            if query != "" {
                this.Close()
                OpenTarget(SearchURL(query))
            }
        } else if this.Mode = "menu" && this.Matches.Length {
            entry := this.Matches[this.List.Value]
            this.Close()
            OpenTarget(entry.Target)
        }
    }

    Close() {
        if !this.Window
            return true
        if !this.SaveDraft()
            return false
        if this.DraftTimer
            SetTimer(this.DraftTimer, 0)
        this.DraftTimer := 0
        this.Window.Destroy()
        this.Window := 0, this.Mode := ""
        return true
    }

    SelectionSearch() {
        saved := ClipboardAll()
        text := ""
        try {
            A_Clipboard := ""
            Send("^c")
            if ClipWait(1)
                text := Trim(A_Clipboard)
        } finally {
            A_Clipboard := saved
        }
        if text = "" {
            this.Search()
            return
        }
        if RegExMatch(text, "i)^https?://\S+$")
            OpenTarget(text)
        else
            OpenTarget("https://www.google.com/search?q=" UrlEncode((GetKeyState("CapsLock", "T") ? "define " : "") text))
    }
}

NoteFont() {
    ; Per-user installs may exist before Windows publishes their registry entry.
    static loadedLocalFont := false
    if Settings.NoteFont = "Traveling _Typewriter" {
        if !loadedLocalFont {
            for path in [EnvGet("LOCALAPPDATA") "\Microsoft\Windows\Fonts\TravelingTypewriter.ttf", A_WinDir "\Fonts\TravelingTypewriter.ttf"] {
                if FileExist(path) && DllCall("gdi32\AddFontResourceExW", "Str", path, "UInt", 0x10, "Ptr", 0, "Int") {
                    loadedLocalFont := true
                    break
                }
            }
        }
        if loadedLocalFont
            return Settings.NoteFont
    }
    ; Detect the original font; use a readily available monospace fallback.
    for key in ["HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts", "HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"] {
        Loop Reg, key, "V" {
            if InStr(A_LoopRegName, Settings.NoteFont)
                return Settings.NoteFont
        }
    }
    return "Consolas"
}

UrlEncode(text) {
    bytes := Buffer(StrPut(text, "UTF-8"))
    length := StrPut(text, bytes, "UTF-8")-1
    result := ""
    Loop length {
        c := NumGet(bytes, A_Index-1, "UChar")
        result .= (c >= 65 && c <= 90 || c >= 97 && c <= 122 || c >= 48 && c <= 57 || InStr("-._~", Chr(c))) ? Chr(c) : Format("%{:02X}", c)
    }
    return result
}

SearchURL(query) {
    query := Trim(query)
    if RegExMatch(query, "i)^([a-z])\s+(.+)$", &match) && SearchEngines.Has(StrLower(match[1]))
        return SearchEngines[StrLower(match[1])] UrlEncode(match[2])
    return "https://www.google.com/search?q=" UrlEncode(query)
}

OpenTarget(target) {
    try Run(target)
    catch as err
        MsgBox("Could not open:`n" target "`n`n" err.Message, "SplashUI")
}

SelfTest() {
    Assert(UrlEncode("æ ø å & + 日本") = "%C3%A6%20%C3%B8%20%C3%A5%20%26%20%2B%20%E6%97%A5%E6%9C%AC", "UTF-8 encoding")
    Assert(SearchURL("o blå") = SearchEngines["o"] "bl%C3%A5", "prefix search")
    Assert(SearchURL("x hello") = "https://www.google.com/search?q=x%20hello", "unknown prefix")
    App.TestMode := true
    App.Menu("Test", Commands)
    App.Input.Value := "notepad"
    App.Filter()
    Assert(App.Matches.Length = 1, "menu filtering")
    App.Input.Value := "no-such-entry-9834"
    App.Filter()
    Assert(App.Matches.Length = 0, "empty results")
    App.Menu("Lectio", LectioLinks)
    App.Search()
    App.Note(false)
    App.Note(true)
    ; Exercise disk persistence in an isolated folder, never the user's draft.
    originalDir := Settings.DataDir
    testDir := A_Temp "\SplashUI-test-" A_TickCount
    try {
        Settings.DataDir := testDir
        App.TestMode := false
        App.Input.Value := "Draft æøå`nsecond line"
        Assert(App.SaveDraft(), "save draft")
        Assert(FileRead(testDir "\draft.txt", "UTF-8") = App.Input.Value, "draft round trip")
        App.Close()
    } finally {
        App.TestMode := true
        Settings.DataDir := originalDir
        if FileExist(testDir "\draft.txt")
            FileDelete(testDir "\draft.txt")
        if DirExist(testDir)
            DirDelete(testDir)
    }
    App.Close()
    FileAppend("PASS: encoding, search routing, menu filtering, all panel constructors, draft round trip.`n", "*")
}

Assert(condition, label) {
    if !condition
        throw Error("Self-test failed: " label)
}
