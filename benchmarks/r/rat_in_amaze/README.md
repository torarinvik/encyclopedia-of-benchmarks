# Rat in a Maze (Java and JavaScript variants)

This package preserves two distinct contracts from the pinned Java and
JavaScript implementations. It is separate from [`rat_in_maze`](../rat_in_maze/README.md).

## Contract

The input is a signed-i64 array `[variant, n, cells...]`. Cells are row-major,
with `1` open and `0` blocked. `n` is in `1..4`, and the array must contain
exactly `2+n*n` words. Variants are:

| Variant | Source behavior |
|---:|---|
| `0` Java | Return every simple path in DFS order Down, Left, Right, Up. |
| `1` JavaScript | Return only the first simple path in DFS order Right, Down, Up, Left; no route is `false` / `solved=false`. |

Both start at `(0,0)` and target `(n-1,n-1)`. A path may not revisit a cell.
The input is restricted to binary cells; this is the JavaScript source's input
domain, and Java treats only `1` as open. A blocked start or goal has no route
in either variant. On an open 1×1 maze, both variants succeed with one empty
path string.

Successful output is a sequence of signed-i64 words serialized as
little-endian bytes: `[path_count, path_length, direction_codes..., ...]`.
Each path has its own length prefix. Direction codes are `D=0`, `L=1`, `R=2`,
`U=3`. Java writes all paths in its search order; JavaScript writes one path.
Thus an open 1×1 maze writes `[1,0]`. No route maps to `-3` and writes no
output, preserving the distinction between no path and a successful empty
path. Invalid input returns `-1`. A route with a null or short output buffer
returns `-2` without writes. Success returns the output byte count.

Dimensions up to 4×4 bound the output. The all-open 4×4 maze has 184 simple
paths with 1,912 total moves, so successful output is at most 2,097 words
(16,776 bytes). The maximum valid input is 18 words; 19 words are parseable so
trailing data can be rejected.

## Pinned sources

- Java [`RatInAMaze.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/backtracking/RatInAMaze.java), `findPaths`, commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.
- JavaScript [`RatInAMaze.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Backtracking/RatInAMaze.js), `RatInAMaze`, commit `5c39e87a9a31f279c60f830ad74a845e4788a517`.

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`benchmarks/rat_in_amaze_oracle.py`](../../rat_in_amaze_oracle.py)

## Language ports

| Language | Port |
|---|---|
| C | [`c/r/rat_in_amaze.c`](../../../c/r/rat_in_amaze.c) |
| C3 | [`c3/r/rat_in_amaze.c3`](../../../c3/r/rat_in_amaze.c3) |
| C++ | [`cpp/r/rat_in_amaze.cpp`](../../../cpp/r/rat_in_amaze.cpp) |
| Elisa | [`elisa/r/rat_in_amaze.elisa`](../../../elisa/r/rat_in_amaze.elisa) |
| Nim | [`nim/r/rat_in_amaze.nim`](../../../nim/r/rat_in_amaze.nim) |
| Odin | [`odin/r/rat_in_amaze.odin`](../../../odin/r/rat_in_amaze.odin) |
| Rust | [`rust/r/rat_in_amaze.rs`](../../../rust/r/rat_in_amaze.rs) |
| V | [`v/r/rat_in_amaze.v`](../../../v/r/rat_in_amaze.v) |
| Zig | [`zig/r/rat_in_amaze.zig`](../../../zig/r/rat_in_amaze.zig) |
