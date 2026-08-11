# Pip's Times Tables

Multiplication practice for a seven-year-old, with a guinea pig to collect.
Plain HTML, JavaScript and CSS — no build step, no dependencies, no backend.

**Live:** https://andrewlord311-sudo.github.io/TimesTables/app/

## How it works

Seven stages, each cumulative: a new table is introduced and everything learned
so far keeps appearing, so earlier tables are rehearsed rather than abandoned.
Correct answers earn guinea pigs, which are the actual motivation.

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
