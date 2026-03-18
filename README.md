# 📚 Read-to-Play Village

_A mobile game that turns reading into a dopamine-driven village builder_

---

# Table of Contents

1. [Origin of the Idea](#origin-of-the-idea)
2. [Concept Overview](#concept-overview)
3. [Vision and Objectives](#vision-and-objectives)
4. [Core Gameplay Loop](#core-gameplay-loop)
5. [Game Design Concept](#game-design-concept)
6. [Technology Evaluation and Selection](#technology-evaluation-and-selection)
7. [Art and Asset Creation Strategy](#art-and-asset-creation-strategy)
8. [Example AI Prompt for Character Creation](#example-ai-prompt-for-character-creation)
9. [Functional Requirements](#functional-requirements)
10. [Non-Functional Requirements](#non-functional-requirements)
11. [Data Model (Conceptual)](#data-model-conceptual)
12. [Architecture Overview](#architecture-overview)
13. [Competition Analysis](#competition-analysis)
14. [SWOT Analysis (FODA)](#swot-analysis-foda)
15. [Open Questions for Stakeholders](#open-questions-for-stakeholders)
16. [Roadmap for a Solo Developer](#roadmap-for-a-solo-developer)
17. [Risks and Considerations](#risks-and-considerations)
18. [Conclusion](#conclusion)

---

# Origin of the Idea

_(Original description preserved exactly as requested)_

> quiero crear un videojuego que produzca los mismos picos de dopamina por registrar que leiste paginas de un libro. soy un aidcto a clash royale y su sistema dopaminico de recompensas y adrenalina. Quiero poder dejarlo progresivamente y reemplazarlo por el habito de leer, pero intnetar reemplazar la dopamina facil de un videojuego adictivo, de scrollear en redes sociales, o ver pornografía es complicadisimo, porque esas adicciones están creadas y pensadas cuidadosamente para mantenerte atrapado a ellas por los picos de dopamina y satisfacción que te generan. Quiero lograr algo asi con un videojuego pero enfocado en leer! para que personas con adicciones a redes sociales, videojuegos como clash royale o ver porno, pudan progresivamente reemplazar sus adicciones por el buen habito de leer (algo que los jovenes ya no hacen). debe ser un videojuego mobile, estético, llamativo y pensado para ser igual de dopaminico que las otras adicciones pero enfocado en lectura: por ejemplo, un juego como clash of clans pero de lecturA: por cada pagina de libro que registras que has leido, sse te dan recursos para armar una ciudad/aldea, ademas de monedas y gemas, mientras mas paginas lees, mas casas y edificios puedes construir para que tus aldeanitos (tu eliges que pueden ser humanos, gatitos, perritos, conejos, etc) tengan una mejor calidad vida (ademas de casas normales, edificios, centrales de servicios basicos (electricidad, agua, luz), piscinas, parques, cines, etc.) porque sino sufren y se quejan. debe ser un juego con estetica 2d paleta de colores pastel y kawaii. y cuando registrar que terminaste el libro que estabas leyendo actualmente se te dan mas gemas y recursos, y luego empiezas a registrar nuevas paginas leidas para otro libro. asi puede usarse la aplicacion durante largo tiempo leyendo cada dia y registrando como se lee para mejorar tu ciudadcita. no debe ser una app que requiera de internet para usar (no debe tener dependencias externas cloud), debe usar sqlite y ser mobile-native (android).

---

# Concept Overview

The product is a **mobile idle village-building game powered by real-world reading progress**.

Users read books in real life and log pages read inside the game.

Reading progress generates in-game resources used to build and improve a village inhabited by cute characters.

Core idea:

```

real world reading
↓
log pages read
↓
receive rewards
↓
build village
↓
improve villager happiness
↓
read more

```

The design aims to replicate **dopamine reward loops found in mobile games** but redirect them toward reading habits.

---

# Vision and Objectives

### Vision

Create a **mobile experience that replaces addictive digital habits with reading**, using the same psychological reward mechanisms as modern mobile games.

### Objectives

- Encourage daily reading
- Provide satisfying game progression
- Create an emotionally rewarding world
- Build long-term habit loops

---

# Core Gameplay Loop

```

Read real pages
↓
Register pages
↓
Earn coins, gems, chests
↓
Build village
↓
Villagers become happier
↓
Unlock buildings
↓
Read more

```

This loop mimics dopamine feedback patterns found in modern mobile games.

---

# Game Design Concept

### Village Builder

Players build a small town populated by villagers such as:

- cats
- dogs
- rabbits
- humans

### Buildings

Examples:

- houses
- parks
- pools
- cinemas
- water plants
- power plants
- hospitals
- schools

### Happiness System

Villagers require:

- housing
- electricity
- water
- entertainment

If services are missing, villagers complain.

---

# Technology Evaluation and Selection

The project must satisfy:

- solo developer
- Linux development
- mobile native
- offline-first
- SQLite storage
- 2D game

---

## Flutter + Flame

Pros:

- excellent UI
- strong mobile ecosystem
- Dart language
- integrates game + app logic
- easy SQLite support

Cons:

- smaller game ecosystem
- fewer tutorials

Good for:

```

hybrid game + productivity app

```

---

## React Native + Expo

Pros:

- developer already familiar
- fast development
- large ecosystem

Cons:

- not designed for games
- performance limitations
- difficult animation pipelines

---

## Unity

Pros:

- industry standard
- massive asset store
- powerful engine
- optimized mobile builds

Cons:

- heavier environment
- learning curve
- C# required

---

## Recommended Stack

```

Flutter

- Flame Engine
- SQLite (Drift)

```

Reasons:

- strong mobile UI
- easy local storage
- ideal for hybrid app/game

---

# Art and Asset Creation Strategy

The developer is not a graphic designer.

Strategy:

Use **AI-assisted asset generation**.

Tools:

- Gemini Nano / Gemini image models
- AI sprite generators
- Aseprite for editing
- pixel art editors

Workflow:

```

AI generation
↓
sprite cleanup
↓
game integration

```

Art style:

- kawaii
- pastel palette
- chubby characters
- simple shapes
- minimal facial features

---

# Example AI Prompt for Character Creation

Prompt optimized for Gemini:

```

cute kawaii cat villager character sprite

front view character
standing upright on two legs
full body visible
looking directly forward

adorable chubby kitty
round chubby body
short little legs
small paws
very simple design
minimal details

kawaii style
pastel color palette
soft pastel colors
clean simple outlines
simple shapes

face with very simple eyes (small black dot eyes)
tiny cute mouth
super cute chubby proportions

2D mobile game sprite
top-down idle game village builder style
high readability at small size

white background
simple and adorable character design

NOT lying down
NOT sitting
NOT side view

```

---

# Functional Requirements

### Reading System

Users must be able to:

- add books
- track total pages
- log reading sessions
- update progress

---

### Reward System

Rewards include:

- coins
- gems
- chests

Rewards scale with pages read.

---

### City Builder

Users can:

- place buildings
- upgrade buildings
- decorate village

---

### Villager System

Villagers:

- occupy homes
- require services
- have happiness metrics

---

### Book Completion

Completing a book provides:

- large gem reward
- rare items
- unlockables

---

# Non-Functional Requirements

### Offline First

The application must function fully offline.

### Performance

- smooth animations
- low memory footprint
- optimized mobile rendering

### Persistence

Local database using SQLite.

### Platform

Android native build.

### UX

- satisfying animations
- instant reward feedback
- readable UI

---

# Data Model (Conceptual)

### Books

```

books
id
title
total_pages
pages_read
created_at

```

---

### Reading Sessions

```

reading_sessions
id
book_id
pages_read
date

```

---

### Resources

```

coins
gems

```

---

### Buildings

```

id
type
level
position_x
position_y

```

---

### Villagers

```

id
species
happiness
home_id

```

---

# Architecture Overview

Suggested structure:

```

presentation
game_engine
application
domain
data

```

State management:

```

Riverpod

```

Persistence:

```

SQLite

```

---

# Competition Analysis

No direct competitor exists with the same concept.

However, several products overlap partially.

---

## Habit Gamification

Habit tracking games such as **Habitica** gamify real-world tasks through RPG mechanics.

---

## Reading Trackers

Apps such as **Bookly** and **StoryGraph** track reading progress and statistics.

---

## Focus Gamification

Apps like **Forest** gamify focus sessions by growing virtual trees.

---

### Market Gap

No existing product combines:

```

reading tracking

- village builder gameplay
- cute idle game mechanics

```

This represents a potential niche.

---

# SWOT Analysis (FODA)

### Strengths

- Unique concept
- Educational impact
- Solo-dev feasible
- Strong emotional appeal

---

### Weaknesses

- Difficult to verify reading honesty
- Requires consistent art style
- Solo development limitations

---

### Opportunities

- Rising interest in habit gamification
- Educational technology market
- AI-assisted development

---

### Threats

- Large companies could replicate
- Users may fake progress
- engagement may drop without strong gameplay

---

# Open Questions for Stakeholders

Reading mechanics:

- Should reading be manually logged or timed?
- Can users read multiple books simultaneously?

Rewards:

- How many coins per page?
- Should rewards be random?

Gameplay:

- Should buildings require construction time?
- Should villagers have individual behaviors?

Verification:

- How to discourage fake reading logs?

Future:

- Should the app include social features?

---

# Roadmap for a Solo Developer

### Phase 1 (MVP)

- reading tracker
- basic rewards
- simple village map
- building placement

---

### Phase 2

- villager happiness
- chest rewards
- animations

---

### Phase 3

- skins
- decorations
- expanded buildings

---

# Risks and Considerations

Key risks:

- verifying reading honesty
- art consistency
- maintaining long-term engagement

Mitigation:

- streak systems
- achievements
- progression unlocks

---

# Conclusion

This project combines **habit formation psychology with mobile game design** to promote reading behavior.

By leveraging dopamine-driven mechanics typically used in addictive mobile games, the system aims to redirect those behavioral loops toward a positive real-world habit: reading.

The concept is technically achievable by a single developer using modern tools, AI-assisted asset generation, and a carefully scoped MVP.

This document serves as the **single source of truth describing the origin, design, and strategy of the idea**.
