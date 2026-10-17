# Rat maze

This benchmark ports the pinned C++ `backtracking::rat_maze::solveMaze` search. It excludes the source self-test and its `main` function.

## Contract

- The ABI is `i32_array_bytes_output`. Input is `[n, n*n row-major cells...]` as signed-i32 words, with exactly `1 + n*n` words. `n` is 1–8; every cell is `0` (blocked) or `1` (open), and the top-left source cell must be open.
- The rat moves only right or down. At each cell the source recursively tries right first, then down. The first path reaching the bottom-right cell is the result. A failed search returns only `[0]`; a successful search returns `[1, path bits...]`, where the bits are the source's printed solution matrix flattened in row-major order. The source passes `soln` by value and prints that matrix only at the successful base case; the benchmark encodes that observable matrix as little-endian signed-i32 words. The one-cell open maze returns `[1, 1]`.
- Invalid, malformed, or null input returns `-1` before output-buffer checks. Valid input with a null output or insufficient capacity returns `-2` without writes. The maximum valid input is 65 words and the maximum output is 260 bytes.

The workload covers right-before-down choice, backtracking from a dead-end right branch, the pinned sample, no-path cases, maximum dimensions, malformed input, error precedence, and output capacity. See [workload.json](workload.json) and the independent [oracle](../../rat_maze_oracle.py).

Pinned source: [TheAlgorithms/C-Plus-Plus `rat_maze.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/backtracking/rat_maze.cpp), function `backtracking::rat_maze::solveMaze`, at commit `fdcc29b0ac2848e9d1a8d926e171cc5b39f97759`.

## Reproduce

~~~
python3 benchmarks/build_abi.py --family i32_array_bytes_output --algorithm rat_maze --language rust
python3 benchmarks/run_i32_array_bytes_output.py --build-manifest build/i32_array_bytes_output/r/rat_maze/rust/build.json
python3 benchmarks/verify_i32_array_bytes_output.py --algorithm rat_maze --languages rust
~~~

## Language ports

| Language | Source |
| --- | --- |
| C | [c/r/rat_maze.c](../../../c/r/rat_maze.c) |
| C3 | [c3/r/rat_maze.c3](../../../c3/r/rat_maze.c3) |
| C++ | [cpp/r/rat_maze.cpp](../../../cpp/r/rat_maze.cpp) |
| Elisa | [elisa/r/rat_maze.elisa](../../../elisa/r/rat_maze.elisa) |
| Nim | [nim/r/rat_maze.nim](../../../nim/r/rat_maze.nim) |
| Odin | [odin/r/rat_maze.odin](../../../odin/r/rat_maze.odin) |
| Rust | [rust/r/rat_maze.rs](../../../rust/r/rat_maze.rs) |
| V | [v/r/rat_maze.v](../../../v/r/rat_maze.v) |
| Zig | [zig/r/rat_maze.zig](../../../zig/r/rat_maze.zig) |
