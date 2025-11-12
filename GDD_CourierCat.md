# Courier Cat - Game Design Document (GDD)

**Version:** 1.0
**Last Updated:** November 11, 2025
**Game Title:** Courier Cat
**Genre:** Cozy Action-Platformer / Time-Attack
**Platform:** PC (Windows, macOS, Linux)
**Target Audience:** Fans of precision platformers, cozy games, and atmospheric experiences
**Development Engine:** LÖVE (Love2D)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Design Pillars](#2-design-pillars)
3. [Core Gameplay Loop](#3-core-gameplay-loop)
4. [Player Character & Controls](#4-player-character--controls)
5. [Movement System](#5-movement-system)
6. [Delivery System](#6-delivery-system)
7. [Scoring & Progression](#7-scoring--progression)
8. [Timer & Pacing](#8-timer--pacing)
9. [Level Design](#9-level-design)
10. [Power-ups & Hazards](#10-power-ups--hazards)
11. [UI/UX Design](#11-uiux-design)
12. [Audio Design](#12-audio-design)
13. [Narrative Design](#13-narrative-design)
14. [Art Direction](#14-art-direction)
15. [Difficulty & Balancing](#15-difficulty--balancing)
16. [Replayability](#16-replayability)
17. [Accessibility](#17-accessibility)
18. [Stretch Goals](#18-stretch-goals)

---

## 1. Executive Summary

**Courier Cat** is a cozy action-platformer where players control a nimble cat delivering letters across a dreamy pixel-art cityscape before sunrise. The game combines precision platforming with time-attack urgency, wrapped in an atmospheric package that emphasizes **flow, beauty, and emotional resonance**.

**Core Experience:**
Players experience the meditative joy of movement mastery while racing against a gentle but persistent timer. Each delivery extends time, creating a rhythm of risk and reward. The game is designed for short sessions (5-8 minutes) with high replayability through procedural variations and skill mastery.

**Unique Selling Points:**
- **Flow-focused movement** that feels intuitive yet rewards mastery
- **Diegetic UI** with moon timer and minimal HUD
- **Atmospheric storytelling** through environmental design and letter fragments
- **Cozy time-attack** that balances relaxation with challenge
- **Procedural variations** that keep each night fresh

---

## 2. Design Pillars

### Pillar 1: Flow, Not Friction
**Philosophy:** Movement should feel intuitive from the first jump and joyful through the hundredth run.

**Implementation:**
- Forgiving collision boxes (player hitbox slightly smaller than sprite)
- Generous jump buffering (6-8 frames)
- Coyote time for edge jumps (4-6 frames)
- Responsive controls with minimal input lag
- Smooth acceleration/deceleration curves
- Clear visual feedback for all actions

**Success Metrics:**
- New players complete first delivery within 60 seconds
- Players describe movement as "satisfying" in playtests
- Less than 5% of deaths feel "unfair" in player surveys

### Pillar 2: Beauty in Brevity
**Philosophy:** Keep sessions short with high replayability.

**Implementation:**
- 5-8 minute target session length
- Quick restart after failure (< 2 seconds)
- Clear beginning, middle, and end to each run
- Meaningful progression that respects player time
- No grinding or padding

**Success Metrics:**
- Average session length: 5-8 minutes
- Players complete 3+ runs per gameplay session
- Minimal drop-off between runs

### Pillar 3: Emotion Through Atmosphere
**Philosophy:** Tell stories visually without dialogue, letting the world speak.

**Implementation:**
- Environmental storytelling through level design
- Letter fragments that hint at larger narratives
- Lighting and color palette that evoke emotion
- Audio that reinforces mood
- Subtle animations that give life to the world

**Success Metrics:**
- Players report emotional engagement with setting
- Letter fragments collected at high rates (>60%)
- Players notice environmental details in playtests

### Pillar 4: Expressive Simplicity
**Philosophy:** Small sprites, big feelings.

**Implementation:**
- Limited color palette (12-16 colors)
- 16×16 sprite size
- Minimal but expressive animations
- Clean, readable visual design
- Every pixel has purpose

**Success Metrics:**
- Visual style described as "cohesive" and "charming"
- Player character recognizable at a glance
- UI elements instantly readable

---

## 3. Core Gameplay Loop

### Session Structure

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Start at Rooftop Perch (Home Base)                      │
│    - Mailbag full of glowing envelopes                      │
│    - Moon timer begins countdown                            │
│    - Player can see first few delivery points               │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Navigate Rooftop City                                    │
│    - Run, jump, dash across buildings                       │
│    - Avoid hazards (vents, laundry lines, pigeons)          │
│    - Collect power-ups (coffee, balloons, lanterns)         │
│    - Build combo meter for consecutive deliveries           │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Deliver Letters                                          │
│    - Approach lit windows/delivery points                   │
│    - Press deliver button (Down/E)                          │
│    - Watch letter flutter away                              │
│    - Gain time extension (+5-15 seconds based on combo)     │
│    - Read brief letter fragment (optional)                  │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Race Against Dawn                                        │
│    - Moon shrinks toward horizon                            │
│    - Skyline gradually lightens                             │
│    - Music tempo increases                                  │
│    - Urgency builds naturally                               │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Session End                                              │
│    SUCCESS: Delivered all letters before dawn               │
│    - Earn rank based on time/combo/letters                  │
│    - Unlock new letter fragments                            │
│    - Update high score                                      │
│                                                              │
│    FAILURE: Dawn arrives with letters remaining             │
│    - Show deliveries completed                              │
│    - Offer quick restart                                    │
│    - No harsh penalties                                     │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 6. Night Transitions                                        │
│    - Layout shifts slightly                                 │
│    - Delivery points randomize                              │
│    - Difficulty scales gently                               │
│    - New letter fragments available                         │
└─────────────────────────────────────────────────────────────┘
```

### Minute-by-Minute Experience

**Minutes 0-1: Getting Oriented**
- Player learns basic movement
- First 1-2 deliveries are easy, forgiving
- Tutorial elements (if first playthrough)
- Music is calm, skyline is deep purple

**Minutes 1-3: Building Rhythm**
- Player finds their flow
- Combos start forming
- Deliveries spread further apart
- Power-ups introduce variety
- Music picks up tempo

**Minutes 3-5: Tension Rises**
- Timer pressure becomes noticeable
- Skyline begins lightening to orange
- Delivery points in trickier locations
- Player must choose optimal routes
- Music reaches peak tempo

**Minutes 5-8: Climax & Resolution**
- Final deliveries are challenging
- Time is tight but achievable
- Skyline glows pink/orange
- Music is urgent but beautiful
- Success feels earned

---

## 4. Player Character & Controls

### Courier Cat - Character Design

**Visual Design:**
- Small cat sprite (16×16 pixels, occupies ~10×14 actual hitbox)
- Large expressive eyes
- Prominent tail (used for animation feedback)
- Mail bag on back that bounces with movement
- Simple two-frame walk cycle, four-frame run cycle

**Personality Through Animation:**
- Tail swishes during idle
- Ears perk up when near delivery point
- Slight crouch before dash
- Letter bag bounces during jump
- Landing has small squash/stretch
- Wall-slide shows paws against wall

**Character Traits (Conveyed Through Gameplay):**
- Nimble and precise
- Dedicated to their job
- Curious (examines delivery points)
- Playful (tail animations, movement fluidity)
- Gentle (soft landing sounds, careful deliveries)

### Control Scheme

**Keyboard Controls (Default):**
- **Arrow Keys / WASD:** Movement (left/right run)
- **Space / W / Up Arrow:** Jump
- **Shift / X / Z:** Dash
- **Down / S / E:** Deliver letter (when near delivery point)
- **P:** Pause menu
- **R:** Quick restart (when paused or failed)
- **Escape:** Return to menu

**Gamepad Controls:**
- **Left Stick / D-Pad:** Movement
- **A / B:** Jump
- **X / RB:** Dash
- **Down + A / Y:** Deliver
- **Start:** Pause
- **Select:** Quick restart

**Control Philosophy:**
- All actions accessible with one hand on keyboard
- No complex button combinations
- Instant responsiveness
- Actions can be queued (jump + dash + deliver)
- Controls feel the same at all frame rates

---

## 5. Movement System

### Movement States

The player character exists in one of several states that determine available actions:

```
GROUNDED → can run, jump, dash, deliver
  ↓ jump
AIRBORNE → can dash (once), wall-slide (when touching wall)
  ↓ touch wall
WALL_SLIDING → can wall-jump, release to fall
  ↓ wall-jump
AIRBORNE → ...
  ↓ dash
DASHING → brief invulnerable movement
  ↓ complete
AIRBORNE/GROUNDED → ...
```

### Running

**Specifications:**
- **Base speed:** 120 pixels/second
- **Acceleration:** Instant (or 0.1s to max speed for slight weight)
- **Deceleration:** 0.15s when releasing input
- **Turn-around:** Instant direction change
- **Max speed with coffee:** 180 pixels/second

**Feel:**
- Responsive and tight
- Character feels light but controlled
- No sliding or slipping unless on ice hazard

**Visual Feedback:**
- Four-frame run animation at 12 FPS
- Small dust puffs every 4th step
- Tail trails behind during direction changes

### Jumping

**Specifications:**
- **Jump height:** 48 pixels (3 tiles high)
- **Jump duration:** 0.4 seconds to apex
- **Gravity:** 800 pixels/second²
- **Jump buffer:** 8 frames (0.13s)
- **Coyote time:** 5 frames (0.083s)
- **Variable jump:** Release jump button early for shorter jump (60% height)

**Jump Types:**

1. **Ground Jump**
   - Standard jump from ground or platform
   - Full height control

2. **Wall Jump**
   - Performed from wall-slide state
   - Launches away from wall at 45° angle
   - Grants brief moment of directional control suspension
   - Slightly higher than ground jump (52 pixels)

3. **Buffered Jump**
   - Player can press jump up to 8 frames before landing
   - Jump executes on first frame of landing
   - Allows maintaining speed without timing precision

4. **Coyote Jump**
   - Player can jump for 5 frames after leaving platform
   - Prevents frustration from near-edge jumps

**Feel:**
- Snappy and responsive
- Clear apex
- Fast fall after apex for tighter control
- Maintains horizontal momentum

**Visual Feedback:**
- Jump squat (1 frame)
- Ears perk up
- Tail arcs during ascent
- Small dust puff on launch
- Squash/stretch on landing

**Audio Feedback:**
- Soft "poff" sound on jump
- Gentle landing "tap"
- Different pitch for wall-jump

### Dashing

**Specifications:**
- **Dash distance:** 60 pixels
- **Dash duration:** 0.2 seconds
- **Dash speed:** 300 pixels/second
- **Cooldown:** 0.5 seconds after landing/touching wall
- **Air dashes:** 1 per jump
- **Dash directions:** 8-directional (cardinal + diagonal)

**Dash Mechanics:**

1. **Ground Dash**
   - Horizontal only (left/right)
   - Doesn't consume air dash
   - Can dash repeatedly with cooldown
   - Low to ground, can go under obstacles

2. **Air Dash**
   - 8 directional control
   - Consumed until landing/touching wall
   - Brief moment (0.1s) of gravity suspension
   - Can be used to recover from falls

3. **Dash Canceling**
   - Can jump out of dash
   - Can wall-slide out of dash
   - Can deliver during dash (risky but stylish)

**Invulnerability:**
- Dashing grants brief i-frames (first 0.1s)
- Can dash through certain hazards (laundry lines, pigeons)
- Cannot dash through solid walls or vents

**Feel:**
- Instant startup (no windup)
- Strong sense of momentum
- Slight slowdown at end for control
- Empowering, not overpowered

**Visual Feedback:**
- Motion blur trail
- Slight crouch before dash
- Tail extends straight back
- Screen shake (subtle) on dash start
- Distinct sprite/animation during dash

**Audio Feedback:**
- Sharp "whoosh" sound
- Different pitch for air vs ground dash

### Wall-Sliding

**Specifications:**
- **Slide speed:** 40 pixels/second (slow fall)
- **Activation:** Automatic when touching wall while in air
- **Direction change:** Can slide on either wall side
- **Duration:** Unlimited while holding toward wall
- **Release:** Let go of directional input to fall normally

**Mechanics:**
- Restores air dash when initiated
- Can be released and re-grabbed on same wall
- Cannot slide on certain surfaces (glass, ice)
- Wall-jump launches away from wall

**Feel:**
- Safe, controlled descent
- Moment to plan next move
- Slightly sticky (0.1s buffer before falling)

**Visual Feedback:**
- Paws pressed against wall
- Slight sliding animation
- Small particle trail down wall
- Ears back (concentrating)

**Audio Feedback:**
- Soft scraping sound
- Changes based on wall material (metal vs brick)

### Advanced Movement Techniques

**Dash-Jump Combo:**
- Dash → Jump immediately preserves dash momentum
- Allows longer jumps
- Core to speedrunning

**Wall-Kick Chain:**
- Jump between parallel walls repeatedly
- Each wall-jump restores air dash
- Used for vertical climbing sections

**Delivery Boost:**
- Delivering while moving grants brief speed boost
- Combo multiplier increases boost duration
- Stylish way to maintain flow

---

## 6. Delivery System

### Delivery Mechanics

**Delivery Zones:**
- Indicated by glowing windows (radius of 32 pixels)
- Glow pulses gently (0.8s cycle)
- Becomes brighter when player is near (< 48 pixels)
- Shows "↓" or "E" prompt when in range

**Delivery Process:**

1. **Approach**
   - Player enters delivery zone (32px radius)
   - Prompt appears
   - Window glow intensifies
   - Soft chime plays

2. **Action**
   - Player presses deliver button
   - Brief animation (0.3s):
     - Cat reaches into bag
     - Letter floats out
     - Letter glows and flutters toward window
     - Window flickers with light
   - Player maintains control during animation

3. **Completion**
   - Letter absorbed by window
   - Sparkle effect
   - Time extension applied
   - Score added
   - Combo incremented
   - Brief letter text appears (optional reading)

**Delivery Rules:**
- Can deliver while in any movement state (grounded, airborne, dashing)
- Cannot deliver same window twice
- Delivery zones don't block movement
- Failed delivery (miss button press) has no penalty

### Delivery Progression

**Early Game (Nights 1-3):**
- 5-7 delivery points
- Close together (< 100 pixels apart)
- Easy to reach, forgiving positioning
- Basic rooftop layouts

**Mid Game (Nights 4-7):**
- 8-12 delivery points
- Moderate spread (100-200 pixels)
- Some require wall-jumps or dashes
- Introduced verticality

**Late Game (Nights 8-10):**
- 12-15 delivery points
- Wide spread (200+ pixels)
- Complex routing required
- Optimal paths involve advanced techniques
- Multiple "correct" routes

**Endless Mode:**
- Procedurally placed delivery points
- Scaling difficulty
- No fixed endpoint

### Special Delivery Types

**Priority Mail (Red Glow):**
- Urgent deliveries
- Give 2x time extension
- Add 2x score
- Limited time to complete (30 seconds)
- Appear in mid-late game

**Fragile Delivery (Blue Glow):**
- Cannot dash within 64 pixels
- Cannot take damage before delivery
- Give 1.5x time and score
- Contain special letter fragments

**Chain Deliveries (Yellow Glow):**
- Appear in sets of 2-3
- Must be completed in sequence
- Each in chain gives escalating bonuses
- Chain broken if too much time passes (10s)

---

## 7. Scoring & Progression

### Score Components

**Base Score:**
- Each delivery: 100 points
- Time bonus: (remaining seconds × 10)
- Completion bonus: 500 points

**Combo System:**

```
Combo Multiplier = floor(consecutive_deliveries / 2) + 1
Max Multiplier = 5x

Examples:
1 delivery = 1x (100 pts)
2-3 deliveries = 2x (200 pts each)
4-5 deliveries = 3x (300 pts each)
6-7 deliveries = 4x (400 pts each)
8+ deliveries = 5x (500 pts each)
```

**Combo Rules:**
- Combo increments with each delivery
- Combo resets when touching ground (encourages air deliveries)
- Combo maintained during dashes
- Wall-slides don't break combo

**Trick Bonuses:**
- Dash delivery: +50 points
- Air delivery: +25 points
- Wall-slide delivery: +75 points
- No-ground complete: +1000 points
- Perfect run (no damage): +500 points

### Rank System

Ranks earned based on end-of-night score:

| Rank | Score Required | Title | Unlock |
|------|----------------|-------|--------|
| E | < 1000 | Sleepy Kitten | — |
| D | 1000-2999 | Rooftop Rookie | Night 2 |
| C | 3000-4999 | Twilight Courier | Night 3 |
| B | 5000-6999 | Moonlight Runner | Coffee power-up |
| A | 7000-8999 | Dawn Chaser | Balloon power-up |
| S | 9000-11999 | Master of Meow | Lantern power-up |
| S+ | 12000+ | Legendary Whisker | Endless Mode |

**Rank Benefits:**
- Higher ranks unlock new nights
- Ranks unlock power-ups
- S+ unlocks endless mode
- Ranks displayed on level select
- Personal best tracked per night

### Progression System

**Night Unlocking:**
- Night 1: Always available
- Nights 2-10: Unlock by completing previous night (any rank)
- Endless Mode: Unlock with S+ on any night

**Letter Fragment Collection:**
- 30 unique letter fragments
- Earned by completing deliveries
- Each delivery has a chance to grant new fragment
- Higher combos increase fragment drop rate
- Reading all 30 unlocks "True Ending" letter

**Cosmetic Unlocks (Stretch Goal):**
- Alternate cat colors
- Different mail bag designs
- Skyline palette swaps
- Earned through challenges

---

## 8. Timer & Pacing

### Dawn Timer

**Visual Representation:**
- Moon icon in top center of screen
- Moon shrinks toward horizon line
- Background skyline gradually lightens
- Parallax cloud speed increases

**Time Mechanics:**

**Base Timer:**
- Night 1: 180 seconds (3 minutes)
- Night 2-3: 210 seconds (3.5 minutes)
- Night 4-6: 240 seconds (4 minutes)
- Night 7-10: 270 seconds (4.5 minutes)

**Time Extensions:**

| Event | Time Added |
|-------|------------|
| Standard delivery | +8 seconds |
| Combo 2x delivery | +10 seconds |
| Combo 3x delivery | +12 seconds |
| Combo 4x delivery | +14 seconds |
| Combo 5x delivery | +16 seconds |
| Priority mail | +20 seconds |
| Lantern power-up | +30 seconds |

**Time Pressure States:**

1. **Calm (> 90s remaining)**
   - Deep purple/blue skyline
   - Slow music tempo
   - Moon is large
   - No time pressure feedback

2. **Warning (90-45s remaining)**
   - Skyline shifts to purple/orange
   - Music tempo increases slightly
   - Moon is medium size
   - Subtle timer pulse every 10s

3. **Urgent (45-15s remaining)**
   - Orange/pink skyline
   - Music at peak tempo
   - Moon is small
   - Timer pulses every 5s
   - Screen edges have faint orange glow

4. **Critical (< 15s remaining)**
   - Bright orange/yellow skyline
   - Intense music
   - Moon is tiny
   - Timer pulses every second
   - Screen edges glow bright orange
   - Dramatic audio cues

**Failure State:**
- Timer reaches zero
- Screen fades to white (sunrise)
- Gentle failure music
- Shows stats: deliveries completed, score, rank
- "Quick Restart" button prominently displayed
- No harsh penalties

**Success State:**
- All deliveries completed
- Moon freezes, sparkles
- Triumphant musical flourish
- Screen fades to warm sunrise
- Victory stats display
- Letter fragment reward

---

## 9. Level Design

### Level Philosophy

Levels are designed as **looping rooftop paths** with multiple valid routes. Players should feel empowered to find their own optimal path while guided toward deliveries.

### Level Structure

**Spatial Layout:**
```
        [Delivery 3]
             │
    [Start Perch] ─── [Delivery 1]
         │                  │
    [Delivery 2]       [Power-up]
         │                  │
    [Delivery 4] ───── [Delivery 5]
         │
    [Delivery 6] ── [Final Delivery]
```

**Vertical Layering:**
- Low level (ground): Safe but slow
- Mid level (2-3 buildings high): Optimal flow path
- High level (4+ buildings high): Risky shortcuts

### Tile Types & Platform Categories

**Solid Platforms:**
- Standard rooftop (16×16 tiles, flat surface)
- Brick walls (climbable via wall-slide)
- Metal vents (not climbable)
- Slanted roofs (45° slopes)

**Semi-Solid Platforms:**
- Awnings (can drop through)
- Laundry lines (thin platforms)
- Fire escapes (one-way platforms)

**Background Elements (No Collision):**
- Windows
- Chimneys (visual only)
- Distant buildings
- Stars/clouds

### Level Design Patterns

**Pattern 1: The Gauntlet**
- Linear sequence of jumps
- Tests timing and precision
- Used for tutorial sections

**Pattern 2: The Split**
- Two paths converge later
- One safer, one faster
- Teaches risk/reward

**Pattern 3: The Climb**
- Vertical wall-jump section
- Optional, leads to power-up or shortcut
- Rewards advanced movement

**Pattern 4: The Gap**
- Large horizontal gap
- Requires dash-jump or specific timing
- Signature moment in each level

**Pattern 5: The Rooftop Run**
- Long straight section
- Focus on speed and flow
- Placement of rhythm-based obstacles

### Procedural Variations

**Night-to-Night Changes:**
- Delivery point locations shuffle (within valid zones)
- Hazard placement varies
- Power-up locations randomize
- Minor tile variations (chimney positions, etc.)

**What Stays Consistent:**
- Core platform layout
- Overall path structure
- Major landmarks
- Skill requirements

**Difficulty Scaling:**
- Early nights: Wide platforms, short gaps
- Mid nights: Narrower platforms, longer gaps, more hazards
- Late nights: Precise jumps, tight timing, environmental obstacles

### Sample Level Breakdown - Night 1

**Theme:** "First Flight"
**Deliveries:** 5
**Estimated Time:** 2-3 minutes (generous)
**Focus:** Teaching basic movement

**Layout:**
1. **Start Perch** (top-left)
   - Safe elevated platform
   - Clear view of first delivery

2. **Delivery 1** - "The Neighbor"
   - 2 platforms away (easy jump × 2)
   - Teaches basic jumping

3. **Delivery 2** - "The Drop"
   - Below current position
   - Teaches dropping through platforms

4. **Delivery 3** - "The Climb"
   - Requires wall-jump to reach
   - Introduces wall-slide

5. **Delivery 4** - "The Gap"
   - Longer jump, requires run-up
   - Teaches momentum

6. **Delivery 5** - "The Dash"
   - Coffee power-up provided before
   - Requires dash to reach
   - Victory!

---

## 10. Power-ups & Hazards

### Power-ups

**1. Coffee (Speed Boost)**

**Appearance:**
- Steaming coffee cup sprite
- Small wisp of steam animation
- Warm brown/cream colors

**Mechanics:**
- Increases run speed by 50% (120 → 180 px/s)
- Duration: 15 seconds
- Stacks with combo bonuses
- Timer shown as small coffee cup icon in UI

**Spawn Logic:**
- 1-2 per level
- Placed before long horizontal sections
- Always on main path (never hidden)

**Strategy:**
- Use for difficult deliveries
- Save for final rush
- Enables risky shortcuts

---

**2. Balloon (Extra Jump)**

**Appearance:**
- Small red balloon tied to platform
- Bobs gently up/down
- Pops when collected

**Mechanics:**
- Grants one additional mid-air jump
- Can be used after normal jump
- Can be used after air dash
- Persists until used (doesn't expire)
- Shows balloon icon near player

**Spawn Logic:**
- 0-1 per level
- Placed before vertical sections
- Often in optional areas

**Strategy:**
- Allows reaching high deliveries
- Enables no-ground combos
- Can save from failed jumps

---

**3. Lantern (Slow Dawn)**

**Appearance:**
- Glowing paper lantern
- Soft yellow/orange light
- Gentle sway animation

**Mechanics:**
- Freezes dawn timer for 10 seconds
- Grants +30 seconds when effect ends
- Clear visual: clock icon with pause symbol
- Rare (only 1 per level in late game)

**Spawn Logic:**
- Night 5+
- Hidden in challenging locations
- Optional but valuable

**Strategy:**
- Emergency time recovery
- Enables full exploration
- Rewards risky detours

---

### Hazards

**1. Open Vents (Steam Hazard)**

**Appearance:**
- Metal grate with rising steam
- Steam puffs every 2 seconds
- Red warning glow before puff

**Mechanics:**
- Telegraph: 0.5s red glow before steam
- Active: 1.0s steam puff
- Cooldown: 1.5s
- Effect: Pushes player upward (150 px/s)
- Can dash through during i-frames

**Placement:**
- Horizontal surfaces
- Forces timing challenge
- Can be avoided with proper routing

**Damage:** No damage, but disrupts movement

---

**2. Laundry Lines (Low Obstacles)**

**Appearance:**
- Clothesline strung between buildings
- Shirts/sheets hanging
- Gentle sway in wind

**Mechanics:**
- Height: 24 pixels above platform
- Must duck (automatic while dashing)
- Can jump over
- Effect: Slows player if hit (0.5s stun)

**Placement:**
- Across gaps
- Above narrow platforms
- Can dash under

**Damage:** Movement disruption

---

**3. Pigeons (Moving Hazards)**

**Appearance:**
- Plump gray/white pigeon
- Idle or flying animation
- Coos softly

**Mechanics:**
- Roosting: Stationary, takes up platform space
- Flying: Patrols set path at 60 px/s
- Effect: Bumps player backward (no damage)
- Can be dashed through
- Scatters when dashed near (visual polish)

**Placement:**
- Narrow platforms
- Flight paths across gaps
- Predictable patterns

**Damage:** Knockback, combo breaker

---

**4. Falling Antennas (Environmental Hazard)**

**Appearance:**
- Old TV antenna on rooftop
- Wobbly when player is near
- Metal/rusty texture

**Mechanics:**
- Trigger: Player within 32 pixels
- Telegraph: Wobble for 0.5s
- Fall: Drops straight down at 200 px/s
- Effect: Knocks player down if hit
- Respawns after 10s

**Placement:**
- Above key paths
- Creates dynamic obstacles
- Teaches awareness

**Damage:** Knockdown, combo breaker

---

**5. Glass Skylights (Fragile Platforms)**

**Appearance:**
- Glass panels flush with rooftop
- Slightly transparent
- Subtle shine

**Mechanics:**
- First step: Glass cracks (visual + sound)
- 0.5s delay, then shatters
- Player falls through
- Cannot wall-slide on glass walls
- Respawns after 15s

**Placement:**
- Optional paths
- Risk/reward shortcuts
- Forces quick movement

**Damage:** Fall hazard, time loss

---

### Hazard Philosophy

- **Telegraph clearly**: All hazards have visual/audio warnings
- **Consistent timing**: Hazard patterns are learnable
- **No instant death**: All hazards disrupt movement, not kill
- **Multiple solutions**: Hazards can be avoided, dashed through, or jumped over
- **Fair placement**: Never placed right after blind jumps

---

## 11. UI/UX Design

### Diegetic UI Philosophy

UI elements exist "in the world" rather than as overlays. This preserves immersion and reinforces the cozy, atmospheric tone.

### HUD Elements

**1. Dawn Timer (Moon)**

**Position:** Top-center of screen
**Design:**
- Large full moon at start
- Gradually shrinks toward horizon line
- Horizon line is fixed visual reference
- Moon glows brighter as it shrinks (urgency)

**Behavior:**
- Smooth size transition (no jumps)
- Pulses when delivering (brief pause + grow)
- Changes color: White → Yellow → Orange
- Final 10s: Flashing animation

**Alternative Mode (Accessibility):**
- Option for digital timer "MM:SS" below moon
- Can toggle in settings

---

**2. Combo Meter**

**Position:** Below player character (follows player)
**Design:**
- Small glowing number when combo ≥ 2
- "×2", "×3", "×4", "×5"
- Color-coded:
  - ×2: Yellow
  - ×3: Orange
  - ×4: Red
  - ×5: Purple with sparkles

**Behavior:**
- Fades in when combo starts
- Grows larger with each increase
- Pulses when incremented
- Fades out when broken
- Optional: Shows "Combo Broken!" briefly

---

**3. Mailbag Counter**

**Position:** On player's back (mail bag)
**Design:**
- Mail bag glows when full
- Visibly empties as deliveries made
- Number of envelopes visible (stylized)
- Doesn't show exact number, just "full/half/empty"

**Behavior:**
- Subtle bounce animation
- Glows brighter near delivery points
- Sparkles when collecting letters

---

**4. Score Display**

**Position:** Top-right corner
**Design:**
- Minimalist number display
- Only shows during/after deliveries
- Fades after 2 seconds
- Shows score gained: "+500 (×3)"

**Behavior:**
- Appears on delivery
- Number ticks up (not instant)
- Color matches combo color
- Final score shown on end screen

---

**5. Power-up Indicators**

**Position:** Small icons near player
**Design:**
- Coffee cup icon (when speed boosted)
- Balloon icon (when extra jump available)
- Lantern icon (when time frozen)
- 16×16 pixel icons
- Floating slightly above player

**Behavior:**
- Fade in when collected
- Pulse when active
- Countdown ring around icon (for timed effects)
- Fade out when expired

---

### Menus

**Main Menu:**

```
╔════════════════════════════════════╗
║                                    ║
║         🐾 COURIER CAT 🐾         ║
║                                    ║
║         [ Start Night ]            ║
║         [ Letter Archive ]         ║
║         [ Options ]                ║
║         [ Exit ]                   ║
║                                    ║
║   Background: Parallax cityscape   ║
║   Music: Main theme (calm)         ║
╚════════════════════════════════════╝
```

**Night Select Screen:**

```
╔════════════════════════════════════╗
║    Night 1   Night 2   Night 3     ║
║      [S]      [A]     [Lock]       ║
║    5 letters  8 letters  —         ║
║    Best: 8500  Best: 7200  —       ║
║                                    ║
║    Night 4   Night 5   Night 6     ║
║     [B]      [C]      [Lock]       ║
║                                    ║
║  [ Endless Mode ] (Locked)         ║
╚════════════════════════════════════╝
```

**Pause Menu:**

```
╔════════════════════════════════════╗
║            PAUSED                  ║
║                                    ║
║         [ Resume ]                 ║
║         [ Restart ]                ║
║         [ Options ]                ║
║         [ Quit to Menu ]           ║
║                                    ║
║   Background: Game screen (dimmed) ║
╚════════════════════════════════════╝
```

**End Screen (Success):**

```
╔════════════════════════════════════╗
║      Dawn arrives safely 🌅        ║
║                                    ║
║   Letters Delivered: 12/12         ║
║   Time Remaining: 42s              ║
║   Combo Peak: ×5                   ║
║   Final Score: 11,250              ║
║                                    ║
║   Rank: S (Master of Meow)         ║
║                                    ║
║   [ Continue ] [ Restart ]         ║
║                                    ║
║   Letter Fragment Unlocked!        ║
╚════════════════════════════════════╝
```

---

### Accessibility Options

**Visual:**
- High-contrast mode
- Colorblind-friendly palettes
- Digital timer option
- UI scale options (1x, 2x, 3x)
- Screen shake toggle

**Audio:**
- Master volume
- Music volume
- SFX volume
- Dialogue/text read-aloud (stretch)

**Controls:**
- Full button remapping
- Toggle vs hold for dash
- Jump buffer size adjustment
- Auto-deliver option (near window)

**Gameplay:**
- Extended timer mode (+50% time)
- Reduced hazards mode
- Practice mode (infinite time)
- Invincibility toggle

---

## 12. Audio Design

### Music System

**Adaptive Music Architecture:**

The game uses a layered music system that responds to gameplay state:

**Layer Structure:**
1. **Base Layer** - Ambient pad, gentle melody
2. **Rhythm Layer** - Lo-fi beats
3. **Harmony Layer** - Jazz chords, piano flourishes
4. **Tension Layer** - Strings, urgency

**State-Based Mixing:**

| Game State | Active Layers | Tempo | Notes |
|------------|---------------|-------|-------|
| Calm (>90s) | Base + Rhythm | 80 BPM | Relaxed |
| Warning (90-45s) | Base + Rhythm + Harmony | 95 BPM | Building |
| Urgent (45-15s) | All layers | 110 BPM | Intense |
| Critical (<15s) | All layers + flourishes | 120 BPM | Peak |

**Combo-Driven Music:**
- Each delivery adds a musical note/chord
- High combos trigger harmony layer
- ×5 combo adds special melodic flourish

**Track Specifications:**
- Length: 2-3 minute loops
- Seamless loop points
- Mixed in stems for layer control
- Format: OGG Vorbis (for LÖVE compatibility)

**Music Tracks:**

1. **Main Theme** - Menu music, calm and inviting
2. **Night Run** - Primary gameplay track, adaptive
3. **Victory Sunrise** - Success jingle (15s)
4. **Dawn's Arrival** - Failure music, gentle (10s)
5. **Endless Mode** - Extended procedural variant

---

### Sound Effects

**Movement SFX:**

| Action | Sound | Details |
|--------|-------|---------|
| Footstep | Soft tap | Pitch varies, 3 variations |
| Jump | Poff | Airy, short |
| Land | Soft thud | Subtle, not harsh |
| Dash | Whoosh | Directional, sharp |
| Wall-slide | Scrape | Continuous, material-based |
| Wall-jump | Poff + scrape | Combination |

**Delivery SFX:**

| Event | Sound | Details |
|-------|-------|---------|
| Approach window | Soft chime | Musical note (C5) |
| Deliver action | Flutter | Paper rustling |
| Letter absorb | Sparkle | Magical, gentle |
| Combo increment | Piano note | Ascending scale |
| ×5 combo | Chord | Triumphant |

**Environment SFX:**

| Element | Sound | Details |
|---------|-------|---------|
| Wind | Ambient whoosh | Continuous, subtle |
| Distant city | Low hum | Very quiet |
| Vent steam | Hiss | Punctuated |
| Pigeon coo | Gentle coo | Occasional |
| Antenna fall | Creak + crash | Comedic |
| Glass crack | Tinkle | Delicate |

**UI SFX:**

| Action | Sound | Details |
|--------|-------|---------|
| Menu navigate | Click | Soft |
| Menu select | Chime | Positive |
| Menu back | Clack | Gentle |
| Timer warning | Bell | Gradual urgency |
| Power-up collect | Ding | Happy |

**Audio Philosophy:**
- Soft, not harsh
- Complements music, doesn't overpower
- Positional audio for immersion
- Volume balanced for comfort
- All sounds fit aesthetic (no jarring modern sounds)

---

## 13. Narrative Design

### Narrative Philosophy

Courier Cat tells its story **environmentally** and through **fragmentary letters**. There is no dialogue, cutscenes, or exposition dumps. The narrative emerges from:

1. The world itself (visual storytelling)
2. Letter fragments (collectible text snippets)
3. Player interpretation (emergent meaning)

---

### Core Narrative

**The Surface Story:**
You are a cat who delivers letters at night. Simple, cozy, wholesome.

**The Deeper Story (Revealed Through Letters):**

The city is a **liminal space between waking and dreaming**. The letters aren't just mail—they're **messages between people who exist in different states of consciousness**. Some recipients are awake and lonely. Some are asleep and dreaming. Some are memories.

Courier Cat is the only one who can cross these boundaries. You're not just delivering mail—you're connecting fragments of people's hearts across the threshold of sleep.

**Thematic Core:**
- Connection despite distance
- Memory and loss
- The beauty of ephemeral moments
- Dedication to small, meaningful work
- The magic hidden in mundane rituals

---

### Letter Fragment System

**Collection Mechanic:**
- 30 unique letter fragments
- Each delivery has a 40% chance to drop a fragment
- Fragments are tied to specific delivery locations
- Higher combos increase drop rate
- Completing all 30 unlocks "True Ending" letter

**Fragment Types:**

**1. Mundane Letters (40% of fragments)**
These seem normal at first:

> "Remind me to water the plants on Tuesday."

> "The bread is in the usual place. Don't wait up."

> "Your light is still on. Are you okay?"

**2. Wistful Letters (30% of fragments)**
These hint at longing:

> "I dreamed of your voice last night. It's been so long."

> "The city looks different from up here. Do you see it too?"

> "Sometimes I forget which side of the window I'm on."

**3. Mysterious Letters (20% of fragments)**
These suggest something deeper:

> "The cat knows. The cat always knows."

> "When the moon shrinks, where does it go?"

> "Tell me—what color is the sky in your dream?"

**4. Revelatory Letters (10% of fragments)**
These reveal the truth:

> "I'm writing to someone I'll never meet. You're writing to someone who forgot you."

> "We're all asleep, aren't we? Except the courier."

> "Thank you for carrying what we cannot hold."

**The "True Ending" Letter (Fragment 30):**

> "Dear Courier,
>
> You've walked these rooftops a thousand nights, carrying our words when we couldn't carry them ourselves. You connected the sleeping and the waking, the living and the remembered, the lonely and the loved.
>
> We never knew your name. You never asked for ours.
>
> But every letter you delivered mattered. Every window you visited held a world.
>
> Dawn is coming. It always does.
>
> But tonight—this night—you made the darkness a little less lonely.
>
> Thank you, little courier.
>
> When you're ready, rest. We'll keep each other company in the dreams.
>
> — The City"

---

### Environmental Storytelling

**Visual Narrative Elements:**

1. **Window Variations:**
   - Some windows have plants (cared for)
   - Some are dark (abandoned)
   - Some have silhouettes (people watching)
   - Some flicker (TVs on)

2. **Rooftop Details:**
   - Forgotten toys
   - Drying laundry
   - Makeshift gardens
   - Old antennas (outdated technology)

3. **Skyline Changes:**
   - Certain buildings' lights turn off over time
   - New windows light up in later nights
   - Constellations shift (time passage)

4. **Letter Bag Details:**
   - Bag gets lighter as deliveries complete (visual weight)
   - Final letter glows brightest
   - Bag has worn patches (history)

**No Explicit Narrative Delivery:**
- Players discover meaning themselves
- Multiple interpretations are valid
- Not every player will collect all fragments
- The game is complete without the narrative layer

---

## 14. Art Direction

### Visual Specifications

**Resolution:**
- Base resolution: 320×180 pixels
- Scaled up to window size with nearest-neighbor filtering
- 16:9 aspect ratio
- Pixel-perfect rendering

**Color Palette:**

**Primary Palette (12 colors):**

```
Night Sky:       #1a1c2c (deep blue-black)
Shadow:          #5d275d (purple shadow)
Mid-purple:      #b13e53 (warm purple)
Rooftop:         #ef7d57 (orange-brown)
Accent:          #ffcd75 (warm yellow)
Highlight:       #a7f070 (gentle green-yellow)
Window Glow:     #38b764 (mint green)
Sky Gradient 1:  #257179 (teal)
Sky Gradient 2:  #29366f (deep blue)
Moon:            #f4f4f4 (off-white)
Cloud:           #566c86 (blue-gray)
Detail:          #333c57 (dark blue-gray)
```

**Expanded Palette (+4 colors for detail):**
- Dawn orange: #ff8563
- Letter glow: #41a6f6
- Warning red: #e43b44
- Combo purple: #8b6bd9

### Sprite Specifications

**Player Character (Cat):**
- Size: 16×16 pixels
- Hitbox: 10×14 pixels (centered)
- Animations:
  - Idle: 2 frames, 1 FPS (tail swish)
  - Run: 4 frames, 12 FPS
  - Jump: 3 frames (squat, rise, fall)
  - Dash: 2 frames, 8 FPS (blur trail)
  - Wall-slide: 1 frame (static)
  - Deliver: 3 frames, 10 FPS

**Tile Sets:**
- Tile size: 16×16 pixels
- Rooftop tiles: 8 variations
- Wall tiles: 4 variations
- Detail tiles: 12+ variations (chimneys, vents, etc.)
- Platform tiles: Semi-solid variants

**Props & Objects:**
- Power-ups: 16×16 (animated)
- Hazards: 16×16 to 32×32 (depending on type)
- Windows: 16×24 (tall)
- Delivery glow: Particle effect overlay

### Animation Principles

1. **Limited Frame Count:**
   - Most animations: 2-4 frames
   - Focus on key poses
   - Smooth via timing, not frame count

2. **Squash & Stretch:**
   - Landing squash (1 frame)
   - Jump stretch (subtle)
   - Dash trail effect

3. **Anticipation:**
   - Crouch before dash
   - Wind-up before wall-jump

4. **Follow-Through:**
   - Tail lags behind body
   - Bag bounces after landing
   - Ears settle after movement

### Parallax Background Layers

**Layer 1 - Far Background (0.1x scroll speed):**
- Distant city silhouette
- Very dark, low detail
- Largest buildings
- Static stars

**Layer 2 - Mid Background (0.3x scroll speed):**
- Closer buildings
- Window patterns
- Cloud layer 1 (slow drift)

**Layer 3 - Near Background (0.6x scroll speed):**
- Adjacent rooftops
- Detailed architecture
- Cloud layer 2 (medium drift)

**Layer 4 - Playfield (1.0x scroll speed):**
- Player and interactive elements
- Full detail and collision

**Layer 5 - Foreground (1.2x scroll speed):**
- Occasional foreground elements
- Hanging laundry, antennas
- Creates depth

### Lighting & Atmosphere

**Color Grading States:**

1. **Night (0-90s remaining):**
   - Deep purple/blue tones
   - High contrast
   - Sharp shadows
   - Cool color temperature

2. **Dawn Approach (90-45s):**
   - Purple shifts to purple-orange
   - Contrast softens
   - Shadows lighten
   - Warming color temperature

3. **Sunrise (45-0s):**
   - Orange/pink/yellow dominance
   - Low contrast
   - Soft shadows
   - Warm color temperature

**Lighting Effects:**
- Window glow (additive blending)
- Moon glow (radial gradient)
- Delivery sparkles (particle system)
- Dash trail (motion blur)
- Power-up auras (subtle glow)

---

## 15. Difficulty & Balancing

### Difficulty Curve

**Design Philosophy:**
- Gentle learning curve
- Difficulty through level design, not mechanics
- Player skill expression is king
- No artificial difficulty (RNG, cheap deaths)

### Progression Arc

**Nights 1-2: Tutorial & Foundations**
- **Deliveries:** 5-7
- **Time:** Generous (180-210s)
- **Hazards:** Minimal (0-2)
- **Focus:** Teaching core movement
- **Success Rate Target:** 85%

**Nights 3-4: Building Confidence**
- **Deliveries:** 8-10
- **Time:** Moderate (210-240s)
- **Hazards:** Light (2-4)
- **Focus:** Introducing combos and power-ups
- **Success Rate Target:** 70%

**Nights 5-7: Challenging Flow**
- **Deliveries:** 10-12
- **Time:** Tight (240-270s)
- **Hazards:** Moderate (4-6)
- **Focus:** Route optimization
- **Success Rate Target:** 50%

**Nights 8-10: Mastery**
- **Deliveries:** 12-15
- **Time:** Very tight (270-300s)
- **Hazards:** Heavy (6-8)
- **Focus:** Advanced techniques
- **Success Rate Target:** 30%

**Endless Mode: Escalating Challenge**
- **Deliveries:** Infinite, procedural
- **Time:** Starts at 180s, decreases by 5s per delivery
- **Hazards:** Increase density over time
- **Focus:** High score chasing
- **Success Rate Target:** N/A (score-based)

### Balancing Metrics

**Movement Speed:**
- Run: 120 px/s (base)
- Run + Coffee: 180 px/s (+50%)
- Dash: 300 px/s (2.5x run speed)
- Wall-slide: 40 px/s (descent)
- Jump apex: 0.4s

**Spatial Metrics:**
- Minimum gap width: 32 pixels (2 tiles, easy jump)
- Medium gap width: 48 pixels (3 tiles, run + jump)
- Large gap width: 64 pixels (4 tiles, dash-jump)
- Maximum gap width: 80 pixels (5 tiles, coffee + dash-jump)

**Timer Balance:**
- Base time should allow 1.5x the optimal route time
- Each delivery adds ~8-16s
- Optimal players finish with 30-60s remaining
- Casual players finish with 0-15s remaining

### Player Skill Tiers

**Tier 1 - Beginner:**
- Completes Night 1-3
- Uses ground path primarily
- Minimal combos
- Relies on safety

**Tier 2 - Intermediate:**
- Completes Night 4-7
- Uses air deliveries
- Maintains 2-3x combos
- Takes calculated risks

**Tier 3 - Advanced:**
- Completes Night 8-10
- Chains wall-jumps
- Maintains 4-5x combos
- Optimizes routes

**Tier 4 - Master:**
- S+ ranks
- Endless Mode high scores
- Speedrun strategies
- No-ground runs

### Dynamic Difficulty (Stretch Goal)

**Optional Adaptive Systems:**
- If player fails 3 times, add +30s to timer
- If player succeeds with >60s remaining, add 1 delivery
- Hazard density adjusts based on recent performance
- Always opt-in via settings

---

## 16. Replayability

### Replayability Pillars

1. **Procedural Variations**
2. **Score Chasing & Rankings**
3. **Letter Collection**
4. **Skill Mastery**
5. **Speedrunning**

### Procedural Variations

**What Changes Between Runs:**
- Delivery point positions (within valid zones)
- Hazard placement and timing
- Power-up locations
- Minor tile variations
- Cloud patterns and skyline details

**What Stays Consistent:**
- Core platform layout (muscle memory)
- Number of deliveries
- Overall difficulty
- Required techniques

**Seeded Runs (Stretch Goal):**
- Daily challenge seed
- Custom seed input
- Leaderboards per seed

### Score Chasing

**Leaderboard Structure:**

**Global Leaderboards (Stretch Goal):**
- Per-night high scores
- Overall cumulative score
- Endless Mode high score
- Speedrun times

**Personal Bests:**
- Best rank per night
- Highest combo achieved
- Most letters collected
- Fastest completion

**Challenge Modes (Stretch Goal):**
- No-ground run
- No-dash run
- Perfect combo (never break)
- Minimum time (speedrun)

### Letter Collection

**Completionist Hook:**
- 30 letter fragments to collect
- Each reveals part of larger story
- Fragments unlock in semi-random order
- Collecting all 30 unlocks True Ending
- Archive menu for re-reading

**Fragment Rarities:**
- Common: 40% (easy to find)
- Uncommon: 30% (moderate effort)
- Rare: 20% (high combo required)
- Legendary: 10% (specific conditions)

### Skill Mastery

**Skill Expression:**
- Movement tech discovery (dash-jumps, wall-kick chains)
- Route optimization
- Risk/reward decisions
- Combo maintenance
- Perfect timing

**Mastery Indicators:**
- S+ ranks
- No-damage runs
- Sub-2-minute completions
- ×5 combo maintenance

### Speedrunning Support

**Built-In Features:**
- In-game timer (frame-perfect)
- Quick restart (no load time)
- Consistent physics (deterministic)
- Input display (optional)
- Replay saving (stretch goal)

**Speedrun Categories:**
- Any% (complete any night)
- 100% (all letters + S+ all nights)
- Individual night runs
- Endless Mode (high score)

---

## 17. Accessibility

### Visual Accessibility

**Colorblind Modes:**
- Protanopia (red-blind) palette
- Deuteranopia (green-blind) palette
- Tritanopia (blue-blind) palette
- High-contrast mode

**UI Scaling:**
- 1x (default 320×180)
- 2x (640×360)
- 3x (960×540)
- 4x (1280×720)

**Visual Assists:**
- Optional digital timer (in addition to moon)
- Combo counter always visible (not just near player)
- Hazard outlines (highlight dangerous elements)
- Delivery zone radius indicators

**Screen Effects:**
- Toggle screen shake
- Reduce particle effects
- Disable flashing (critical timer)

### Audio Accessibility

**Volume Controls:**
- Master volume
- Music volume
- SFX volume
- Ambient volume

**Audio Substitution:**
- Visual indicators for audio cues
- Closed captions for important sounds (stretch)
- Screen flash when timer critical

**Audio Modes:**
- Mono audio (for single-ear hearing)
- Stereo enhancement toggle

### Control Accessibility

**Input Options:**
- Full button remapping
- Keyboard-only play
- Gamepad-only play
- One-handed mode (auto-run toggle)

**Input Assists:**
- Extended jump buffer (6-12 frames)
- Extended coyote time (4-8 frames)
- Auto-deliver (trigger when in range)
- Dash as toggle vs hold
- Reduced input complexity mode

### Gameplay Accessibility

**Difficulty Modifiers:**
- Extended timer (+25%, +50%, +100%, infinite)
- Reduced hazard density
- Invincibility mode
- Practice mode (no fail state)
- Slow-motion mode (0.5x, 0.75x speed)

**Assist Indicators:**
- Clear "assist mode active" indicator
- Separate leaderboards for assist mode
- No judgment, no penalties

**Pause & Save:**
- Pause at any time
- Auto-save progress
- Resume mid-run (stretch goal)

---

## 18. Stretch Goals

### Tier 1 - Polish & Content

**Photo Mode:**
- Press P to freeze game
- Free camera movement
- Hide UI option
- Save screenshot locally
- Share to social media (stretch)

**Weather Variants:**
- Rain: Visual effect, slippery platforms
- Fog: Reduced visibility, atmospheric
- Fireworks: Visual spectacle, timed events
- Full moon: Brighter lighting, more time

**Cosmetic Unlocks:**
- Alternate cat colors (orange, black, calico)
- Different mail bag styles
- Skyline palette swaps
- Earned via challenges

### Tier 2 - New Modes

**Co-op Mode (Signal & Runner):**
- Player 1: Controls cat
- Player 2: Guides with map, hints
- Asymmetric co-op
- Local only

**Endless "Dawn Mode":**
- Procedurally generated cityscape
- Deliveries appear infinitely
- Gradual lighting change
- Difficulty escalates
- High score leaderboard

**Custom Night Builder:**
- Place delivery points
- Customize hazards
- Set timer
- Share with code

### Tier 3 - Community & Longevity

**Speedrun Features:**
- Built-in timer (frame-perfect)
- Input display
- Replay recording & playback
- Ghost replay race

**Daily Challenges:**
- Seeded daily run
- Global leaderboard
- Unique modifiers
- 24-hour rotation

**Community Features:**
- Level sharing (custom nights)
- Replay sharing
- Global leaderboards
- Monthly tournaments

### Tier 4 - Expansion Content

**New Cityscape (DLC Idea):**
- Winter city (snow theme)
- Harbor district (docks, boats)
- Suburbs (lower, wider buildings)
- New hazards and power-ups

**Story Expansion:**
- Additional 10 letter fragments
- Alternate endings
- Character relationships explored
- Deeper lore

**Advanced Mechanics:**
- Glide ability (hold jump while falling)
- Grappling hook (experimental)
- Double-dash (risky power-up)

---

## Appendix A: Design Reference

**Movement Inspirations:**
- Celeste (precision platforming, forgiving mechanics)
- Super Meat Boy (tight controls, quick restart)
- Ori series (flow and grace)

**Aesthetic Inspirations:**
- Night in the Woods (tone, color palette)
- Katana Zero (neon lighting, parallax)
- A Short Hike (cozy, low-stakes)

**Narrative Inspirations:**
- Kiki's Delivery Service (theme of delivery, growth)
- Journey (environmental storytelling)
- What Remains of Edith Finch (fragmented narrative)

---

## Appendix B: Key Metrics Summary

| Metric | Value |
|--------|-------|
| Target session length | 5-8 minutes |
| Player sprite size | 16×16 px |
| Player hitbox | 10×14 px |
| Base run speed | 120 px/s |
| Jump height | 48 px |
| Dash distance | 60 px |
| Base timer (Night 1) | 180s |
| Deliveries (Night 1) | 5 |
| Deliveries (Night 10) | 15 |
| Color palette | 16 colors |
| Base resolution | 320×180 |

---

**End of Game Design Document**

*This GDD is a living document and will evolve during development based on playtesting and iteration.*
