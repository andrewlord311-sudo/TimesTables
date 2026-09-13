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

## The files

Everything is in `app/` — `index.html`, `app.js`, `style.css`, and the guinea
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
