# Knight Tour Open DFS

This package normalizes the pinned C++ and Rust backtracking implementations into one deterministic open-tour benchmark. It searches a fixed 8×8 board from square `(0, 0)`, trying moves in the shared source order `(2,1), (1,2), (-1,2), (-2,1), (-2,-1), (-1,-2), (1,-2), (2,-1)`. The source returns the first complete tour found by depth-first backtracking.

## Contract

Input is an empty signed 64-bit array. Any nonempty input is invalid and returns `-1`. The output is the 64 square IDs in visitation order, encoded as little-endian signed i64 values. A square ID is `row * 8 + column`; the first value is 0. Success returns 512 bytes. A null or undersized output buffer returns `-2` without writing.

The Python source uses a different move order, so this package follows the matching C++/Rust sequence for cross-language determinism. The pinned JavaScript `solve()` never marks its starting square as visited and therefore does not complete; that defective variant is documented but excluded from the output contract.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm knight_tour_open_dfs --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/k/knight_tour_open_dfs/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/k/knight_tour_open_dfs.c`](../../../c/k/knight_tour_open_dfs.c) |
| C3 | [`c3/k/knight_tour_open_dfs.c3`](../../../c3/k/knight_tour_open_dfs.c3) |
| C++ | [`cpp/k/knight_tour_open_dfs.cpp`](../../../cpp/k/knight_tour_open_dfs.cpp) |
| Elisa | [`elisa/k/knight_tour_open_dfs.elisa`](../../../elisa/k/knight_tour_open_dfs.elisa) |
| Nim | [`nim/k/knight_tour_open_dfs.nim`](../../../nim/k/knight_tour_open_dfs.nim) |
| Odin | [`odin/k/knight_tour_open_dfs.odin`](../../../odin/k/knight_tour_open_dfs.odin) |
| Rust | [`rust/k/knight_tour_open_dfs.rs`](../../../rust/k/knight_tour_open_dfs.rs) |
| V | [`v/k/knight_tour_open_dfs.v`](../../../v/k/knight_tour_open_dfs.v) |
| Zig | [`zig/k/knight_tour_open_dfs.zig`](../../../zig/k/knight_tour_open_dfs.zig) |

## Pinned sources

- C++ [`backtracking/knight_tour.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/backtracking/knight_tour.cpp)
- C++ mirror [`backtracking/knight_tour.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/backtracking/knight_tour.cpp)
- JavaScript [`Backtracking/KnightTour.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Backtracking/KnightTour.js)
- Python [`backtracking/knight_tour.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/backtracking/knight_tour.py)
- Rust [`src/backtracking/knight_tour.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/backtracking/knight_tour.rs)
