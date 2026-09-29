; Personalise this file, then use Reload from the tray menu.
Settings := {
    Background: "221A0F", Text: "D3AF86", Accent: "FF9900",
    Font: "Segoe UI", NoteFont: "Traveling _Typewriter",
    FontSize: 14, NoteSize: 18, Opacity: 240,
    Monitor: "active", ; "active" window, "mouse", or a monitor number
    DataDir: A_AppData "\SplashUI-v2"
}

; Targets can be URLs, executable names, quoted paths with arguments, or folders.
Commands := [
    {Label: "Notepad", Target: "notepad.exe"},
    {Label: "Calculator", Target: "calc.exe"},
    {Label: "File Explorer", Target: "explorer.exe"},
    {Label: "Google", Target: "https://www.google.com/"},
    {Label: "Gmail", Target: "https://mail.google.com/"},
    {Label: "Google Keep", Target: "https://keep.google.com/"},
    {Label: "Workflowy", Target: "https://workflowy.com/"}
]

; Add your own school/teacher/class IDs here. These are ordinary URL entries.
LectioLinks := [
    {Label: "Lectio", Target: "https://www.lectio.dk/"}
    ; , {Label: "My timetable", Target: "https://www.lectio.dk/lectio/SCHOOL/SkemaNy.aspx?type=laerer&laererid=ID"}
]

; The query is UTF-8 URL-encoded and appended to the selected prefix.
SearchEngines := Map(
    "d", "https://www.dictionary.com/browse/",
    "t", "https://www.thesaurus.com/browse/",
    "o", "https://ordnet.dk/ddo/ordbog?query=",
    "s", "https://sprotin.fo/?p=dictionaries&_SearchDescription=1&_DictionaryPage=1&_DictionaryId=1&_SearchFor=",
    "n", "https://books.google.com/ngrams/graph?year_start=1800&year_end=2000&content=",
    "m", "https://www.google.com/maps/dir/?api=1&destination="
)
