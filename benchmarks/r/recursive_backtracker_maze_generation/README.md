# Recursive-backtracker maze generation

This package constructs a perfect maze on a bounded rectangular cell grid by
depth-first traversal and backtracking. The generator starts at a supplied
cell, chooses among its unvisited neighbors, carves that passage, and pushes
the new cell. When no unvisited neighbor remains, it backtracks. The resulting
passage graph is a spanning tree, so every pair of cells has one path.

## Bounded contract

The `i64_array_bytes_output` input is
`[rows, columns, start_cell, draw_count, neighbor_ordinals...]`. Dimensions are
1 through 64 with at most 64 cells, and the start is a row-major cell index.
The deterministic choice tape has exactly `rows*columns-1` values. Each value
is 0 through 3 and, when consumed, must be smaller than the current number of
unvisited neighbors. Candidate order is north, east, south, west. The tape
replaces the random-choice source so every language replays the same walk.
An invalid frame or unavailable dynamic choice returns -1.

Output is one byte per row-major cell. Bits 0, 1, 2, and 3 represent north,
east, south, and west walls. A carved passage clears the corresponding bit in
both cells; outer boundary walls remain set. The maximum frame has 67 i64
words, the maximum parseable frame is 68 words, and output is at most 64
bytes. A null output or short capacity returns -2 without writing. Fixed
arrays account for 704 bytes on 64-bit targets; the declared native workspace
cap is 1,024 bytes to include scalar/index state and alignment, excluding
caller-owned input and output.

This is a construction algorithm, distinct from local maze solvers such as
[`rat_maze`](../../m/rat_maze/README.md) and
[`rat_in_maze`](../rat_in_maze/README.md), which search an already supplied
maze. It also differs from
[`wilson_uniform_spanning_tree`](../../w/wilson_uniform_spanning_tree/README.md):
Wilson's method uses loop-erased random walks, while this package uses a DFS
stack. Both produce spanning trees, but the traversal and induced distribution
are different. The supplied tape defines one deterministic trace; no claim of
uniform spanning-tree sampling is made.

## References and provenance

The RosettaGit [Maze generation task](https://rosettagit.org/tasks/maze-generation/)
was used as a discovery lead. The DFS/backtracking construction was checked
against Matej Gabrovsek's *Analysis of Maze Generating Algorithms*
([paper](https://ipsitransactions.org/journals/papers/tir/2019jan/p5.pdf)) and
the spanning-tree interpretation against the recursive-backtracker section
of [Ohio State's maze-generation thesis](https://etd.ohiolink.edu/acprod/odb_etd/ws/send_file/send?accession=osu1563286393237089&disposition=inline).
No task wording, published code, examples, or tests were copied. The contract,
choice tapes, references, fixtures, and ten ports were written for this bounded
benchmark. See [RIGHTS.md](RIGHTS.md) for the clean-room record.

## Workload and inventory

[`workload.json`](workload.json) pins singleton, one-row, two-by-two, maximum
cell-count/capacity, malformed-choice, null, and output-error cases.
[`verify_workload.py`](verify_workload.py) compares the iterative-stack
reference with a recursive passage-list reference and checks every pinned
result and byte string. [`check_inventory.py`](check_inventory.py) statically
checks the ten source paths and metadata; it does not execute native code.

| Language | Source |
|---|---|
| C | `c/r/recursive_backtracker_maze_generation.c` |
| C3 | `c3/r/recursive_backtracker_maze_generation.c3` |
| C++ | `cpp/r/recursive_backtracker_maze_generation.cpp` |
| Elisa | `elisa/r/recursive_backtracker_maze_generation.elisa` |
| Mojo | `mojo/r/recursive_backtracker_maze_generation.mojo` |
| Nim | `nim/r/recursive_backtracker_maze_generation.nim` |
| Odin | `odin/r/recursive_backtracker_maze_generation.odin` |
| Rust | `rust/r/recursive_backtracker_maze_generation.rs` |
| V | `v/r/recursive_backtracker_maze_generation.v` |
| Zig | `zig/r/recursive_backtracker_maze_generation.zig` |
