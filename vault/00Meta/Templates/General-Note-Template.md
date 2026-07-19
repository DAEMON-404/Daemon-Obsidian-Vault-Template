<%*
// --- TEMPLATER SCRIPT ---
// General Note Template - Rosé Pine Editorial Edition

const noteTitle = await tp.system.prompt("Note Title");
if (!noteTitle) { return; }

const noteType = await tp.system.suggester(
    ["Quick Note", "Research", "Meeting Notes", "Idea", "Tutorial", "Reference"],
    ["Quick Note", "Research", "Meeting Notes", "Idea", "Tutorial", "Reference"],
    false,
    "Select Note Type"
);
if (!noteType) { return; }

// Type colors
const typeColors = {
    "Quick Note": "00FF41",
    "Research": "9B59B6",
    "Meeting Notes": "3498DB",
    "Idea": "F39C12",
    "Tutorial": "1ABC9C",
    "Reference": "E74C3C"
};
const typeColor = typeColors[noteType] || "808080";

// Set the note title
await tp.file.rename(noteTitle.replace(/\s+/g, '-'));
-%>
---
title: "<% noteTitle %>"
note_type: "<% noteType %>"
status: "SEEDLING"
importance: "Medium"
reviewed: false
related_topics: []
projects: []
courses: []
creation_date: <% tp.date.now("YYYY-MM-DD") %>
creation_time: <% tp.date.now("HH:mm") %>
last_modified: <% tp.date.now("YYYY-MM-DD HH:mm") %>
tags:
  - Notes/<% noteType.replace(/\s+/g, '-') %>
  - Status/Active
cssclasses:
  - editorial
  - note-banner
---

```dataviewjs
await dv.view("00Meta/Views/NoteBanner");
```

---

## // NOTE_CLASSIFICATION

![Type](https://img.shields.io/badge/Type-<% noteType.replace(/\s+/g, '%20') %>-<% typeColor %>?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-SEEDLING-00FF41?style=for-the-badge)
![Date](https://img.shields.io/badge/Date-<% tp.date.now("YYYY--MM--DD") %>-cyan?style=for-the-badge)

---

> [!info]+ `> NOTE_MATRIX`
> ```
> ┌──────────────────────────────────────────────────────────┐
> │  TITLE:    <% noteTitle %>                               │
> │  TYPE:     <% noteType %>                                │
> │  CREATED:  <% tp.date.now("YYYY-MM-DD") %> @ <% tp.date.now("HH:mm") %>  │
> │  STATUS:   [■□□□□□□□□□] SEEDLING                         │
> └──────────────────────────────────────────────────────────┘
> ```

---

## // QUICK_SUMMARY

*TL;DR - What is this note about?*


---

## // MAIN_CONTENT

<%* if (noteType === "Quick Note") { %>
### `> KEY_POINTS`

-
-
-

### `> DETAILS`


<%* } else if (noteType === "Research") { %>
### `> RESEARCH_QUESTION`

*What am I trying to find out or understand?*


### `> FINDINGS`

> [!abstract]+ Source 1
> **LINK:**
> **KEY_INFO:**
>

> [!abstract]+ Source 2
> **LINK:**
> **KEY_INFO:**
>

### `> ANALYSIS`


### `> CONCLUSIONS`


<%* } else if (noteType === "Meeting Notes") { %>
### `> MEETING_DETAILS`

```
┌─ MEETING_INFO ────────────────────────────────────────────┐
│                                                           │
│  DATE:       <% tp.date.now("YYYY-MM-DD") %>              │
│  TIME:       <% tp.date.now("HH:mm") %>                   │
│  ATTENDEES:                                               │
│  -                                                        │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

**AGENDA:**
1.
2.
3.

### `> DISCUSSION_POINTS`

> [!info]+ Topic 1
> **DISCUSSION:**
>
> **DECISIONS:**
>

> [!info]+ Topic 2
> **DISCUSSION:**
>
> **DECISIONS:**
>

### `> ACTION_ITEMS`

- [ ] Task 1 - Assigned to: - Due:
- [ ] Task 2 - Assigned to: - Due:
- [ ] Task 3 - Assigned to: - Due:

### `> FOLLOW_UP`


<%* } else if (noteType === "Idea") { %>
### `> THE_IDEA`

*Core concept:*


### `> WHY_IT_MATTERS`


### `> POTENTIAL_APPLICATIONS`

1.
2.
3.

### `> NEXT_STEPS`

- [ ]
- [ ]
- [ ]

### `> RELATED_CONCEPTS`

-
-
<%* } else if (noteType === "Tutorial") { %>
### `> OVERVIEW`

*What does this tutorial cover?*


### `> PREREQUISITES`

-
-

### `> STEP_BY_STEP_GUIDE`

> [!terminal]+ Step 1: [First Step]
> **WHAT_TO_DO:**
>
>
> ```bash
> # Commands here
>
>
> ```
>
> **EXPECTED_OUTCOME:**
>

> [!terminal]+ Step 2: [Second Step]
> **WHAT_TO_DO:**
>
>
> ```bash
> # Commands here
>
>
> ```
>
> **EXPECTED_OUTCOME:**
>

> [!terminal]+ Step 3: [Third Step]
> **WHAT_TO_DO:**
>
>
> ```bash
> # Commands here
>
>
> ```
>
> **EXPECTED_OUTCOME:**
>

### `> TROUBLESHOOTING`

> [!warning]+ Problem 1
> **SYMPTOM:**
> **SOLUTION:**
>

> [!warning]+ Problem 2
> **SYMPTOM:**
> **SOLUTION:**
>

### `> ADDITIONAL_RESOURCES`

-
-
<%* } else if (noteType === "Reference") { %>
### `> REFERENCE_INFO`

**CATEGORY:**

**DESCRIPTION:**


### `> KEY_INFORMATION`

| ATTRIBUTE | VALUE |
|-----------|-------|
|           |       |
|           |       |

### `> DETAILS`


### `> USAGE_EXAMPLES`

> [!example]+ Example 1
> ```bash
> # Code or example here
>
>
> ```

> [!example]+ Example 2
> ```bash
> # Code or example here
>
>
> ```

### `> RELATED_REFERENCES`

- [[Related Note 1]]
- [[Related Note 2]]
<%* } %>

---

## // CONNECTIONS

### `> RELATED_NOTES`

- [[Note 1]]
- [[Note 2]]
- [[Note 3]]

### `> RELATED_PROJECTS`

-
-

### `> EXTERNAL_RESOURCES`

- [Resource 1](URL)
- [Resource 2](URL)

---

## // ADDITIONAL_THOUGHTS

> [!note]+ `> REFLECTIONS`
>

**QUESTIONS_TO_EXPLORE:**
-
-

---

## // ACTION_ITEMS

- [ ]
- [ ]
- [ ]

---

## // ATTACHMENTS

*Link any relevant files, images, or other media*

-
-

---

## // BACKLINKS

```dataview
LIST
FROM [[]] AND !"00Meta"
```

---

```
╔═══════════════════════════════════════════════════════════════════╗
║  LAST_UPDATED: <% tp.date.now("YYYY-MM-DD HH:mm") %>              ║
║  TYPE:         <% noteType %>                                     ║
║  STATUS:       [SEEDLING]                                         ║
╚═══════════════════════════════════════════════════════════════════╝
```
