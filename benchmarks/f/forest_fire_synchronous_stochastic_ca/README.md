# Synchronous stochastic forest-fire automaton

This package measures a bounded, deterministic replay of a three-state forest-fire cellular automaton. Each step reads one complete old generation and writes one complete new generation. Growth and lightning decisions come from supplied integer draw tapes, so every language receives identical random decisions.

## Contract

The `i64_array_bytes_output` input is
`[rows,cols,steps,10000,growth_threshold,lightning_threshold,board,growth_draws,lightning_draws]`.
Require `1<=rows,cols<=8`, `0<=steps<=8`, thresholds in `0..10000`, board states `0=empty`, `1=tree`, `2=burning`, and all draw values in `0..9999`. Every cell in the outermost row or column must be empty in the initial board. The exact length is `6 + rows*cols + 2*steps*rows*cols`; the maximum valid and parseable frames are 1094 and 1095 words. Each draw tape is step-major, then row-major, and contains one draw for every cell at every step, even if a cell's current state does not use that draw.

For each generation, outermost row and column sites remain empty. An interior burning site becomes empty. An interior tree with any burning site among its eight surrounding Moore neighbors becomes burning; otherwise it ignites when its lightning draw is below the lightning threshold. An interior empty site grows a tree when its growth draw is below the growth threshold. All transitions use only the preceding board. The grid is rectangular, does not wrap, and cells outside its edge are empty. A one-row or one-column board consists entirely of fixed empty cells.

Output is little-endian signed-i64 words `[steps,(empty_count,tree_count,burning_count)*steps,final_board_row_major]`. Its maximum is 89 words / 712 bytes. Invalid input, including a null input, returns `-1`. Null output and short capacity return `-2`; input validation precedes output checks, and errors write no bytes. The largest fixed scratch is the two 64-byte state buffers plus a three-entry i64 count buffer (152 bytes), within the declared 192-byte workspace limit. Caller-owned input and output buffers are excluded.

## References and distinction

RosettaGit's [Forest fire task](https://rosettagit.org/tasks/forest-fire/) supplied the task discovery and the selected Moore-neighborhood variant with permanently empty outermost cells. The model's three states, parallel updates, tree-growth probability, spontaneous lightning probability, and spreading ignition are cross-checked against Drossel and Schwabl's 1992 [Self-organized critical forest-fire model](https://doi.org/10.1103/PhysRevLett.69.1629) and their [general stochastic model](https://arxiv.org/abs/cond-mat/9310059). The benchmark pins this task variant's Moore neighborhood and fixed empty boundary behavior rather than claiming to reproduce every boundary or neighborhood variant in the literature.

The local [`game_of_life`](../../g/game_of_life/README.md) profile is a deterministic binary B3/S23 transition. [`one_dimensional`](../../o/one_dimensional/README.md) is a one-dimensional elementary rule, and [`abelian_sandpile_stabilization`](../../a/abelian_sandpile_stabilization/README.md) is a chip-firing stabilization process. [Brownian-tree DLA](../../b/brownian_tree_diffusion_limited_aggregation/README.md) attaches random walkers to an aggregate. None performs this three-state growth, ignition, and burn-out transition.

The primary reference scans each cell and checks its neighborhood directly. The independent reference first spreads a burning-neighbor mask from burning sites, then applies state rules. Both references use the same specified transition and deterministic tapes but different neighborhood work. The workload pins manually derived small transitions and error cases; [`verify_workload.py`](verify_workload.py) compares both references with every pinned result and byte string. The package includes ten native ports and a source-path inventory.

## Language ports

| Language | Source |
|---|---|
| C | [forest_fire_synchronous_stochastic_ca.c](../../../c/f/forest_fire_synchronous_stochastic_ca.c) |
| C3 | [forest_fire_synchronous_stochastic_ca.c3](../../../c3/f/forest_fire_synchronous_stochastic_ca.c3) |
| C++ | [forest_fire_synchronous_stochastic_ca.cpp](../../../cpp/f/forest_fire_synchronous_stochastic_ca.cpp) |
| Elisa | [forest_fire_synchronous_stochastic_ca.elisa](../../../elisa/f/forest_fire_synchronous_stochastic_ca.elisa) |
| Mojo | [forest_fire_synchronous_stochastic_ca.mojo](../../../mojo/f/forest_fire_synchronous_stochastic_ca.mojo) |
| Nim | [forest_fire_synchronous_stochastic_ca.nim](../../../nim/f/forest_fire_synchronous_stochastic_ca.nim) |
| Odin | [forest_fire_synchronous_stochastic_ca.odin](../../../odin/f/forest_fire_synchronous_stochastic_ca.odin) |
| Rust | [forest_fire_synchronous_stochastic_ca.rs](../../../rust/f/forest_fire_synchronous_stochastic_ca.rs) |
| V | [forest_fire_synchronous_stochastic_ca.v](../../../v/f/forest_fire_synchronous_stochastic_ca.v) |
| Zig | [forest_fire_synchronous_stochastic_ca.zig](../../../zig/f/forest_fire_synchronous_stochastic_ca.zig) |

See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), and [`INVENTORY.md`](INVENTORY.md). Source files and fixture inputs are clean-room; no task source code, wording, tests, or example outputs were copied. No programs, tests, scripts, helpers, checkers, builds, compilers, profilers, or benchmarks have been run.
