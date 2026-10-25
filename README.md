# Pip's Times Tables

Multiplication practice for a seven-year-old, with a guinea pig to collect.
Plain HTML, JavaScript and CSS — no build step, no dependencies, no backend.

**Live:** https://andrewlord311-sudo.github.io/TimesTables/app/

## How it works

Seven stages, each cumulative: a new table is introduced and everything learned
so far keeps appearing, so earlier tables are rehearsed rather than abandoned.
Correct answers earn guinea pigs, which are the actual motivation.

**Answers are typed, not chosen.** The skill being practised is recall, and
three buttons only ever test recognition — she can get there by elimination,
with a 33% floor from guessing. The three choices are still one tap away
behind "Stuck?", so a new stage never becomes a wall; taking that help is
recorded, and the fact keeps coming back as though she had missed it.

**Questions are weighted towards what she finds hard.** Every fact keeps a
small record in `localStorage`, and how long a *correct* answer took is the
mastery signal — six seconds means she counted it up, one second means she
knows it. Missed facts come up roughly three times as often as average and
known ones about a third as often. There is no visible timer: a clock on the
screen mostly just makes children anxious, and the information is as good
collected quietly.

The stage row at the top of Feed Pip and the Jigsaw is the way back to any stage:
each button says which stage it is and the table it adds (a tick marks cleared
stages), and a line under it lists every table in the chosen stage. The last
stage chosen in each game is remembered in `localStorage` (`ttg_last_stage`).

Stage 1 and 2 unlock **Dreamy and Evie**, Clara's own guinea pigs, before the
invented ones — and stage 1's jigsaw is a real photo of her holding Evie.

"For grown-ups" on the home screen lists the facts still shaky, so someone
can see where she actually is without any of it becoming a scoreboard for her.

## Guinea Pig Run

The third game, and the only one pinned to Clara's actual Year 3 target:
**just the 2, 5 and 10 times tables, multipliers 1 to 12**, so 10 × 12 = 120 is
the largest thing she ever sees. Ten questions, never a repeat, split 4/3/3
across the three tables — which table gets the extra one is shuffled, so it is
not always the 2s. Products are kept distinct too, so one run never asks both
5 × 2 and 2 × 5.

Every correct answer hops Evie over the next obstacle towards the flag; a wrong
one makes her stumble, and the question comes round again.

**It is timed, and the clock is never on screen.** A visible timer turns
practice into a test and mostly makes children hurry and panic. The completion
screen says nothing about time at all — not even "a new best", which would
give the game away. Best and recent times appear only under "For grown-ups".

## Column Maths

Year 3 column addition and subtraction (`app/columns.js`). The sum is laid out
in columns (H T O, and Th at stage 7). Clara taps a space, types a digit, and
fills in the answer **and** the carry (addition: little boxes under the answer)
or the exchange (subtraction: a box above the top digit for what is left, and a
tiny box beside the digit for the extra 1 ten). **Check** marks each space;
the hint names the column to look at but never gives the digit, and after
three checks "Show me one step" fills one space. Seven stages: add with no
carry, one carry, two carries; subtract with no exchange, one, two; then
4-digit sums. 5 sums a session, 1-3 stars each (fewer checks, more stars).
A stage clears with 4 of 5 done and at most one "show me". The generator never
makes a zero in the middle that needs a chain exchange (not Year 3).

## Guinea Pig Garden (the rewards)

`app/garden.js`, a 3D world in Three.js r128 (loaded from cdnjs on first visit,
no model files: everything is built from shapes). Every game earns **stars**
(`addStars`, stored in `ttg_rewards`): 5 for finishing Feed, Jigsaw or Run, and
1-3 per column sum. Stars are spent in the garden on flowers, trees, a hutch,
pond, rainbow and more (`GARDEN_ITEMS`, saved in `ttg_garden`). "Tidy up"
gives the stars back, so nothing is a mistake. The guinea pigs she has
unlocked on the farm, plus Pip, wander in it; tap one and it squeaks. Drag to
turn the camera, scroll to zoom.

**Other worlds open as she gets better.** Four more islands float in the sky:
Beach Island, Snowy Mountain, Candy Land and the Moon. Each opens at a number
of stages cleared across all her games (`skillScore`: times-tables stages plus
Column Maths stages, 14 in all): Beach 7, Snowy 9, Candy 11, Moon all 14. A
locked island is grey, wrapped in cloud, and says how many more stages it
needs; when one opens, a rainbow bridge grows to it, and the finish screen of
the game that opened it says so (`newWorldMessage`). Tap an open island to go
there: each world has its own shop (palm trees and sandcastles, snowmen and
igloos, lollipops and cakes, rockets and UFOs) and keeps its own things. On the
Moon the guinea pigs jump very high.

## The files

Everything is in `app/` — `index.html`, `app.js`, `columns.js`, `garden.js`, `style.css`, and the guinea
pig SVGs with their idle, happy and sad animations.

`app.js` is a single file and is the source of truth for the stage progression
and the reward logic.

## Progress

Kept in the browser only, so it does not follow her between devices and is lost
if that browser's data is cleared. Fine for now; the first thing to change if it
becomes a daily habit.

## Sibling project

`PhonicsApp` is the same shape for a four-year-old learning letter sounds.
Changes worth making here are usually worth making there too.
