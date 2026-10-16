# N-Queens Solution Count

Count the valid placements of `n` queens on an `n × n` board. The ports use a column-by-column depth-first search with row and diagonal occupancy state, but return only the count, so source-specific board orientations and traversal order do not affect results. Each call starts with fresh state.

## Contract

The input is a one-element signed 64-bit array `[n]`, where `n` is from 0 through 8. The output is the signed 64-bit number of valid placements. The empty board at `n = 0` has one empty placement and returns 1. Values outside the range or an input length other than one return -1.

The bounded domain gives exact counts from 0 through 92 and avoids source-specific behavior for invalid sizes. Dart's pinned implementation stores its board globally, and Java uses static occupancy sets; each wrapper creates fresh occupancy state per call. Python prints its count instead of returning it, while Rust and Java return board arrangements; the benchmark projects these APIs to a scalar count. Haskell exposes a count function directly, and JavaScript tracks a count on its solver instance.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm n_queens_solution_count --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/n/n_queens_solution_count/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/n/n_queens_solution_count.c`](../../../c/n/n_queens_solution_count.c) |
| C3 | [`c3/n/n_queens_solution_count.c3`](../../../c3/n/n_queens_solution_count.c3) |
| C++ | [`cpp/n/n_queens_solution_count.cpp`](../../../cpp/n/n_queens_solution_count.cpp) |
| Elisa | [`elisa/n/n_queens_solution_count.elisa`](../../../elisa/n/n_queens_solution_count.elisa) |
| Nim | [`nim/n/n_queens_solution_count.nim`](../../../nim/n/n_queens_solution_count.nim) |
| Odin | [`odin/n/n_queens_solution_count.odin`](../../../odin/n/n_queens_solution_count.odin) |
| Rust | [`rust/n/n_queens_solution_count.rs`](../../../rust/n/n_queens_solution_count.rs) |
| V | [`v/n/n_queens_solution_count.v`](../../../v/n/n_queens_solution_count.v) |
| Zig | [`zig/n/n_queens_solution_count.zig`](../../../zig/n/n_queens_solution_count.zig) |

## Pinned sources

- Dart [`n-queen.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/backtracking/n-queen.dart)
- Haskell [`NQueens.hs`](https://github.com/TheAlgorithms/Haskell/blob/9dcabef99fb8995a760ff25a9e0d659114c0b9d3/src/Misc/NQueens.hs)
- Java [`NQueens.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/backtracking/NQueens.java)
- JavaScript [`NQueens.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Backtracking/NQueens.js)
- Python [`n_queens_math.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/backtracking/n_queens_math.py)
- Rust [`n_queens.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/backtracking/n_queens.rs)
