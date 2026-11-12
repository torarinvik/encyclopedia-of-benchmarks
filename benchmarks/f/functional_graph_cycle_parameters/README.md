# Functional graph cycle parameters

Given a finite successor map and a start node, report how many steps occur
before reaching the eventual cycle (`mu`) and how many nodes that cycle has
(`lambda`). This is the constant-space tortoise-and-hare cycle-finding method
applied to an explicit finite function table.

## Contract

The exported scalar ABI symbol is `functional_graph_cycle_parameters`. Input
is `[N,start,next[0],...,next[N-1]]`, with `1<=N<=64` and every node ID in
`0..N-1`. The exact input length is `N+2`; one extra trailing word is admitted
by the parser bound to exercise malformed framing. The scalar result encodes
both parameters as `65*mu+lambda`. Since `mu+lambda<=N<=64`, quotient and
remainder by 65 recover the pair without ambiguity. Null, malformed, or
out-of-range input returns `-1`.

The maximum valid input has 66 signed 64-bit words, the maximum parseable
framing probe has 67 words, and the largest valid result is 4096.

## Algorithms

The primary advances a tortoise by one successor and a hare by two until they
meet. Resetting one pointer to the start and advancing both by one finds the
cycle entry and thus `mu`. One further lap measures `lambda`. It uses `O(N)`
time and `O(1)` extra space.

The independent oracle follows the successor sequence while storing each
node's first visit step. On the first repeated node, the saved step is `mu` and
the step difference is `lambda`. This uses `O(N)` time and `O(N)` extra space.

## Distinctness and provenance

`floyd_warshall` solves all-pairs shortest paths, and
`negative_cycle_detection` checks weighted graph cycles by relaxation. Neither
recovers the tail and period of one deterministic successor trajectory. The
source is [CP-Algorithms, “Tortoise and Hare Algorithm”](https://cp-algorithms.com/others/tortoise_and_hare.html),
licensed under CC BY-SA 4.0; this package uses the algorithm description only.
See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), the primary and
independent oracle modules, and the static checker
[`check_functional_graph_cycle_parameters_package.py`](../../check_functional_graph_cycle_parameters_package.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/f/functional_graph_cycle_parameters.c`](../../../c/f/functional_graph_cycle_parameters.c) |
| C3 | [`c3/f/functional_graph_cycle_parameters.c3`](../../../c3/f/functional_graph_cycle_parameters.c3) |
| C++ | [`cpp/f/functional_graph_cycle_parameters.cpp`](../../../cpp/f/functional_graph_cycle_parameters.cpp) |
| Elisa | [`elisa/f/functional_graph_cycle_parameters.elisa`](../../../elisa/f/functional_graph_cycle_parameters.elisa) |
| Mojo | [`mojo/f/functional_graph_cycle_parameters.mojo`](../../../mojo/f/functional_graph_cycle_parameters.mojo) |
| Nim | [`nim/f/functional_graph_cycle_parameters.nim`](../../../nim/f/functional_graph_cycle_parameters.nim) |
| Odin | [`odin/f/functional_graph_cycle_parameters.odin`](../../../odin/f/functional_graph_cycle_parameters.odin) |
| Rust | [`rust/f/functional_graph_cycle_parameters.rs`](../../../rust/f/functional_graph_cycle_parameters.rs) |
| V | [`v/f/functional_graph_cycle_parameters.v`](../../../v/f/functional_graph_cycle_parameters.v) |
| Zig | [`zig/f/functional_graph_cycle_parameters.zig`](../../../zig/f/functional_graph_cycle_parameters.zig) |
