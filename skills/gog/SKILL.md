---
name: gog
description: Google Workspace CLI for Gmail, Calendar, Drive, Contacts, Sheets, and Docs.
homepage: https://gogcli.sh
metadata:
  {
    "openclaw":
      {
        "emoji": "🎮",
        "requires": { "bins": ["gog"] },
        "install":
          [
            {
              "id": "brew",
              "kind": "brew",
              "formula": "steipete/tap/gogcli",
              "bins": ["gog"],
              "label": "Install gog (brew)",
            },
          ],
      },
  }
---

# gog

Use `gog` for Gmail/Calendar/Drive/Contacts/Sheets/Docs. Requires OAuth setup.

Setup (once)

- `gog auth credentials /path/to/client_secret.json`
- `gog auth add you@gmail.com --services gmail,calendar,drive,contacts,docs,sheets`
- `gog auth list`

Common commands

Gmail

- Gmail search: `gog gmail search 'newer_than:7d' --max 10`
- Gmail messages search (per email, ignores threading): `gog gmail messages search "in:inbox from:ryanair.com" --max 20 --account you@example.com`
- Gmail send (plain): `gog gmail send --to a@b.com --subject "Hi" --body "Hello"`
- Gmail send (multi-line): `gog gmail send --to a@b.com --subject "Hi" --body-file ./message.txt`
- Gmail send (stdin): `gog gmail send --to a@b.com --subject "Hi" --body-file -`
- Gmail send (HTML): `gog gmail send --to a@b.com --subject "Hi" --body-html "<p>Hello</p>"`
- Gmail draft: `gog gmail drafts create --to a@b.com --subject "Hi" --body-file ./message.txt`
- Gmail send draft: `gog gmail drafts send <draftId>`
- Gmail reply: `gog gmail send --to a@b.com --subject "Re: Hi" --body "Reply" --reply-to-message-id <msgId>`

Calendar

- Calendar list events: `gog calendar events <calendarId> --from <iso> --to <iso>`
- Calendar create event: `gog calendar create <calendarId> --summary "Title" --from <iso> --to <iso>`
- Calendar create with color: `gog calendar create <calendarId> --summary "Title" --from <iso> --to <iso> --event-color 7`
- Calendar update event: `gog calendar update <calendarId> <eventId> --summary "New Title" --event-color 4`
- Calendar show colors: `gog calendar colors`

Drive

- Drive list files: `gog drive ls` or `gog drive ls --folder <folderId>`
- Drive search: `gog drive search "query" --max 10`
- Drive create folder: `gog drive mkdir "Folder Name"` or `gog drive mkdir "Folder Name" --parent <folderId>`
- Drive upload file: `gog drive upload ./file.pdf` or `gog drive upload ./file.pdf --parent <folderId>`
- Drive download: `gog drive download <fileId> --out ./local-file`
- Drive move: `gog drive move <fileId> --to <folderId>`
- Drive rename: `gog drive rename <fileId> "New Name"`
- Drive copy: `gog drive copy <fileId> "Copy Name"`
- Drive delete (trash): `gog drive delete <fileId>` or `gog drive delete <fileId> --permanent`
- Drive share: `gog drive share <fileId> --email a@b.com --role writer`
- Drive permissions: `gog drive permissions <fileId>`
- Drive get metadata: `gog drive get <fileId>`
- Drive URL: `gog drive url <fileId>`

Docs (full CRUD)

- Docs create: `gog docs create "My Document"` or `gog docs create "My Document" --parent <folderId>`
- Docs create from markdown: `gog docs create "My Document" --file ./content.md`
- Docs read: `gog docs cat <docId>`
- Docs write (replace all): `gog docs write <docId> "New content"` or `gog docs write <docId> --file ./content.md`
- Docs insert at position: `gog docs insert <docId> "Text to insert" --index 1`
- Docs delete range: `gog docs delete <docId> --start 1 --end 50`
- Docs find and replace: `gog docs find-replace <docId> "old text" "new text"`
- Docs export: `gog docs export <docId> --format txt --out /tmp/doc.txt`
- Docs copy: `gog docs copy <docId> "Copy Title"`
- Docs info: `gog docs info <docId>`
- Docs comments: `gog docs comments list <docId>` / `gog docs comments add <docId> "Comment text"`

Sheets (full CRUD)

- Sheets create: `gog sheets create "My Spreadsheet"`
- Sheets copy: `gog sheets copy <sheetId> "Copy Title"`
- Sheets get: `gog sheets get <sheetId> "Tab!A1:D10" --json`
- Sheets update: `gog sheets update <sheetId> "Tab!A1:B2" --values-json '[["A","B"],["1","2"]]' --input USER_ENTERED`
- Sheets append: `gog sheets append <sheetId> "Tab!A:C" --values-json '[["x","y","z"]]' --insert INSERT_ROWS`
- Sheets clear: `gog sheets clear <sheetId> "Tab!A2:Z"`
- Sheets format: `gog sheets format <sheetId> "Tab!A1:D1" --bold --bg-color "#4285F4"`
- Sheets notes: `gog sheets notes <sheetId> "Tab!A1:D10"`
- Sheets metadata: `gog sheets metadata <sheetId> --json`
- Sheets export: `gog sheets export <sheetId> --format csv --out /tmp/data.csv`

Slides

- Slides create: `gog slides create "My Presentation"`
- Slides create from markdown: `gog slides create-from-markdown "My Deck" --file ./slides.md`
- Slides info: `gog slides info <presentationId>`
- Slides list: `gog slides list-slides <presentationId>`
- Slides add image slide: `gog slides add-slide <presentationId> ./image.png --notes "Speaker notes"`
- Slides read slide: `gog slides read-slide <presentationId> <slideId>`
- Slides update notes: `gog slides update-notes <presentationId> <slideId> --notes "New notes"`
- Slides delete: `gog slides delete-slide <presentationId> <slideId>`
- Slides export: `gog slides export <presentationId> --format pdf --out /tmp/deck.pdf`
- Slides copy: `gog slides copy <presentationId> "Copy Title"`

Contacts

- Contacts: `gog contacts list --max 20`

Calendar Colors

- Use `gog calendar colors` to see all available event colors (IDs 1-11)
- Add colors to events with `--event-color <id>` flag
- Event color IDs (from `gog calendar colors` output):
  - 1: #a4bdfc
  - 2: #7ae7bf
  - 3: #dbadff
  - 4: #ff887c
  - 5: #fbd75b
  - 6: #ffb878
  - 7: #46d6db
  - 8: #e1e1e1
  - 9: #5484ed
  - 10: #51b749
  - 11: #dc2127

Email Formatting

- Prefer plain text. Use `--body-file` for multi-paragraph messages (or `--body-file -` for stdin).
- Same `--body-file` pattern works for drafts and replies.
- `--body` does not unescape `\n`. If you need inline newlines, use a heredoc or `$'Line 1\n\nLine 2'`.
- Use `--body-html` only when you need rich formatting.
- HTML tags: `<p>` for paragraphs, `<br>` for line breaks, `<strong>` for bold, `<em>` for italic, `<a href="url">` for links, `<ul>`/`<li>` for lists.
- Example (plain text via stdin):

  ```bash
  gog gmail send --to recipient@example.com \
    --subject "Meeting Follow-up" \
    --body-file - <<'EOF'
  Hi Name,

  Thanks for meeting today. Next steps:
  - Item one
  - Item two

  Best regards,
  Your Name
  EOF
  ```

- Example (HTML list):
  ```bash
  gog gmail send --to recipient@example.com \
    --subject "Meeting Follow-up" \
    --body-html "<p>Hi Name,</p><p>Thanks for meeting today. Here are the next steps:</p><ul><li>Item one</li><li>Item two</li></ul><p>Best regards,<br>Your Name</p>"
  ```

Notes

- Set `GOG_ACCOUNT=you@gmail.com` to avoid repeating `--account`.
- For scripting, prefer `--json` plus `--no-input`.
- Sheets values can be passed via `--values-json` (recommended) or as inline rows.
- Docs supports full CRUD: create, read (cat), write, insert, delete, find-replace, export, copy, comments.
- Confirm before sending mail or creating events.
- `gog gmail search` returns one row per thread; use `gog gmail messages search` when you need every individual email returned separately.
