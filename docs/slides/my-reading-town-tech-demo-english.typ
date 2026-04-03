#import "@preview/minimal-presentation:0.7.0": *

#let pink = rgb("#FFB3BA")
#let lavender = rgb("#B5B3FF")
#let mint = rgb("#B3FFD9")
#let cream = rgb("#FFF8F0")
#let darkText = rgb("#4A4A4A")
#let darkPink = rgb("#E8637A")
#let darkLavender = rgb("#7B79E8")
#let darkMint = rgb("#2E9E6B")
#let peach = rgb("#FFDFC4")

#let cbox(fill: cream, body) = block(
  width: 100%,
  fill: fill,
  inset: 11pt,
  radius: 6pt,
  body,
)

#let tag(body, fill: darkPink) = box(
  fill: fill,
  inset: (x: 8pt, y: 4pt),
  radius: 20pt,
  text(fill: white, size: 12pt, weight: "semibold", body),
)

#show: project.with(
  title: "My Reading Town",
  sub-title: "Technical Demo: Flutter mobile development,\narchitecture, stack, and how it all works",
  author: "Fernando Pinto Villarroel",
  date: "2026",
  index-title: "Contents",
  logo: image("./images/logo.png"),
  logo-light: image("./images/logo.png"),
  cover: image("./images/logo.png"),
  main-color: darkPink,
  lang: "en",
)

// The package hardcodes dy: -4cm, placing titles at 0 cm from the page top edge.
// This override shifts them down to 0.7 cm so they are not cut.
#show heading.where(level: 2): it => {
  section-page.update(_ => false)
  pagebreak()
  place(
    top + left,
    dy: -3.3cm,
    block(
      height: 3.3cm,
      width: 100% - 3cm,
      align(horizon, text(size: 38pt, weight: "regular", it.body)),
    ),
  )
}

// ─── WHAT IS MY READING TOWN? ────────────────────────────────────────────────

= What is My Reading Town?

== What is My Reading Town?

#columns-content()[
  A *mobile app* that turns reading into a village-building game.

  #v(8pt)
  - Log pages read from any book
  - Earn resources: coins, gems, wood, metal
  - Spend them to construct buildings and grow a village
  - Villagers move in as the village expands
  - Missions, minigames, and a guided tour for new players

  #v(10pt)
  #cbox(fill: darkPink)[
    #set text(fill: white, size: 13pt)
    *Goal:* make reading a daily, rewarding habit through game mechanics, not a chore.
  ]
][
  #align(center, image("./images/screenshot-village-game-closeup.jpeg", height: 11cm, fit: "contain"))
]

// ─── MOBILE DEVELOPMENT FUNDAMENTALS ────────────────────────────────────────

= Mobile Development Fundamentals

== Three kinds of software: three mental models

#grid(
  columns: (1fr, 1fr, 1fr),
  gutter: 12pt,
  cbox(fill: cream)[
    #text(fill: darkPink, size: 15pt, weight: "bold")[Backend API]
    #v(5pt)
    #set text(size: 13pt)
    Runs on a *server*. No UI. Receives HTTP requests, processes data, returns JSON or HTML.

    Users never see this directly.

    #v(4pt)
    #text(fill: luma(130), size: 12pt)[Node.js, Django, Spring, Go…]
  ],
  cbox(fill: cream)[
    #text(fill: darkLavender, size: 15pt, weight: "bold")[Web App]
    #v(5pt)
    #set text(size: 13pt)
    Runs *inside a browser*. HTML + CSS + JS render the UI. The browser is the host environment.

    Must be fetched from a server each visit.

    #v(4pt)
    #text(fill: luma(130), size: 12pt)[React, Vue, Angular, plain HTML…]
  ],
  cbox(fill: pink)[
    #text(fill: darkPink, size: 15pt, weight: "bold")[Mobile App ← us]
    #v(5pt)
    #set text(size: 13pt)
    Runs *natively on device*. Installed once. Has direct access to hardware: camera, GPS, storage, notifications.

    No browser. The OS is the host.

    #v(4pt)
    #text(fill: luma(80), size: 12pt)[Flutter, React Native, Swift, Kotlin…]
  ],
)

#v(10pt)
#cbox(fill: lavender)[
  #set text(size: 13pt)
  *My Reading Town* is a mobile app: it runs offline, persists data on-device, and renders a real-time game. No server, no browser, just Flutter on your phone.
]

== Web app vs mobile app: concrete differences

#table(
  columns: (auto, 1fr, 1fr),
  inset: (x: 9pt, y: 8pt),
  stroke: luma(220),
  fill: (_, row) => if row == 0 { pink } else if calc.odd(row) { cream } else { white },
  table.header(
    [],
    align(center)[*Web App*],
    align(center)[*Mobile App (Flutter)*],
  ),
  [*Distribution*],
  [URL, browser renders it],
  [Installed package (.apk / .ipa), runs from device storage],
  [*Rendering*],
  [Browser engine (Blink, WebKit) paints DOM / CSS],
  [Flutter's own rendering canvas (no browser dependency)],
  [*Offline*],
  [Partial, needs service workers and extra setup],
  [First-class, app works with zero connectivity],
  [*Hardware*],
  [Limited, sandboxed by browser security model],
  [Full access: camera, file system, notifications, sensors],

  [*Updates*],
  [Instant, users always get latest when opening URL],
  [Must push a new release through App Store / Play Store],
)

// ─── FLUTTER & DART ──────────────────────────────────────────────────────────

= Flutter & Dart

== Flutter: one codebase, any device

#columns-content()[
  Flutter is Google's open-source UI toolkit. Write code *once* in Dart, compile to native for Android, iOS, Web, and Desktop.

  #v(10pt)
  *How is that possible?*

  Flutter ships its own *rendering engine*. It does not rely on each platform's native UI components, it draws every pixel itself, directly to the GPU canvas.

  #v(8pt)
  #cbox(fill: pink)[
    #set text(size: 13pt)
    *No browser. No bridge layer.*
    Flutter compiles to native ARM machine code. Performance is comparable to apps written natively in Swift (iOS) or Kotlin (Android).
  ]
][
  #v(4pt)
  #cbox(fill: darkText)[
    #set text(fill: white, size: 13pt, weight: "bold")
    #set align(center)
    Everything in Flutter is a Widget
  ]
  #v(6pt)
  #cbox(fill: luma(240))[
    #set text(size: 12pt)
    #set align(center)
    #text(weight: "bold")[App Screen]
  ]
  #v(2pt)
  #pad(left: 12pt)[
    #cbox(fill: lavender)[
      #set text(size: 12pt)
      #set align(center)
      #text(weight: "bold")[Scaffold] (page structure)
    ]
    #v(2pt)
    #pad(left: 12pt)[
      #grid(columns: (1fr, 1fr), gutter: 4pt,
        cbox(fill: pink)[#set text(size: 11pt); #set align(center); AppBar\nnavigation],
        cbox(fill: mint)[#set text(size: 11pt); #set align(center); Body\ncontent area],
      )
      #v(2pt)
      #pad(left: 12pt)[
        #grid(columns: (1fr, 1fr), gutter: 4pt,
          cbox(fill: peach)[#set text(size: 10pt); #set align(center); Village Map\n(Flame canvas)],
          cbox(fill: lavender)[#set text(size: 10pt); #set align(center); HUD Overlay\n(buttons, bars)],
        )
      ]
    ]
  ]
  #v(4pt)
  #cbox(fill: cream)[
    #set text(size: 11pt)
    #set align(center)
    Only the subtrees that changed are repainted, not the whole screen.
  ]
]

== Dart: the language behind Flutter

#columns-content()[
  Dart is Google's strongly-typed, object-oriented language, designed for client-side apps.

  #v(8pt)
  - *Statically typed*: errors caught at compile time, not runtime
  - *Null safety*: the compiler prevents null-pointer crashes by design
  - *Async-first*: concurrency built into the language itself
  - *Single-threaded with isolates*: no shared-memory race conditions
][
  #grid(rows: (1fr, 1fr), gutter: 8pt,
    grid(columns: (1fr, 1fr), gutter: 8pt,
      cbox(fill: pink)[
        #set text(size: 12pt)
        #text(weight: "bold", fill: darkPink)[Type System]
        #v(4pt)
        Every value has a declared type. Mistakes are caught before the app runs, not when a user taps a button.
      ],
      cbox(fill: lavender)[
        #set text(size: 12pt)
        #text(weight: "bold", fill: darkLavender)[Null Safety]
        #v(4pt)
        Variables cannot be null unless explicitly allowed. Eliminates an entire class of crashes.
      ],
    ),
    grid(columns: (1fr, 1fr), gutter: 8pt,
      cbox(fill: mint)[
        #set text(size: 12pt)
        #text(weight: "bold", fill: darkMint)[Async / Await]
        #v(4pt)
        Loading from disk or network never freezes the UI, async operations are a first-class language feature.
      ],
      cbox(fill: peach)[
        #set text(size: 12pt)
        #text(weight: "bold", fill: darkPink)[Familiar Syntax]
        #v(4pt)
        Classes, interfaces, generics, lambdas, the same constructs you already know from Java or C\#.
      ],
    ),
  )
]

// ─── TECHNOLOGY STACK ────────────────────────────────────────────────────────

= Technology Stack

== Full tech stack at a glance

#grid(
  columns: (1fr, 1fr, 1fr, 1fr),
  gutter: 10pt,
  cbox(fill: darkPink)[
    #set text(fill: white, size: 13pt)
    #text(weight: "bold", size: 14pt)[UI & Framework]
    #v(4pt)
    Flutter 3.5+\
    Dart language\
    Material Design widgets\
    Custom kawaii-pastel theme
  ],
  cbox(fill: darkLavender)[
    #set text(fill: white, size: 13pt)
    #text(weight: "bold", size: 14pt)[Game Engine]
    #v(4pt)
    Flame 1.21\
    2D isometric grid\
    Sprite components\
    Camera & input system
  ],
  cbox(fill: darkMint)[
    #set text(fill: white, size: 13pt)
    #text(weight: "bold", size: 14pt)[Data & State]
    #v(4pt)
    sqflite (SQLite)\
    13 tables, local DB\
    Provider (state mgmt)\
    GetIt (DI container)
  ],
  cbox(fill: darkText)[
    #set text(fill: white, size: 13pt)
    #text(weight: "bold", size: 14pt)[Platform APIs]
    #v(4pt)
    Push notifications\
    Camera & gallery\
    OS share sheet\
    File system access
  ],
)

#v(10pt)
#cbox(fill: cream)[
  #set text(size: 13pt)
  #grid(
    columns: (1fr, 1fr, 1fr),
    gutter: 10pt,
    [*Localization:* 5 translation files (EN, ES, FR, IT, PT)],
    [*Networking:* fetches book metadata from Open Library API],
    [*Extras:* confetti animations · gallery export · backup & restore],
  )
]

== Clean Architecture in Flutter

#columns-content()[
  #set text(size: 12pt)
  The codebase is split into *four layers*. Each layer has one responsibility. The key rule: *dependencies only point inward*, outer layers know about inner ones, never the reverse.

  #v(6pt)
  #cbox(fill: mint)[
    #set text(size: 11pt)
    *Why this matters:* the database can be swapped for cloud storage, or the state library replaced, without touching any business logic. The innermost layer has zero framework imports.
  ]

  #v(6pt)
  #set text(size: 11pt)
  This is the same "ports and adapters" pattern used in well-structured backend services, the same principles apply equally well on mobile.
][
  #cbox(fill: darkText)[
    #set text(fill: white, size: 11pt, weight: "bold")
    #set align(center)
    Infrastructure (Flutter UI + Database)
    #set text(weight: "regular", size: 9pt)
    \screens, widgets, game canvas, SQLite helper
  ]
  #align(center, text(fill: darkPink, size: 13pt)[↓ depends on])
  #cbox(fill: lavender)[
    #set text(size: 11pt, weight: "bold")
    #set align(center)
    Adapters (Providers & Repositories)
    #set text(weight: "regular", size: 9pt)
    \connects Flutter state to business services
  ]
  #align(center, text(fill: darkPink, size: 13pt)[↓ depends on])
  #cbox(fill: mint)[
    #set text(size: 11pt, weight: "bold")
    #set align(center)
    Application (Services)
    #set text(weight: "regular", size: 9pt)
    \ReadingService, BuildingService, MissionService…
  ]
  #align(center, text(fill: darkPink, size: 13pt)[↓ depends on])
  #cbox(fill: pink)[
    #set text(size: 11pt, weight: "bold")
    #set align(center)
    Domain (Entities + Rules)
    #set text(weight: "regular", size: 9pt)
    \Book, Villager, Building, pure Dart, no Flutter
  ]
]

// ─── CORE GAME LOOP ──────────────────────────────────────────────────────────

= Core Game Loop

== Core game loop: how reading becomes gameplay

#grid(
  columns: (1fr, auto, 1fr, auto, 1fr, auto, 1fr),
  gutter: 6pt,
  cbox(fill: darkPink)[
    #set text(fill: white, size: 12pt)
    #set align(center)
    *1. Log reading*
    #v(3pt)
    Open a book, enter pages read and time spent
  ],
  align(center + horizon)[
    #text(fill: darkPink, size: 20pt, weight: "bold")[→]
  ],
  cbox(fill: darkLavender)[
    #set text(fill: white, size: 12pt)
    #set align(center)
    *2. Earn resources*
    #v(3pt)
    The app calculates coins, gems, wood, and metal
  ],
  align(center + horizon)[
    #text(fill: darkPink, size: 20pt, weight: "bold")[→]
  ],
  cbox(fill: darkMint)[
    #set text(fill: white, size: 12pt)
    #set align(center)
    *3. Build village*
    #v(3pt)
    Spend resources to place buildings on the map
  ],
  align(center + horizon)[
    #text(fill: darkPink, size: 20pt, weight: "bold")[→]
  ],
  cbox(fill: darkText)[
    #set text(fill: white, size: 12pt)
    #set align(center)
    *4. Villagers arrive*
    #v(3pt)
    Residents move in; happiness rises with more buildings
  ],
)

#v(10pt)
#grid(
  columns: (1fr, 1fr, 1fr),
  gutter: 10pt,
  cbox(fill: cream)[
    #set text(size: 13pt)
    *Resource formula*\
    3 coins per page read\
    20 gems on book completion\
    Wood & metal from sessions\
    50 coins + 20 gems finish bonus
  ],
  cbox(fill: cream)[
    #set text(size: 13pt)
    *Construction queue*\
    Buildings take real time to complete. A powerup item speeds up construction. Progress is saved across app restarts.
  ],
  cbox(fill: cream)[
    #set text(size: 13pt)
    *Missions & XP*\
    Completing milestones (build 3 houses, read 500 pages…) awards XP. Missions branch into construction, villager, and reading tracks.
  ],
)

// ─── Q&A ─────────────────────────────────────────────────────────────────────

= Q&A

== Thank you

#cbox(fill: pink)[
  #set align(center)
  #set text(size: 16pt)
  *My Reading Town: tech summary*
  #v(8pt)
  Flutter 3.5 + Dart · Flame 2D engine · SQLite (sqflite)\
  Provider state management · GetIt DI · Clean Architecture\
  5-language i18n · Offline-first · Android & iOS

  #v(10pt)
  #text(size: 14pt, weight: "light")[
    Open source · Built for the love of reading and game design\
    Fernando Pinto Villarroel
  ]
]
