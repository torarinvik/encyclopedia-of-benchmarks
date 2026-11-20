# Zielonka parity-game solver

This package implements the recursive parity-game solver shown as Algorithm 1
in Chapter 591 of the *Encyclopedia of Algorithms*. It repeatedly selects the
minimum priority in the current subgame, computes the attractor of the player
whose parity matches that priority, and solves the remaining subgame. If the
opponent wins any remaining vertex, it computes the opponent's attractor and
recurses again outside that region.

## Contract

The exported scalar ABI is `i64_array_scalar`, with symbol
`zielonka_parity_game_solver`. The input frame is
`[N,M,(owner,priority)*N,(from,to)*M]`.

- `1<=N<=8` and `N<=M<=20`.
- Owner `0` means Even; owner `1` means Odd. Priorities are integers in
  `[0,5]`.
- The directed arena is simple: repeated arcs are invalid. Every vertex must
  have at least one outgoing edge, so every play is infinite.
- The convention follows the cited chapter: the **minimum** priority occurring
  infinitely often determines the winner. Even wins an even minimum, Odd an
  odd minimum. The minimum-versus-maximum fixture distinguishes this convention.
- The result is the bitmask of vertices won by Even; the Odd region is its
  complement within the `N` vertices. Strategies are excluded because the
  benchmark targets Algorithm 1's winning partition.
- Maximum valid input length is 58 words. One trailing word, making length 59,
  is parseable and rejected. Invalid frames return `-1`.

The primary reference follows the recursive attractor decomposition. The
independent reference enumerates positional strategies for both players and
classifies the eventual cycle under each strategy pair; this brute-force oracle
is practical under the eight-vertex, twenty-edge bound. Workload fixtures cover
even and odd self-loops, the parity convention, opponent-owned universal
attractor growth, Zielonka's second recursive branch, the maximum frame, and
invalid framing, owner, priority, edge, and endpoint fields.

## Sources and overlap

The profile follows Tim A. C. Willemse and Maciej Gazda, [“Parity Games,”
*Encyclopedia of Algorithms*, Chapter 591](https://doi.org/10.1007/978-1-4939-2864-4_591),
in particular its recursive Algorithm 1. The chapter attributes the
constructive recursion to McNaughton and Zielonka; the primary reference is
Robert McNaughton's [“Infinite Games Played on Finite Graphs”](https://doi.org/10.1016/0168-0072(93)90036-D).
The ports are clean-room implementations of those algorithm descriptions.

This is distinct from [`games_on_arbitrary_graphs`](../../g/games_on_arbitrary_graphs/README.md),
which solves normal-play graph positions and permits draws. It is also distinct
from the repository's integer parity classifiers, which do not solve two-player
infinite games.

## Language ports

| Language | Source |
|---|---|
| C | [`c/z/zielonka_parity_game_solver.c`](../../../c/z/zielonka_parity_game_solver.c) |
| C3 | [`c3/z/zielonka_parity_game_solver.c3`](../../../c3/z/zielonka_parity_game_solver.c3) |
| C++ | [`cpp/z/zielonka_parity_game_solver.cpp`](../../../cpp/z/zielonka_parity_game_solver.cpp) |
| Elisa | [`elisa/z/zielonka_parity_game_solver.elisa`](../../../elisa/z/zielonka_parity_game_solver.elisa) |
| Mojo | [`mojo/z/zielonka_parity_game_solver.mojo`](../../../mojo/z/zielonka_parity_game_solver.mojo) |
| Nim | [`nim/z/zielonka_parity_game_solver.nim`](../../../nim/z/zielonka_parity_game_solver.nim) |
| Odin | [`odin/z/zielonka_parity_game_solver.odin`](../../../odin/z/zielonka_parity_game_solver.odin) |
| Rust | [`rust/z/zielonka_parity_game_solver.rs`](../../../rust/z/zielonka_parity_game_solver.rs) |
| V | [`v/z/zielonka_parity_game_solver.v`](../../../v/z/zielonka_parity_game_solver.v) |
| Zig | [`zig/z/zielonka_parity_game_solver.zig`](../../../zig/z/zielonka_parity_game_solver.zig) |

No programs, tests, scripts, checkers, builds, compilers, profilers, or
benchmarks were run while preparing this package.
