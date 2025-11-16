# Courier Cat - Development Plan & Roadmap

**Project Duration:** 16 weeks (4 months)
**Team Size:** Solo developer (or small 2-3 person team)
**Target Release:** End of Week 16

---

## 📍 Current Status (Updated: January 2025)

**Current Phase:** Phase 3 - Content & Polish (Week 6)
**Milestone:** ✅ Vertical Slice Complete | 🔄 Week 6 In Progress

### Completed Work
- ✅ **Weeks 1-2:** Prototype Complete (Movement, Camera, Input)
- ✅ **Weeks 3-5:** Vertical Slice Complete (Full gameplay loop, UI, Audio)
- ✅ **44 JIRA Tickets Completed** (VETS-2 through VETS-52)

### Current Sprint: Week 6 - Content Expansion
**JIRA Tickets:** VETS-53 through VETS-60 (8 tickets)
- 🔄 VETS-53: Test and Polish Night 2
- 🔄 VETS-54: Design and Implement Night 3
- 🔄 VETS-55: Create SaveSystem
- 🔄 VETS-56: Implement Rank Calculation
- 🔄 VETS-57: Create NightSelectState
- 🔄 VETS-58: Update MenuState Integration
- 🔄 VETS-59: Update ResultsState for Progression
- 🔄 VETS-60: Test Full 3-Night Progression

**Goal:** 3 playable nights with full progression system

---

## Table of Contents

1. [Overview](#overview)
2. [Development Philosophy](#development-philosophy)
3. [Phase Breakdown](#phase-breakdown)
4. [Week-by-Week Roadmap](#week-by-week-roadmap)
5. [Risk Assessment](#risk-assessment)
6. [Milestones & Deliverables](#milestones--deliverables)
7. [Testing Schedule](#testing-schedule)
8. [Asset Creation Pipeline](#asset-creation-pipeline)
9. [Dependencies & Blockers](#dependencies--blockers)
10. [Post-Launch Plan](#post-launch-plan)

---

## Overview

This document provides a detailed, actionable development plan for **Courier Cat**, breaking down the 16-week development cycle into manageable phases, weekly goals, and specific tasks.

### Development Phases

1. **Phase 1: Prototype** (Weeks 1-2) - Prove core movement
2. **Phase 2: Vertical Slice** (Weeks 3-5) - Complete gameplay loop
3. **Phase 3: Content & Polish** (Weeks 6-8) - Expand and refine
4. **Phase 4: Full Production** (Weeks 9-12) - Complete all content
5. **Phase 5: Beta & Refinement** (Weeks 13-14) - Testing and balancing
6. **Phase 6: Launch Prep** (Weeks 15-16) - Marketing and release

---

## Development Philosophy

### Core Principles

1. **Playable Builds Always**
   - Every week should produce a playable build
   - Continuous integration of features
   - Test early, test often

2. **Vertical Slices Over Horizontal**
   - Complete one night fully before expanding
   - Ensures core loop is solid
   - Easier to test and iterate

3. **Placeholder Art Early**
   - Don't block on art assets
   - Use rectangles and solid colors
   - Polish visuals in Phase 3-4

4. **Feel First, Content Second**
   - Movement must feel good before expanding
   - Nail the core loop before adding nights
   - Polish > quantity

5. **Scope Flexibility**
   - Have "must-have," "should-have," and "nice-to-have" features
   - Be ready to cut stretch goals
   - Core experience is sacred

### Must-Have Features

- ✅ Core movement (run, jump, dash, wall-slide)
- ✅ Delivery system
- ✅ Timer system
- ✅ 5+ playable nights
- ✅ Basic scoring/progression
- ✅ Pixel art visuals
- ✅ Music and SFX
- ✅ Save system

### Should-Have Features

- ⚠️ 10 playable nights
- ⚠️ Letter fragment collection
- ⚠️ Adaptive music layers
- ⚠️ All power-up types
- ⚠️ All hazard types
- ⚠️ Parallax backgrounds
- ⚠️ Accessibility options

### Nice-to-Have Features (Stretch Goals)

- 🎯 Photo mode
- 🎯 Endless mode
- 🎯 Speedrun tools
- 🎯 Daily challenges
- 🎯 Custom night builder
- 🎯 Co-op mode

---

## Phase Breakdown

### Phase 1: Prototype (Weeks 1-2)

**Objective:** Prove that the core movement feels good

**Focus Areas:**
- Player controller (run, jump)
- Basic physics and collision
- One test level
- Camera system
- Input handling

**Technical Goals:**
- Set up LÖVE project structure
- Integrate bump.lua for collision
- Implement fixed timestep
- Create entity-component base

**Deliverable:** Playable prototype with satisfying movement

**Success Metrics:**
- Can run and jump smoothly
- Jump height/distance feels right
- Camera follows player correctly
- No major bugs or glitches

---

### Phase 2: Vertical Slice (Weeks 3-5)

**Objective:** Complete one full night with all core systems

**Focus Areas:**
- Full movement suite (dash, wall-slide, wall-jump)
- Delivery system
- Timer and scoring
- First complete level
- Basic hazards and power-ups
- Win/lose states

**Technical Goals:**
- State management system
- Animation system
- Particle effects (basic)
- Audio integration (placeholder)
- UI framework

**Deliverable:** One complete, polished night

**Success Metrics:**
- Night is completable in 3-5 minutes
- All mechanics feel good
- Deliveries are satisfying
- Timer creates appropriate tension
- Win/lose states work correctly

---

### Phase 3: Content & Polish (Weeks 6-8)

**Objective:** Expand to 3 nights and add visual/audio polish

**Focus Areas:**
- Create Nights 2 and 3
- Finalize pixel art for player
- Create tile sets
- Implement all hazard types
- Add power-ups
- Real music and SFX
- UI polish
- Particle effects

**Technical Goals:**
- Level loading system
- Procedural variation system
- Audio manager (adaptive music)
- Parallax background system

**Deliverable:** 3 polished nights with complete art and audio

**Success Metrics:**
- Each night feels distinct
- Difficulty curve is smooth
- Visuals are cohesive
- Audio enhances atmosphere
- No placeholder art in core gameplay

---

### Phase 4: Full Production (Weeks 9-12)

**Objective:** Complete all 10 nights and major features

**Focus Areas:**
- Create Nights 4-10
- Letter fragment system
- Menu systems (main, night select, results)
- Save/load system
- Settings menu
- Accessibility features
- Achievements/progression
- All power-ups and hazards

**Technical Goals:**
- Save system
- Data persistence
- Achievement tracking
- Performance optimization

**Deliverable:** Feature-complete game

**Success Metrics:**
- All 10 nights are completable
- Letter fragments are collectible
- Save/load works flawlessly
- Progression feels rewarding
- Performance is solid (60 FPS)

---

### Phase 5: Beta & Refinement (Weeks 13-14)

**Objective:** Bug fixing, balancing, and polish

**Focus Areas:**
- Playtesting (internal and external)
- Bug fixing
- Balance adjustments
- Performance optimization
- Edge case handling
- Quality assurance

**Technical Goals:**
- Profiling and optimization
- Memory leak fixes
- Platform-specific testing
- Build automation

**Deliverable:** Beta-ready build

**Success Metrics:**
- No critical bugs
- Balanced difficulty
- Positive playtester feedback
- Smooth performance on all platforms

---

### Phase 6: Launch Prep (Weeks 15-16)

**Objective:** Prepare for public release

**Focus Areas:**
- Trailer creation
- Screenshot capture
- Store page setup (itch.io)
- Press kit
- Marketing materials
- Final bug fixes
- Platform builds

**Technical Goals:**
- Final optimization pass
- Build signing and packaging
- Update scripts

**Deliverable:** Public release

**Success Metrics:**
- Game is released on target date
- Store page is polished
- Marketing materials are ready
- No game-breaking bugs at launch

---

## Week-by-Week Roadmap

### Week 1: Foundation & Basic Movement

**Monday-Tuesday: Project Setup**
- [ ] Create LÖVE project structure
- [ ] Set up version control (Git)
- [ ] Configure conf.lua
- [ ] Integrate libraries (bump.lua, anim8, hump.camera)
- [ ] Create basic file organization
- [ ] Set up constants and utilities

**Wednesday-Thursday: Player Movement (Part 1)**
- [ ] Implement Transform component
- [ ] Implement Physics component
- [ ] Implement Collision component
- [ ] Create Player entity
- [ ] Implement running (left/right)
- [ ] Implement basic jumping
- [ ] Test movement feel

**Friday-Sunday: Camera & Testing**
- [ ] Implement camera system (following player)
- [ ] Create test level (platforms)
- [ ] Integrate collision detection
- [ ] Test and iterate on jump feel
- [ ] Document issues and improvements

**Deliverable:** Player can run and jump in a test level

---

### Week 2: Advanced Movement & Polish

**Monday-Tuesday: Wall Mechanics**
- [ ] Implement wall detection
- [ ] Implement wall-sliding
- [ ] Implement wall-jumping
- [ ] Test wall mechanics feel
- [ ] Add coyote time
- [ ] Add jump buffering

**Wednesday-Thursday: Dashing**
- [ ] Implement dash mechanic
- [ ] Implement dash cooldown
- [ ] Add 8-directional air dash
- [ ] Create dash visual feedback (trail)
- [ ] Test dash feel and balance

**Friday-Sunday: Input System & Refinement**
- [ ] Build input abstraction layer
- [ ] Implement input buffering
- [ ] Add gamepad support
- [ ] Polish movement values
- [ ] Create movement reference document
- [ ] **MILESTONE: Prototype Complete**

**Deliverable:** Fully-featured movement system that feels great

---

### Week 3: Core Gameplay Systems

**Monday-Tuesday: Delivery System**
- [ ] Create DeliveryZone entity
- [ ] Implement delivery detection
- [ ] Implement delivery action
- [ ] Create delivery animation/feedback
- [ ] Add delivery zones to test level

**Wednesday-Thursday: Timer & Scoring**
- [ ] Implement timer system
- [ ] Create moon timer visual
- [ ] Implement time extensions
- [ ] Create scoring system
- [ ] Implement combo mechanics
- [ ] Test scoring balance

**Friday-Sunday: Win/Lose States**
- [ ] Create StateManager system
- [ ] Implement GameState
- [ ] Implement ResultsState
- [ ] Create win condition (all deliveries)
- [ ] Create lose condition (timer runs out)
- [ ] Test state transitions

**Deliverable:** Complete gameplay loop (play, deliver, win/lose)

---

### Week 4: First Level & Hazards

**Monday-Tuesday: Level System**
- [ ] Design Level 1 (Night 1)
- [ ] Implement level JSON format
- [ ] Create level loader
- [ ] Place 5 delivery zones
- [ ] Test level flow and timing

**Wednesday-Thursday: Basic Hazards**
- [ ] Implement steam vent hazard
- [ ] Implement laundry line hazard
- [ ] Add hazards to Level 1
- [ ] Test hazard interactions

**Friday-Sunday: Power-Ups**
- [ ] Create PowerUp base entity
- [ ] Implement coffee power-up (speed boost)
- [ ] Add power-up to Level 1
- [ ] Test power-up balance
- [ ] Polish timing

**Deliverable:** One complete level with deliveries, hazards, and power-ups

---

### Week 5: Animation & UI

**Monday-Tuesday: Animation System**
- [ ] Integrate anim8 library
- [ ] Create Animation component
- [ ] Create placeholder sprite sheet
- [ ] Implement player animations (idle, run, jump, dash, wall-slide)
- [ ] Test animation transitions

**Wednesday-Thursday: UI Framework**
- [ ] Create HUD system
- [ ] Implement timer display (moon)
- [ ] Implement combo display
- [ ] Implement score display
- [ ] Create pause menu

**Friday-Sunday: Audio (Placeholder)**
- [ ] Integrate audio system
- [ ] Add placeholder music
- [ ] Add placeholder SFX (jump, dash, deliver)
- [ ] Test audio integration
- [ ] **MILESTONE: Vertical Slice Complete**

**Deliverable:** Polished single night with UI and audio

---

### Week 6: Content Expansion 🔄 IN PROGRESS (VETS-53 through VETS-60)

**Monday-Tuesday: Night 2 (VETS-53)**
- [x] Test Night 2 thoroughly (night2.json already exists)
- [x] Verify 7 delivery zones are reachable
- [x] Test difficulty progression from Night 1
- [x] Balance timer and hazards
- [x] Polish based on playtesting

**Wednesday-Thursday: Night 3 (VETS-54, VETS-55, VETS-56)**
- [ ] Design Night 3 layout **(VETS-54)**
- [ ] Create night3.json with 8-10 delivery zones **(VETS-54)**
- [ ] Add 4-6 mixed hazards **(VETS-54)**
- [ ] Implement SaveSystem **(VETS-55)**
- [ ] Implement rank calculation **(VETS-56)**
- [ ] Test difficulty curve across all 3 nights **(VETS-54)**

**Friday-Sunday: Night Select Screen & Progression (VETS-57, VETS-58, VETS-59, VETS-60)**
- [ ] Create NightSelectState **(VETS-57)**
- [ ] Update MenuState to use NightSelectState **(VETS-58)**
- [ ] Update ResultsState for save/progression **(VETS-59)**
- [ ] Implement night unlocking logic **(VETS-55, VETS-59)**
- [ ] Show best ranks and scores **(VETS-57, VETS-59)**
- [ ] Test full 3-night progression flow **(VETS-60)**

**Deliverable:** 3 playable nights with full progression system

**JIRA Tickets:**
- VETS-53: Test and Polish Night 2
- VETS-54: Design and Implement Night 3
- VETS-55: Create SaveSystem
- VETS-56: Implement Rank Calculation
- VETS-57: Create NightSelectState
- VETS-58: Update MenuState Integration
- VETS-59: Update ResultsState for Progression
- VETS-60: Test Full 3-Night Progression

---

### Week 7: Art Assets (Player & Tiles)

**Monday-Tuesday: Player Sprite**
- [ ] Design cat character (16×16)
- [ ] Create color palette
- [ ] Draw idle animation
- [ ] Draw run animation (4 frames)
- [ ] Draw jump animation (3 frames)

**Wednesday-Thursday: Player Sprite (Continued)**
- [ ] Draw dash animation
- [ ] Draw wall-slide frame
- [ ] Draw delivery animation
- [ ] Export sprite sheets
- [ ] Integrate into game

**Friday-Sunday: Tile Sets**
- [ ] Design rooftop tiles
- [ ] Create tile variations
- [ ] Create platform tiles
- [ ] Create prop tiles (chimneys, vents, windows)
- [ ] Integrate tiles into levels

**Deliverable:** Complete player sprite and tile art

---

### Week 8: Audio & Visual Polish

**Monday-Tuesday: Music**
- [ ] Create main theme (menu music)
- [ ] Create "Night Run" gameplay track
- [ ] Create victory jingle
- [ ] Create failure music
- [ ] Integrate music into game

**Wednesday-Thursday: Sound Effects**
- [ ] Create jump SFX
- [ ] Create dash SFX
- [ ] Create delivery SFX
- [ ] Create UI SFX (menu clicks, etc.)
- [ ] Create hazard SFX
- [ ] Integrate all SFX

**Friday-Sunday: Particles & Polish**
- [ ] Implement particle system
- [ ] Add dust particles (running, landing)
- [ ] Add delivery sparkles
- [ ] Add dash trail effect
- [ ] Add screen shake (subtle)
- [ ] **MILESTONE: Content & Polish Complete**

**Deliverable:** 3 fully polished nights with final art and audio

---

### Week 9: Nights 4-6

**Monday-Tuesday: Night 4**
- [ ] Design layout (medium difficulty)
- [ ] Add 10 delivery zones
- [ ] Add varied hazards
- [ ] Test and balance

**Wednesday-Thursday: Night 5**
- [ ] Design layout (increasing difficulty)
- [ ] Add 10-12 delivery zones
- [ ] Introduce priority mail (red glow)
- [ ] Test and balance

**Friday-Sunday: Night 6**
- [ ] Design layout
- [ ] Add 12 delivery zones
- [ ] Add complex platforming
- [ ] Test difficulty spike

**Deliverable:** 6 playable nights

---

### Week 10: Nights 7-10

**Monday-Tuesday: Nights 7-8**
- [ ] Design Night 7 (hard)
- [ ] Design Night 8 (hard)
- [ ] Add 12-15 delivery zones each
- [ ] Add all hazard types
- [ ] Test and balance

**Wednesday-Thursday: Nights 9-10**
- [ ] Design Night 9 (very hard)
- [ ] Design Night 10 (master)
- [ ] Add 15 delivery zones each
- [ ] Create signature challenges
- [ ] Test mastery feel

**Friday-Sunday: Procedural Variations**
- [ ] Implement variation system
- [ ] Randomize delivery positions
- [ ] Randomize hazard timing
- [ ] Test seed reproducibility

**Deliverable:** All 10 nights complete

---

### Week 11: Letter System & Menus

**Monday-Tuesday: Letter Fragments**
- [ ] Write all 30 letter fragments
- [ ] Implement fragment drop system
- [ ] Create LetterArchiveState
- [ ] Implement fragment unlocking
- [ ] Test collection rate

**Wednesday-Thursday: Menu Systems**
- [ ] Polish MainMenuState
- [ ] Create OptionsState
- [ ] Implement settings (volume, controls, accessibility)
- [ ] Create credits screen
- [ ] Test menu flow

**Friday-Sunday: Save System**
- [ ] Implement SaveData structure
- [ ] Create save/load functions
- [ ] Implement auto-save triggers
- [ ] Test persistence
- [ ] Test save migration (version changes)

**Deliverable:** Complete menu and save systems

---

### Week 12: Final Features & Systems

**Monday-Tuesday: Adaptive Music**
- [ ] Create music stems (base, rhythm, harmony, tension)
- [ ] Implement AdaptiveMusic system
- [ ] Link to timer states
- [ ] Test smooth transitions

**Wednesday-Thursday: Parallax Backgrounds**
- [ ] Create far background layer
- [ ] Create mid background layer
- [ ] Create near background layer
- [ ] Implement parallax system
- [ ] Integrate into all nights

**Friday-Sunday: Accessibility**
- [ ] Implement colorblind modes
- [ ] Add assist options (extended timer, etc.)
- [ ] Add UI scaling
- [ ] Test all options
- [ ] **MILESTONE: Feature Complete**

**Deliverable:** All major features implemented

---

### Week 13: Internal Testing & Bug Fixing

**Monday-Tuesday: Full Playthrough**
- [ ] Play all 10 nights start to finish
- [ ] Document all bugs
- [ ] Note balance issues
- [ ] Check for soft locks
- [ ] Test edge cases

**Wednesday-Thursday: Bug Fixes (Pass 1)**
- [ ] Fix critical bugs
- [ ] Fix game-breaking issues
- [ ] Fix major balance problems
- [ ] Fix collision bugs
- [ ] Fix UI bugs

**Friday-Sunday: Bug Fixes (Pass 2)**
- [ ] Fix medium-priority bugs
- [ ] Polish rough edges
- [ ] Improve feedback
- [ ] Test fixes

**Deliverable:** Stable, bug-free build

---

### Week 14: External Beta Testing

**Monday: Beta Preparation**
- [ ] Create beta build
- [ ] Write testing instructions
- [ ] Create feedback form
- [ ] Recruit 5-10 playtesters

**Tuesday-Thursday: Beta Testing Period**
- [ ] Distribute beta builds
- [ ] Monitor feedback
- [ ] Answer questions
- [ ] Collect bug reports
- [ ] Gather balance feedback

**Friday-Sunday: Beta Feedback Integration**
- [ ] Fix reported bugs
- [ ] Adjust difficulty based on feedback
- [ ] Make UX improvements
- [ ] Test fixes
- [ ] **MILESTONE: Beta Complete**

**Deliverable:** Polished, tested game

---

### Week 15: Platform Builds & Final Polish

**Monday-Tuesday: Platform Builds**
- [ ] Create Windows build (.exe)
- [ ] Create macOS build (.app)
- [ ] Create Linux build (.love)
- [ ] Test each platform
- [ ] Fix platform-specific bugs

**Wednesday-Thursday: Final Polish**
- [ ] Final optimization pass
- [ ] Memory leak checks
- [ ] Performance profiling
- [ ] Final balance tweaks
- [ ] Final playtests

**Friday-Sunday: Marketing Assets (Part 1)**
- [ ] Capture gameplay footage
- [ ] Create GIFs for social media
- [ ] Take polished screenshots
- [ ] Write game description

**Deliverable:** Release-ready builds for all platforms

---

### Week 16: Launch Week

**Monday-Tuesday: Marketing Assets (Part 2)**
- [ ] Edit trailer (1-2 minutes)
- [ ] Create thumbnail/key art
- [ ] Write press release
- [ ] Prepare press kit

**Wednesday: Store Setup**
- [ ] Create itch.io page
- [ ] Upload builds
- [ ] Write store description
- [ ] Set pricing
- [ ] Upload screenshots and trailer

**Thursday: Pre-Launch**
- [ ] Final build verification
- [ ] Set release date/time
- [ ] Prepare launch announcement
- [ ] Notify press/influencers

**Friday: LAUNCH DAY 🚀**
- [ ] Publish game on itch.io
- [ ] Post launch announcement (social media)
- [ ] Monitor for critical bugs
- [ ] Respond to player feedback
- [ ] **MILESTONE: Launch!**

**Weekend: Post-Launch Support**
- [ ] Monitor reviews and feedback
- [ ] Fix any critical bugs immediately
- [ ] Engage with community
- [ ] Celebrate!

**Deliverable:** Public release of Courier Cat

---

## Risk Assessment

### High-Risk Areas

**1. Movement Feel**
- **Risk:** Movement doesn't feel good, game is unenjoyable
- **Mitigation:** Spend extra time in Week 1-2, iterate heavily, get feedback early
- **Contingency:** Have reference values from Celeste/similar games

**2. Scope Creep**
- **Risk:** Adding too many features, missing deadline
- **Mitigation:** Strict feature prioritization, weekly scope reviews
- **Contingency:** Cut nice-to-have features (endless mode, photo mode, etc.)

**3. Art Asset Creation**
- **Risk:** Art takes longer than expected
- **Mitigation:** Use placeholder art until Week 7, consider hiring pixel artist
- **Contingency:** Simplify art style, reduce animation frames

**4. Technical Bugs**
- **Risk:** Physics bugs, collision issues, save corruption
- **Mitigation:** Test continuously, use version control, write unit tests
- **Contingency:** Allocate extra time in Week 13-14

### Medium-Risk Areas

**5. Level Design**
- **Risk:** Levels aren't fun or too difficult
- **Mitigation:** Playtest frequently, gather feedback, iterate quickly
- **Contingency:** Simplify layouts, reduce delivery counts

**6. Audio Production**
- **Risk:** Music/SFX creation takes longer than expected
- **Mitigation:** Source royalty-free music as backup, simple SFX
- **Contingency:** Use high-quality free assets

**7. Performance Issues**
- **Risk:** Game doesn't run at 60 FPS on target hardware
- **Mitigation:** Profile early, optimize as you go, use object pooling
- **Contingency:** Reduce particle effects, simplify backgrounds

---

## Milestones & Deliverables

### Milestone 1: Prototype Complete (End of Week 2)
- ✅ Player movement (run, jump, dash, wall-slide)
- ✅ Camera system
- ✅ Test level with platforms
- ✅ Input system
- ✅ Feels good to play

**Approval Criteria:** Movement feels responsive and fun

---

### Milestone 2: Vertical Slice Complete (End of Week 5)
- ✅ One complete night
- ✅ Delivery system
- ✅ Timer and scoring
- ✅ Win/lose states
- ✅ Basic UI
- ✅ Placeholder audio

**Approval Criteria:** Full gameplay loop is functional and enjoyable

---

### Milestone 3: Content & Polish Complete (End of Week 8)
- ✅ 3 polished nights
- ✅ Final player art
- ✅ Tile sets
- ✅ Real music and SFX
- ✅ Particle effects
- ✅ UI polish

**Approval Criteria:** Game looks and sounds like final product

---

### Milestone 4: Feature Complete (End of Week 12)
- ✅ All 10 nights
- ✅ Letter fragment system
- ✅ All menus and UI
- ✅ Save system
- ✅ All features implemented

**Approval Criteria:** Every planned feature is in the game

---

### Milestone 5: Beta Complete (End of Week 14)
- ✅ Bug fixes
- ✅ Balancing adjustments
- ✅ Playtester feedback integrated
- ✅ Stable build

**Approval Criteria:** No critical bugs, positive feedback

---

### Milestone 6: Launch (End of Week 16)
- ✅ Public release on itch.io
- ✅ Marketing materials
- ✅ Platform builds
- ✅ Community engagement

**Approval Criteria:** Game is live and playable by public

---

## Testing Schedule

### Continuous Testing (Every Week)
- Developer playtests
- Smoke tests (build runs, no crashes)
- Core feature tests (movement, delivery, timer)

### Focused Testing

**Week 5:** First external playtest
- 2-3 trusted friends
- Test vertical slice
- Gather feel/fun feedback

**Week 8:** Second playtest
- 3-5 people
- Test 3 nights
- Gather difficulty feedback

**Week 11:** Alpha test
- 5-7 people
- Test all nights (as many as complete)
- Gather balance and bug feedback

**Week 14:** Beta test
- 10-15 people
- Full game playthrough
- Comprehensive feedback

**Week 15:** Final QA
- Developer-led full playthrough
- Platform-specific testing
- Edge case testing

---

## Asset Creation Pipeline

### Art Assets

**Weeks 1-6: Placeholder**
- Colored rectangles
- Simple shapes
- Focus on functionality

**Week 7: Player Sprites**
- Design character
- All animations
- Export and integrate

**Week 7: Tile Sets**
- Rooftop tiles
- Props (chimneys, vents)
- Background elements

**Week 10: Backgrounds**
- Parallax layers
- Skyline silhouettes
- Cloud sprites

**Week 11: UI Art**
- Menu backgrounds
- Button sprites
- Icons

### Audio Assets

**Weeks 1-7: Placeholder**
- Free SFX from freesound.org
- Royalty-free music

**Week 8: Music**
- Main theme
- Gameplay track
- Victory/failure music

**Week 8: SFX**
- Movement sounds
- Delivery sounds
- UI sounds
- Hazard sounds

**Week 12: Adaptive Music**
- Stems for layering
- Export and integrate

---

## Dependencies & Blockers

### Critical Path

```
Week 1-2 (Movement)
    ↓
Week 3-5 (Core Loop)
    ↓
Week 6 (Content Expansion)
    ↓
Week 7-8 (Art & Audio)
    ↓
Week 9-12 (Full Production)
    ↓
Week 13-14 (Testing)
    ↓
Week 15-16 (Launch)
```

### Potential Blockers

1. **Movement doesn't feel good** (Week 1-2)
   - **Impact:** Delays entire project
   - **Mitigation:** Extra iteration time, reference other games

2. **Art creation bottleneck** (Week 7)
   - **Impact:** Delays polish phase
   - **Mitigation:** Hire pixel artist, simplify art, extend timeline

3. **Technical bugs** (Week 13)
   - **Impact:** Delays launch
   - **Mitigation:** Continuous testing, version control, documentation

4. **Scope creep** (Any week)
   - **Impact:** Miss deadlines
   - **Mitigation:** Ruthless prioritization, weekly reviews

### External Dependencies

- **LÖVE Framework:** Stable, no risk
- **Libraries:** All open-source, stable
- **Pixel Artist:** If hired, coordinate schedule
- **Musician:** If hired, provide assets by Week 8
- **Playtesters:** Recruit early, confirm availability

---

## Post-Launch Plan

### Week 17+: Post-Launch Support

**First Week Post-Launch:**
- Monitor for critical bugs
- Release hotfix patches if needed
- Engage with community
- Collect feedback

**First Month:**
- Minor updates and bug fixes
- Quality-of-life improvements
- Community engagement

**3-6 Months:**
- Consider free content updates
- Endless mode (if cut)
- Photo mode (if cut)
- Additional nights
- Community-requested features

### Long-Term

- **DLC Consideration:** New cityscape, additional nights
- **Platform Expansion:** Steam release, consoles (stretch)
- **Community:** Build Discord, engage with speedrunners
- **Sequel/Spin-off:** If successful, consider "Courier Cat 2"

---

## Success Criteria

### Development Success
- ✅ Shipped on time (16 weeks)
- ✅ Shipped within scope (core features complete)
- ✅ Shipped with quality (minimal bugs, positive feedback)

### Commercial Success (Optional Goals)
- 🎯 100 downloads in first week
- 🎯 500 downloads in first month
- 🎯 Positive reviews (>80% positive)
- 🎯 Recoup development costs (if applicable)

### Personal Success
- ✅ Complete a game start to finish
- ✅ Learn LÖVE framework
- ✅ Build portfolio piece
- ✅ Have fun making it!

---

## Daily Workflow Recommendations

### Typical Development Day (4-6 hours)

**Hour 1: Review & Planning**
- Check previous day's progress
- Review today's tasks
- Prioritize work

**Hours 2-4: Development**
- Focused coding/asset creation
- Minimal distractions
- Frequent commits (version control)

**Hour 5: Testing**
- Playtest new features
- Document bugs
- Test edge cases

**Hour 6: Documentation**
- Update task list
- Write notes for tomorrow
- Push changes to repo

### Weekly Review (Friday)

- Review week's goals vs actual progress
- Adjust next week's plan if needed
- Playtest full build
- Celebrate wins!

---

## Tools & Resources

### Development Tools
- **IDE:** VS Code with Lua extension
- **Version Control:** Git + GitHub
- **Project Management:** Trello or Notion
- **Pixel Art:** Aseprite or GraphicsGale
- **Audio:** Audacity, FL Studio, Ableton (or free alternatives)
- **Level Design:** Tiled Map Editor (optional)

### Reference Games
- Celeste (movement feel)
- Super Meat Boy (tight controls)
- Night in the Woods (tone, aesthetic)
- Katana Zero (visual style)
- A Short Hike (cozy vibe)

### Community Resources
- LÖVE Discord
- /r/gamedev
- /r/pixelart
- TIGSource forums
- itch.io community

---

**End of Development Plan**

*Good luck, and remember: Ship it! A finished game is better than a perfect idea.*

🐾 **Happy developing!** 🐾
