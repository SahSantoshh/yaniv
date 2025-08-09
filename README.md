# Yaniv Score Tracker Flutter App

## Purpose

A Flutter app to track scores of the Yaniv card game. Focuses on score tracking, not card dealing.

## Features

- Add any number of players with custom names.
- Configurable game end score (default 124).
- Halving Rule (configurable):
  - After adding a round’s score, if a player’s **new total score** is exactly 62 or 124,
    then the round score is halved.
  - UI shows original score with strikethrough plus the halved score.
- Winner Halves Previous Total Rule (configurable):
  - The player with the lowest round score (winner) sets their total for that round
    to half their previous total score (instead of adding current round score).
  - UI shows winner’s round score as "~~0~~ newScore" with 0 struck through.
- Scoreboard with round-by-round scores and total scores.
- Winner’s round score highlighted in yellow.
- Game ends when any player’s total score exceeds the end score.
- Winner is the player with the lowest total score at game end.
- Restart option after game ends.

## Screens

### Setup Screen

- Add player name inputs (add unlimited players).
- Set end score.
- Toggle Halving Rule and Winner halves previous total rule.
- Start Game button.

### Game Screen

- Table showing round-wise scores and totals.
- Scores with halving rule show original struck through and halved score next to it.
- Winner score cell highlighted.
- Add Round Scores button opens dialog to input scores.
- Game over dialog appears when any player exceeds end score.

### Add Round Scores Dialog

- Input scores for each player.
- Save or Cancel buttons.

## Rules Summary

- Totals are cumulative sums of round scores except:
  - If after adding a round, the new total is exactly 62 or 124 and halving rule is on,
    that round’s score is halved and displayed accordingly.
  - Winner halves previous total rule overrides winner’s total to half their previous total score.
- Lowest total score player at game end is winner.

## Visual Style

- Clean UI with readable fonts.
- Strike-through for halved scores.
- Yellow highlight for round winners.
- Horizontal scrolling for many players.
