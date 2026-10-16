# Knights Tour Warnsdorff Open

This package ports the pinned Java Warnsdorff-style open tour. It searches a fixed 8×8 board from `(0, 0)`, visits the lowest-onward-degree legal square first, preserves the source move order for ties, and prunes a move when it leaves an unvisited neighbor with no onward move. The tour is open; it does not need to return to its starting square.

## Contract

Input is an empty signed 64-bit array. Nonempty input returns `-1`. Output is the 64 square IDs in visitation order as little-endian signed i64 values, where each ID is `row * 8 + column`. Success returns 512 bytes. A null or undersized output buffer returns `-2` without writing.

The Java source uses a 12×12 padded board with an 8×8 active region. These ports use direct 8×8 bounds while preserving its ordered moves, stable tie sort, orphan check, and resulting tour.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm knights_tour_warnsdorff_open --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/k/knights_tour_warnsdorff_open/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/k/knights_tour_warnsdorff_open.c`](../../../c/k/knights_tour_warnsdorff_open.c) |
| C3 | [`c3/k/knights_tour_warnsdorff_open.c3`](../../../c3/k/knights_tour_warnsdorff_open.c3) |
| C++ | [`cpp/k/knights_tour_warnsdorff_open.cpp`](../../../cpp/k/knights_tour_warnsdorff_open.cpp) |
| Elisa | [`elisa/k/knights_tour_warnsdorff_open.elisa`](../../../elisa/k/knights_tour_warnsdorff_open.elisa) |
| Nim | [`nim/k/knights_tour_warnsdorff_open.nim`](../../../nim/k/knights_tour_warnsdorff_open.nim) |
| Odin | [`odin/k/knights_tour_warnsdorff_open.odin`](../../../odin/k/knights_tour_warnsdorff_open.odin) |
| Rust | [`rust/k/knights_tour_warnsdorff_open.rs`](../../../rust/k/knights_tour_warnsdorff_open.rs) |
| V | [`v/k/knights_tour_warnsdorff_open.v`](../../../v/k/knights_tour_warnsdorff_open.v) |
| Zig | [`zig/k/knights_tour_warnsdorff_open.zig`](../../../zig/k/knights_tour_warnsdorff_open.zig) |

## Pinned source

- Java [`KnightsTour.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/backtracking/KnightsTour.java)
