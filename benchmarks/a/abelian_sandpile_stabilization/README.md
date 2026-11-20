# Abelian sandpile stabilization

This bounded scalar benchmark stabilizes a dissipative Abelian sandpile on a
small rectangular square grid. It is distinct from cellular automata such as
[`game_of_life`](../../g/game_of_life/README.md): the state is an integer grain
height, every legal toppling conserves grains except those sent to the sink,
and the output is the unique stable configuration.

## Contract

The ABI is `int64_t abelian_sandpile_stabilization(const int64_t *input,
size_t length)`. Input is `[rows,cols,cells row-major...]`, with `1<=rows,cols<=4`,
each initial height in `0..31`, and exact length `2+rows*cols`. Valid frames
contain 3 to 18 words; a 19-word frame is parseable and rejected as trailing
input. Null, malformed, or out-of-range input returns `-1`.

Each site topples at threshold four. A topple removes four grains and sends one
grain to each in-bounds orthogonal neighbor. Grains sent toward missing
neighbors leave the system through the sink. The result packs the stable
row-major heights in base four, with the first cell in the least-significant
digit: `sum(stable[i]*4^i)`. Stable heights are 0 through 3, so the result is
in `0..4^16-1 = 4,294,967,295`.

The primary uses a row-major FIFO of unstable sites, toppling one grain batch
at a time and adding newly unstable sites in fixed north, east, south, west
order. A queued flag prevents duplicates. The independent reference uses
synchronous rounds: each round computes `floor(height/4)` topplings from the
old board, places remainders on the next board, and accumulates all in-bounds
transfers. The Abelian property makes both legal schedules reach the same
stable board.

For one-based coordinates, `phi(x,y)=x*(cols+1-x)/2+y*(rows+1-y)/2` is
nonnegative and at most six per grain on this domain. The discrete grid
Laplacian gives a decrease of two for each legal single-site topple. With at
most 16*31 initial grains, stabilization therefore uses at most 1488
topplings. Each synchronous nonterminal round contains at least one topple,
so it also uses at most 1488 rounds. The primary takes `O(V+T)` time and `O(V)`
space; the independent reference takes `O(V*R+T)` time and `O(V)` space, where
`V<=16`, `T<=1488`, and `R<=1488`.

The hand-derived cascade fixture `[2,2,31,0,0,0]` stabilizes to
`[3,1,1,0]`, encoded as 23. The two-corner fixture `[2,2,8,0,0,0]` becomes
`[0,2,2,0]`, encoded as 40. The workload also covers sink dissipation,
maximum frame and packed-result bounds, malformed lengths, invalid heights,
null input, and signed-i64 boundaries.

## Provenance and rights

The algorithm idea is grounded in Deepak Dhar, “Self-Organized Critical State
of Sandpile Automaton Models,” *Physical Review Letters* 64(14), 1613–1616
(1990), [author-hosted paper](https://repository.ias.ac.in/9280/1/311.pdf).
The [RosettaGit task title](https://rosettagit.org/tasks/abelian-sandpile-model/)
was used only for discovery. The package specializes the general toppling
matrix model to an open-boundary rectangular square grid. No task prose,
examples, tests, or implementation code was copied; all ports, references, and
fixtures were authored for this repository. See [RIGHTS.md](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [abelian_sandpile_stabilization.c](../../../c/a/abelian_sandpile_stabilization.c) |
| C3 | [abelian_sandpile_stabilization.c3](../../../c3/a/abelian_sandpile_stabilization.c3) |
| C++ | [abelian_sandpile_stabilization.cpp](../../../cpp/a/abelian_sandpile_stabilization.cpp) |
| Elisa | [abelian_sandpile_stabilization.elisa](../../../elisa/a/abelian_sandpile_stabilization.elisa) |
| Mojo | [abelian_sandpile_stabilization.mojo](../../../mojo/a/abelian_sandpile_stabilization.mojo) |
| Nim | [abelian_sandpile_stabilization.nim](../../../nim/a/abelian_sandpile_stabilization.nim) |
| Odin | [abelian_sandpile_stabilization.odin](../../../odin/a/abelian_sandpile_stabilization.odin) |
| Rust | [abelian_sandpile_stabilization.rs](../../../rust/a/abelian_sandpile_stabilization.rs) |
| V | [abelian_sandpile_stabilization.v](../../../v/a/abelian_sandpile_stabilization.v) |
| Zig | [abelian_sandpile_stabilization.zig](../../../zig/a/abelian_sandpile_stabilization.zig) |

`check_inventory.py` exposes `static_issues()` and `verify_workload.py`
exposes `verify()`. They are supplied for later static verification; they are
not run during this drafting task.
