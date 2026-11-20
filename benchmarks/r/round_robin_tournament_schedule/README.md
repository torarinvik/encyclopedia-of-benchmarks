# Round-robin tournament schedule

This package generates the canonical single round-robin opponent table using
the circle method (also called the clock method). Each unordered pair of teams
appears exactly once, and every round is a matching. For an odd team count, a
dummy team is added and its match is omitted as a bye.

## Contract

- ABI: `i64_array_bytes_output`, symbol `round_robin_tournament_schedule`.
- Input is exactly `[team_count]`, where `2 <= team_count <= 8`. The maximum
  valid and parseable frame lengths are 1 and 2 i64 words; an extra word is
  malformed.
- Output bytes are `[team_count, round_count, opponents...]`. The opponent
  matrix is row-major by team ID, then round. Team IDs are unsigned bytes;
  `0xff` marks a bye. Odd team counts are padded with a dummy pivot, whose
  pairings are omitted.
- The canonical order is fixed: rounds increase from zero; in each round the
  pivot is paired with the ring position for that round, then ring offsets are
  visited from one upward. The table stores the reciprocal opponent for both
  teams.
- Malformed input returns `-1` before output validation. A null output or
  insufficient capacity returns `-2`, with no bytes written. Maximum output is
  58 bytes; native scratch is capped at 128 bytes.

The primary reference writes pairings from modular ring coordinates. The
independent reference rotates an explicit ring list and pairs opposite
positions. Both take O(n²) time and use O(n²) workspace for the bounded
opponent matrix.

## Source and duplicate review

RosettaCodeData's pinned popular-title index lists **Round-robin tournament
schedule** at score 30 in revision
[`1d475861d7141ef2fafff293d9339f56e4b0f5db`](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks).
The title is used only for discovery. The formula follows Algorithm 1 (Circle
method) in Ribeiro et al., [“A tutorial on graph models for scheduling
round-robin sports tournaments”](https://doi.org/10.1111/itor.13290); its
odd-team dummy construction is also cross-checked against Boschetti and
Righini's [clock-method description](https://doi.org/10.1287/ited.2022.0269).

The local [`round_robin`](../round_robin/README.md) benchmark schedules CPU
jobs with a fixed time quantum. [`tournament_sort`](../../t/tournament_sort/README.md)
sorts values by tournament selection. Neither creates a tournament's
one-factorization or opponent table, so this schedule-generation operation is
distinct.

See [`TITLE_AUDIT.md`](TITLE_AUDIT.md) for the score 31–29 title-only screen.
No Rosetta task text, examples, tests, submissions, source code, paper prose,
figures, or tables are reused. Shared suite and catalog registration remain
root-owned.

## Files

- [`workload.json`](workload.json) pins even and odd schedules, bye markers,
  maximum output, capacity errors, and malformed frames.
- [`primary_oracle.py`](primary_oracle.py) and
  [`independent_oracle.py`](independent_oracle.py) specify distinct
  constructions.
- [`RIGHTS.md`](RIGHTS.md), [`INVENTORY.md`](INVENTORY.md),
  [`INVENTORY.json`](INVENTORY.json), and the package-local static helpers
  record provenance and source coverage.

| Language | Source |
| --- | --- |
| C | [`c/r/round_robin_tournament_schedule.c`](../../../c/r/round_robin_tournament_schedule.c) |
| C3 | [`c3/r/round_robin_tournament_schedule.c3`](../../../c3/r/round_robin_tournament_schedule.c3) |
| C++ | [`cpp/r/round_robin_tournament_schedule.cpp`](../../../cpp/r/round_robin_tournament_schedule.cpp) |
| Elisa | [`elisa/r/round_robin_tournament_schedule.elisa`](../../../elisa/r/round_robin_tournament_schedule.elisa) |
| Mojo | [`mojo/r/round_robin_tournament_schedule.mojo`](../../../mojo/r/round_robin_tournament_schedule.mojo) |
| Nim | [`nim/r/round_robin_tournament_schedule.nim`](../../../nim/r/round_robin_tournament_schedule.nim) |
| Odin | [`odin/r/round_robin_tournament_schedule.odin`](../../../odin/r/round_robin_tournament_schedule.odin) |
| Rust | [`rust/r/round_robin_tournament_schedule.rs`](../../../rust/r/round_robin_tournament_schedule.rs) |
| V | [`v/r/round_robin_tournament_schedule.v`](../../../v/r/round_robin_tournament_schedule.v) |
| Zig | [`zig/r/round_robin_tournament_schedule.zig`](../../../zig/r/round_robin_tournament_schedule.zig) |
