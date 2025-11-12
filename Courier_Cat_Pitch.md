# 🐾 Courier Cat
**Genre:** Cozy action-platformer / time-attack  
**Engine:** LÖVE (Love2D)  
**Art Style:** Pixel art (16×16 or 32×32 tiles) with sunset palettes and parallax skylines  
**Tone:** Playful, atmospheric, and slightly melancholic — *like a dream at dawn*

---

## 🎬 Elevator Pitch
Deliver letters across a sleeping city as **Courier Cat**, a nimble feline racing rooftops before sunrise.  
Balance **speed, precision, and flow** as you bound between buildings, slide under laundry lines, and chase the horizon.  
Every night, the world changes — rooftops shift, obstacles move, and you must adapt to reach every window before dawn.

*“One cat, one bag of letters, one night before the world forgets.”*

---

## 🕹️ Core Gameplay Loop
1. **Start at your rooftop perch** with a mailbag full of glowing envelopes.  
2. **Run, jump, and dash** across a looping pixel skyline.  
3. **Deliver letters** by landing near lit windows or ringing bells.  
4. **Beat the dawn clock** — each delivery adds precious seconds before sunrise.  
5. **Earn rank upgrades** (“Rooftop Rookie,” “Twilight Courier,” “Master of Meow”).  
6. **Repeat nightly** — layouts shift slightly, difficulty scales gently, and letters reveal fragments of the city’s hidden story.

---

## 🧩 Core Mechanics

| Mechanic | Description |
|-----------|--------------|
| **Movement** | Run, jump, wall-slide, dash. Tight, forgiving platforming. |
| **Deliveries** | Press `Down` or `E` near glowing windows to deliver letters. |
| **Timer** | Sunrise countdown. Deliveries extend time slightly. |
| **Scoring** | Combo meter for consecutive deliveries without touching ground. |
| **Power-ups** | Coffee (speed boost), Balloon (extra jump), Lantern (slows dawn). |
| **Hazards** | Open vents, laundry lines, pigeons, falling antennas. |

---

## 🌇 Setting & Art Direction

**Setting:**  
A dreamlike pixel city — somewhere between 1930s rooftops and a Miyazaki skyscape. Every building silhouette feels familiar but not quite real. The skyline glows in gradients of purple, orange, and pink, with soft clouds scrolling slowly in parallax.

**Visual Style:**
- **Pixel density:** 16×16 sprites, 320×180 base resolution.  
- **Palette:** 12–16 colors, emphasizing warm/cool contrast between night and sunrise.  
- **Animation:** Minimal but expressive — tail flicks, letter bag bounce, window glows.  
- **UI:** Clean, diegetic — the timer is a glowing moon shrinking toward horizon.

**Inspirations:**  
- *Celeste* (movement feel)  
- *Night in the Woods* (tone)  
- *Katana Zero* (lighting aesthetic)  
- *Kiki’s Delivery Service* (theme)

---

## 🎵 Audio Direction
- **Music:** Lo-fi chill beats + ambient jazz. Each track starts calm and slowly picks up tempo as dawn nears.  
- **SFX:**  
  - Footsteps on tiles and metal vents (soft clinks).  
  - Letter “flutter” when delivered.  
  - Distant city hum.  
  - A short piano chord on perfect delivery streaks.  
- **Optional stretch:** adaptive music layer that syncs to your combo streaks.

---

## 💌 Narrative Layer

Each night’s deliveries include fragments of short letters. Some are mundane, others cryptic:

> “You never look up, but I still see your light.”  
> “Tonight the wind smells like rain and regret.”  
> “Tell the gulls I said goodbye.”

Letters hint at **a quiet story about connection and memory** — optional but rewarding to piece together.

Players may eventually realize that Courier Cat isn’t just delivering mail… but carrying messages between forgotten dreamers.

---

## 🔧 Technical Vision (LÖVE Implementation)

| System | Details |
|---------|----------|
| **Engine** | LÖVE (Lua) — single-screen or scrolling 2D. |
| **Libraries** | `bump.lua` (collisions), `anim8` (animation), `sti` (tilemaps from Tiled), `hump.camera`. |
| **Resolution** | Fixed 320×180 virtual res, scaled up (nearest filter). |
| **Controls** | Arrow keys or WASD (run, jump, dash, deliver). |
| **Physics** | Basic gravity, friction, wall detection. |
| **Levels** | JSON or Tiled `.tmx` maps. Each night randomizes tile variants and delivery spots. |
| **Scoring & UI** | Lua table for combo, timer, letters delivered. Drawn via `love.graphics.print` with bitmap font. |
| **Replayability** | Procedural shuffling of rooftops and window locations; day/night color palette swap. |

---

## 🐈‍⬛ Production Scope

| Feature Tier | Scope | Estimated Time |
|---------------|--------|----------------|
| **Prototype (MVP)** | 1 level, running/jumping/dashing, 5 windows to deliver to, simple timer | ~1 week |
| **Vertical Slice** | 3 levels, delivery scoring, background parallax, music loop | ~2–3 weeks |
| **Full Release (Small Indie)** | 10+ night variations, letter story fragments, polish | 1–2 months part-time |

---

## 🌟 Stretch Ideas
- **Photo Mode:** Press `P` to capture “postcards” from your runs.  
- **Weather Variants:** Rain, fog, fireworks, full moon nights.  
- **Co-op Mode:** One player controls Cat; other guides with map hints (Signal & Runner-style).  
- **Endless “Dawn Mode”:** Procedurally generated cityscape with gradual lighting change.  
- **Speedrun Stats:** Seeded maps and replays.

---

## 🎯 Design Pillars
1. **Flow, not friction.** Make movement feel intuitive and joyful.  
2. **Beauty in brevity.** Keep sessions short (5–8 minutes), with replayability.  
3. **Emotion through atmosphere.** No dialogue — the world tells its story visually.  
4. **Expressive simplicity.** Small sprites, big feelings.

---

## 🧭 Why LÖVE is a perfect fit
- Lightweight, immediate 2D rendering for crisp pixel art.  
- Easy to prototype movement and parallax with minimal boilerplate.  
- Lua scripting encourages iteration and “playful tweaking.”  
- Ideal for distributing tiny `.love` builds for quick playtesting.  
- Works offline — you can gift your daughter her own Courier Cat build without installers.
