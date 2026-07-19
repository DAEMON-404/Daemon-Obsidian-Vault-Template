---
title: "<% tp.file.title.replace(/\"/g, '\\\"') %>"
type: notes
status: active
creation_date: <% tp.date.now("YYYY-MM-DD") %>
cssclasses:
  - editorial
  - note-banner
---

```dataviewjs
await dv.view("00Meta/Views/NoteBanner");
```

<% tp.file.cursor() %>
