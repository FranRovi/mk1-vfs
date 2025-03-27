# Mock Data Structure

## User: public
```
├── Documents/
│   ├── Work/
│   │   ├── report_2024.pdf           [type: pdf, size: 1MB, status: final] {tags: work, final}
│   │   ├── meeting_notes.txt         [type: text, size: 2KB, status: draft] {tags: draft}
│   │   └── presentation.pptx         [type: powerpoint, size: 5MB, status: final] {tags: final}
│   ├── Personal/
│   │   ├── budget_2024.xlsx          [type: excel, size: 100KB, status: draft] {tags: personal, draft}
│   │   └── recipes.docx              [type: word, size: 50KB, status: final] {tags: final}
│   └── Archive/
├── Pictures/
└── Projects/
    ├── Frontend/
    │   ├── index.html                [type: html, size: 4KB, status: final] {tags: final}
    │   ├── styles.css                [type: css, size: 2KB, status: draft] {tags: draft}
    │   └── app.js                    [type: javascript, size: 8KB, status: draft] {tags: draft}
    ├── Backend/
    │   ├── server.py                 [type: python, size: 16KB, status: final] {tags: important, final}
    │   └── database.sql              [type: sql, size: 32KB, status: draft] {tags: draft}
    └── Documentation/
```

## User: user456
```
├── Downloads/
└── Music/
    ├── song.mp3                      [type: audio, size: 4MB, artist: Test Artist] {tags: music}
    └── playlist.m3u                  [type: playlist, size: 1KB] {tags: music}
```

Available Tags:
- public: work, personal, important, archived, draft, final
- user456: music, downloads