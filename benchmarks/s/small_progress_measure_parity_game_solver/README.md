# Small progress-measure parity-game solver

This package implements Jurdziński's small progress-measures algorithm for a
bounded finite parity game. It is distinct from
[`zielonka_parity_game_solver`](../../z/zielonka_parity_game_solver/README.md):
Zielonka recursively decomposes the arena with attractors, while this profile
monotonically lifts bounded rank tuples to the least progress-measure fixed
point.

## Contract

The exported `i64_array_scalar` function is
`small_progress_measure_parity_game_solver`. Its frame is
`[N,M,(owner,priority)*N,(from,to)*M]`.

- `1 <= N <= 8`; `N <= M <= 20`.
- Owner `0` is Even and owner `1` is Odd. Priorities are in `0..=5`.
- The directed graph is simple. Duplicate arcs are invalid, self-loops are
  allowed, and every vertex must have an outgoing arc.
- Minimum priority occurring infinitely often determines the winner. Even
  wins when that priority is even.
- The result is one signed 64-bit bitmask: bit `v` is set exactly when vertex
  `v` is Even-winning. Strategies are outside the output contract.
- A valid input has at most 58 words; a 59-word frame is parseable and rejected.
  Invalid frames return `-1`.

The bounded rank domain is `(r1,r3,r5)` in lexicographic order, followed by a
greatest value `TOP`. Each coordinate `rp` ranges from zero through the number
of vertices whose priority is exactly `p`. No priority compression is used.
For a successor measure, `Prog` keeps the odd-priority prefix through the
current vertex priority and clears its higher-priority suffix. At an odd
priority it advances to the least strictly greater prefix, carrying across
bounded coordinates as needed; overflow yields `TOP`. At an even priority it
keeps the prefix without incrementing. An already-`TOP` successor remains
`TOP`.

Even vertices lift toward the lexicographically least successor `Prog` value;
Odd vertices use the greatest. The new measure is the greater of the current
measure and that selected value. Vertices are lifted in ascending ID order in
repeated full sweeps until one sweep makes no change. This is a deterministic
fair lifting policy for the source's least fixed point. A vertex is
Even-winning exactly when its final measure is finite.

## References and relation to local benchmarks

The package follows Jurdziński, [“Small Progress Measures for Solving Parity
Games”](https://doi.org/10.1007/3-540-46541-3_24), STACS 2000, Sections 2–4:
the paper defines the bounded odd-priority measure domain, `Prog`, the owner
dependent `Lift`, and fixed-point procedure. The chapter context is Willemse
and Gazda, [“Parity Games,” *Encyclopedia of Algorithms*, Chapter
591](https://doi.org/10.1007/978-1-4939-2864-4_591). The independent reference
enumerates positional strategies and classifies their eventual cycles rather
than lifting progress measures.

This profile differs from `games_on_arbitrary_graphs`, which solves
normal-play positions, and from integer parity tests, which do not model
infinite games. It returns the same kind of winning-region bitmask as the
local Zielonka profile, but computes it with a materially different method.

## Bounds and package files

The fixed source workspace is at most 2 KiB. The package includes primary and
independent references, a bounded workload, rights and provenance notes, and
a static inventory reviewer. All ten language ports are listed in
[`INVENTORY.md`](INVENTORY.md). The workload is registered with the
`i64_array_scalar` runner and verifier.

No source code or protected text was reused. No programs, tests, scripts,
checkers, builds, compilers, profilers, or benchmarks were run while preparing
this package.
