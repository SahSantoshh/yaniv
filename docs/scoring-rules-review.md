# Scoring rules review

Defaults used below unless a scenario says otherwise.

| Setting | Default |
| --- | --- |
| Target score | 124. The match ends when a total goes **above** this. 124 continues. 125 ends it. |
| Call score | 5. A caller above this is rejected and the round is not saved. |
| Halving | On. Totals that land exactly on 124 or 62 are cut in half, rounded up. |
| Winner half | On. A round winner's previous total is cut in half, rounded up. |
| Asaf | On. A failed call adds the penalty to the caller. |
| Tie penalty | On. An exact tie is a failed call. |
| Asaf penalty | 30 |
| Join penalty | 10, added to the current highest total |

Tests live in `test/scoring_rules_test.dart`. Every scenario below is asserted there.

Players are A, B, and C. **Caller** is the player who called Yaniv.

---

## 1. Call score

You can call only when your hand is less than or equal to the call score.

| Case | Input | Result | Test |
| --- | --- | --- | --- |
| Happy path | Call score 5, A calls with 5 | Round is saved | tested |
| Boundary | Call score 5, A calls with 0 | Round is saved | tested |
| Invalid | Call score 5, A calls with 6 | "Yaniv can only be called at 5 or below". Round is not saved | tested |
| Custom | Call score 7, A calls with 7 | Saved | tested |
| Custom invalid | Call score 7, A calls with 8 | Rejected | tested |
| Empty field | Call score left blank, or only spaces | Treated as 5. The match can start | tested |
| Negative | Call score -1 | Match does not start. "Call score cannot be negative" | tested |
| Boundary zero | Call score 0 | Match can start. Only a hand of 0 may call | tested |

---

## 2. Successful call

The caller has the lowest hand alone. Caller adds 0 and, with winner half on, their total is halved. Everyone else adds their hand.

**Tested.** A calls with 3. B has 8. C has 10.

| Player | Hand | Round score |
| --- | --- | --- |
| A, caller | 3 | 0 |
| B | 8 | 8 |
| C | 10 | 10 |

**Tested.** A alone has 0. Previous totals: A 40, B 20. A calls with 0, B has 4.

| Player | Was | Hand | Becomes |
| --- | --- | --- | --- |
| A, caller | 40 | 0 | 20 (halved) |
| B | 20 | 4 | 24 |

---

## 3. Asaf (someone has a lower hand)

The caller adds their hand plus the penalty. The lowest hand adds 0 and is the round winner. Other hands are added as entered.

**Tested.** Penalty 30. A calls with 5. B has 2. C has 9.

| Player | Hand | Round score |
| --- | --- | --- |
| A, caller | 5 | 35, marked as a penalty |
| B | 2 | 0, and is halved if winner half is on |
| C | 9 | 9 |

**Tested.** Two players share the lowest hand. Previous totals: A 10, B 40, C 20. A calls with 5. B has 2. C has 2. Winner half is on.

| Player | Was | Hand | Round score | Becomes |
| --- | --- | --- | --- | --- |
| A, caller | 10 | 5 | 35, penalty | 45 |
| B | 40 | 2 | 0 | 20 (halved) |
| C | 20 | 2 | 0 | 10 (halved) |

**Tested.** Custom penalty 20. A calls with 5, B has 1. A adds 25, not 35. B adds 0.

---

## 4. Tie penalty

On: a matching hand is a failed call. The caller is penalized. Each player on that lowest hand adds 0.

**Tested.** A calls with 4. B has 4. Penalty 30.

| Player | Hand | Round score |
| --- | --- | --- |
| A, caller | 4 | 34, penalty |
| B | 4 | 0 |

Off: the caller still wins. The caller adds 0. The tied player keeps their hand.

**Tested.** Tie penalty off. A calls with 4. B has 4.

| Player | Hand | Round score |
| --- | --- | --- |
| A, caller | 4 | 0 |
| B | 4 | 4 |

---

## 5. Caller has 0 and someone else also has 0

A called hand of 0 is never a penalty, even when someone else also has 0.

### Winner half on

Only the caller is halved. Every other 0 adds 0 and is not halved. Higher hands are added as entered.

**Tested.** Previous totals: A 40, B 20, C 10. A calls with 0. B has 0. C has 6.

| Player | Was | Hand | Becomes |
| --- | --- | --- | --- |
| A, caller | 40 | 0 | 20 (halved) |
| B | 20 | 0 | 20 (added 0, not halved) |
| C | 10 | 6 | 16 |

### Winner half off

Both players add 0. Tie penalty does not apply to a called 0.

**Tested.** Winner half off, tie penalty on. Previous totals: A 40, B 20. Both hands are 0.

| Player | Was | Hand | Becomes |
| --- | --- | --- | --- |
| A, caller | 40 | 0 | 40 |
| B | 20 | 0 | 20 |

**Tested.** Winner half off and tie penalty off. Both hands are 0.

| Player | Hand | Round score |
| --- | --- | --- |
| A, caller | 0 | 0 |
| B | 0 | 0 |

---

## 6. Asaf turned off

A round still has a caller. The lowest hand is the caller and adds 0. Everyone else adds their hand. If several players share that lowest hand, the round cannot be saved until someone picks which of them called. Only that caller is halved. The others on the same hand add 0.

**Tested.** Previous totals: A 40, B 20, C 10. Hands 4, 4, and 9. A is the caller.

| Player | Was | Hand | Becomes |
| --- | --- | --- | --- |
| A, caller | 40 | 4 | 20 (halved) |
| B | 20 | 4 | 20 (added 0, not halved) |
| C | 10 | 9 | 19 |

Saving this round with no caller is rejected. Picking C is rejected, because C does not have the lowest hand.

**Tested.** One lowest hand. A has 2, B has 8, C has 9. Previous totals 40, 20, and 10. A is the caller.

| Player | Was | Hand | Becomes |
| --- | --- | --- | --- |
| A, caller | 40 | 2 | 20 |
| B | 20 | 8 | 28 |
| C | 10 | 9 | 19 |

**Tested.** A and B both have 0, C has 6. Saving without a caller is rejected. Picking C is rejected because the caller must have 0. Picking B: A stays 40, B was 20 and becomes 10, C becomes 16.

**Tested.** Lowest hand is 7 and the call score is 5. The round is not saved.

---

## 7. Halving

Halving runs when a player's total after this round lands exactly on a threshold. The new total is that number cut in half, rounded up.

For target 124 the thresholds are 124, then 62. 31 is odd, so it is not a threshold. An odd target such as 125 has no thresholds.

| Case | Input | Result | Test |
| --- | --- | --- | --- |
| Happy path | A was 120, adds 4, target 124 | 124 is a threshold, so A becomes 62 | tested |
| Same round, no hit | B was 10, adds 1 | B becomes 11 | tested, same round as above |
| Rule off | A was 120, adds 4, halving off | A becomes 124 | tested |
| Odd target | Target 125 | No thresholds | tested |
| Boundary | A was 61, adds 1, target 124 | 62 is a threshold, so A becomes 31 | tested |
| Miss | A was 100, adds 10, target 124 | 110 is not a threshold, so A becomes 110 | tested |
| Custom target | Target 100. A was 90, adds 10 | Thresholds are 100, then 50. A becomes 50 | tested |

Winner half is turned off in the halving tests so a stored 0 does not also halve the total.

---

## 8. Winner half

A stored round score of 0 halves that player's previous total, rounded up. A score of 0 that is marked skip (the other player in the 0–0 call) does not.

| Case | Input | Result | Test |
| --- | --- | --- | --- |
| Happy path | Previous 40, round score 0 | 20 | tested, lone 0 call |
| Odd previous | Previous 41, round score 0 | 21 (41 / 2 rounded up) | tested |
| Already 0 | Previous 0, round score 0 | Stays 0 | tested |
| Not a winner | Round score 6 | 6 is added. No halving of the previous total | tested, player C in the 0–0 case |
| Rule off | Previous 40, round score 0, winner half off | 40 is kept, then 0 is added | tested, the half-off 0–0 case |

---

## 9. Joining penalty

A player who joins after round 1 starts from the highest total already on the board, plus the join penalty, plus the hand they enter this round.

**Tested.** A is on 40. B has not played. Join penalty is 10. This is round 2 (index 1). B enters 5. Winner half is off in this test.

| Player | Start | Hand | Becomes |
| --- | --- | --- | --- |
| A | 40 | 3 | 43 |
| B, joining | 40 + 10 | 5 | 55 |

Shown as `Join (40+10) + 5 = 55`.

**Tested.** On round 1, a player marked inactive is shown as `-` and gets no total.

**Tested.** B joins and wins while winner half is on. A is on 40 and adds 3. B's start is 40 + 10 = 50, then halved.

| Player | Becomes |
| --- | --- |
| A | 43 |
| B, joining winner | 25, shown as `~~50~~ 25` |

**Tested.** Join penalty 0. A is on 40 and adds 3. B enters 5. B starts from 40 alone and becomes 45. Shown as `Join (40+0) + 5 = 45`.

---

## 10. Target score

The match ends when any total is **greater than** the target. Equal to the target does not end it.

| Case | Totals | Target | Result | Test |
| --- | --- | --- | --- | --- |
| Happy path | Someone reaches 125 | 124 | Match over | tested |
| Boundary | Someone is on 124 | 124 | Match continues | tested |
| Custom | Someone is on 101 | 100 | Match over | tested |
| Empty | No rounds yet | 124 | Match continues | tested |
| Odd target | Target 125 on the setup screen | Match does not start. "Target Score must be an even number" | tested |
| Blank target | Target left blank | Treated as 124 | tested |
