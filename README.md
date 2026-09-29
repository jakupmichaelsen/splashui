# SplashUI v2

A standalone AutoHotkey v2 recreation of the original splash helpers. Run **SplashUI.ahk** with AutoHotkey v2. Exit the old hotkey script first to avoid competing bindings. The tray menu provides configuration, reload, resume draft, and exit.

| Shortcut | Action |
| --- | --- |
| Alt+F1 | Filterable app / URL launcher |
| F1 | Web search |
| Shift+F1 | Search selected text, or open a selected HTTP(S) URL |
| Ctrl+Alt+F11 | Fullscreen note, initially populated from clipboard |
| Shift+Alt+F11 | Small, initially empty note |
| Win+F10 | Lectio URL menu |

Menus: type to filter, use Up/Down, then Enter; double-click also opens an entry. Escape cancels. Searches use your default browser. Prefix a query with `d ` (Dictionary), `t ` (Thesaurus), `o ` (Ordnet), `s ` (Sprotin), `n ` (Ngram), or `m ` (Maps directions). Unknown prefixes remain ordinary Google searches. Unicode and punctuation are URL-encoded. Shift+F1 preserves the clipboard; Caps Lock enables “define” searches, as in the original. With no selection, it opens the search panel after a one-second timeout.

Notes: Enter inserts a newline; Ctrl+Enter saves the draft, copies the text, and closes. Escape/Alt+F4 saves and closes without changing your clipboard. Switching panels also saves a note. Drafts are saved after a short typing pause in `%APPDATA%\SplashUI-v2\draft.txt`; the previous on-disk draft is backed up once per script run to `previous-draft.txt`. Use **Resume saved note** in the tray menu to recover it. The full and small editors share one draft. These are local plain-text files, not a notes archive.

## Appearance and monitors

The brown `221A0F`, beige `D3AF86`, orange `FF9900`, borderless panels, left-edge menus, and typewriter editor come from the original helpers. `Traveling _Typewriter` is used when installed; otherwise the editor uses Consolas. The original shared INI was absent, so other typography and transparency defaults are reconstructed. Notes are opaque for readability; menus and search are slightly translucent.

Panels open on the monitor containing the centre of the active window. Set `Settings.Monitor` to `"mouse"` or a monitor number to change this. Menus and search respect that monitor's work area; fullscreen notes cover that monitor only, including its taskbar. Negative monitor coordinates are supported. Geometry uses monitor API coordinates with automatic AHK control scaling disabled and explicit system-DPI sizing. Mixed-DPI displays still need visual testing on your setup; this version does not dynamically relayout an open panel when display settings change. Close and reopen it after changing the display layout.

## Personalisation

Edit **config.ahk**, then choose **Reload** in the tray menu. `Commands` and `LectioLinks` contain labels and targets. Starter commands are examples; your missing personal command and Lectio lists have not been reconstructed. Add actual school/teacher/class URLs before using those entries.

```autohotkey
{Label: "My app", Target: '"C:\Program Files\My App\app.exe" --option'}
{Label: "My folder", Target: "C:\Users\YourName\Documents"}
{Label: "My website", Target: "https://example.com/"}
```

No startup registration is added. To start it with Windows, place a shortcut to this script in your Startup folder after trying it.

## Validation

Run `AutoHotkey64.exe /ErrorStdOut SplashUI.ahk --self-test` to check UTF-8 encoding, search routing, menu filtering, hidden construction of every panel, and a draft write/read in an isolated temporary folder. `--smoke-test` registers the hotkeys/tray menu and exits immediately. Neither test launches apps or visits URLs.

Implementation references: [official v2 GUI documentation](https://www.autohotkey.com/docs/v2/lib/Gui.htm) and [monitor APIs](https://www.autohotkey.com/docs/v2/lib/Monitor.htm).
