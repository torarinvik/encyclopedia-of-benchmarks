# Simulated annealing over a bounded 2D state space

This benchmark follows the pinned Python `simulated_annealing` loop with its `SearchProblem` state model. The callback is fixed to the source example `f(x,y) = x*x + y*y`. Random calls are replaced with explicit neighbor-list ranks and acceptance draws so each language receives the same decisions.

## Contract

Input is a signed 64-bit integer array:

`[x0,y0,step,min_x,max_x,min_y,max_y,find_max,start_temp_micro,rate_micro,threshold_temp_micro,selection_count,selection_indices...,acceptance_count,acceptance_micro...]`

Coordinates and bounds are integers in `[-16,16]`; the initial state must be inside the inclusive bounds. `step` is 1 through 4. `find_max` is 1 for maximize and 0 for minimize. The initial temperature is 1 through 10, the decrease rate is 0.1 through 0.5, and the threshold is 1 through less than the initial temperature; these three fields are micro-units divided by `1e6`.

At each outer iteration, record the current state as `best_state` when its score is greater than the previous best score. This comparison remains greater-than even when `find_max` is 0, preserving the source's minimization-mode behavior. Build the eight neighbors in `SearchProblem.get_neighbors()` order: `(-step,-step)`, `(-step,0)`, `(-step,+step)`, `(0,-step)`, `(0,+step)`, `(+step,-step)`, `(+step,0)`, `(+step,+step)`.

Each neighbor-selection draw is an index into the remaining neighbor list. Remove the selected neighbor before checking it, so a rejected or out-of-bounds neighbor cannot be selected again in that iteration. The score difference is computed before the bounds check, as in the source. Out-of-bounds neighbors are discarded without an acceptance draw. If `find_max` is 0, negate the score difference. Positive changes are accepted without a random draw; otherwise consume the next acceptance draw and accept when it is less than `e ** (change/current_temp)`.

After neighbor selection, update temperature as `current_temp = current_temp - current_temp*rate`. Stop when the updated temperature is below the threshold or when no neighbor was accepted. If the temperature crosses the threshold, do not adopt the just-selected neighbor; it becomes current only when another outer iteration will run. The bounds guarantee at most 22 outer iterations and at most 176 calls of either random kind. Missing draws, malformed framing, invalid bounds or parameters, an out-of-range list index, or an invalid acceptance level returns `-1`.

Neighbor indices are integers from 0 through 7 and must also be valid for the current remaining-list length. Acceptance draws are micro-units with the two levels 0 and 999,999. Those levels preserve the source's accept/reject decision across binary64 math libraries for this bounded score and temperature range. Valid unused stream suffixes have no effect; random calls after the source stops are not made. The input must contain exactly `13 + selection_count + acceptance_count` values; the maximum valid length is 365 and the maximum parseable length is 366.

The source returns a `SearchProblem` object. This ABI returns a reversible coordinate code for that object: `(best_x+16)*33 + (best_y+16)`. Decode with `x = code/33 - 16` and `y = code%33 - 16`. The code ranges from 0 through 1,088; `-1` is reserved for invalid or incomplete input streams.

The oracle is [`../../simulated_annealing_oracle.py`](../../simulated_annealing_oracle.py), and [`workload.json`](workload.json) lists the deterministic traces.

## Implementations

| Language | Path |
| --- | --- |
| C | [`c/s/simulated_annealing.c`](../../../c/s/simulated_annealing.c) |
| C3 | [`c3/s/simulated_annealing.c3`](../../../c3/s/simulated_annealing.c3) |
| C++ | [`cpp/s/simulated_annealing.cpp`](../../../cpp/s/simulated_annealing.cpp) |
| Elisa | [`elisa/s/simulated_annealing.elisa`](../../../elisa/s/simulated_annealing.elisa) |
| Nim | [`nim/s/simulated_annealing.nim`](../../../nim/s/simulated_annealing.nim) |
| Odin | [`odin/s/simulated_annealing.odin`](../../../odin/s/simulated_annealing.odin) |
| Rust | [`rust/s/simulated_annealing.rs`](../../../rust/s/simulated_annealing.rs) |
| V | [`v/s/simulated_annealing.v`](../../../v/s/simulated_annealing.v) |
| Zig | [`zig/s/simulated_annealing.zig`](../../../zig/s/simulated_annealing.zig) |

## Pinned sources

- Algorithm: Python [`simulated_annealing.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/searches/simulated_annealing.py).
- State dependency: Python [`hill_climbing.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/searches/hill_climbing.py), which defines `SearchProblem.score()` and the ordered eight-neighbor list.
