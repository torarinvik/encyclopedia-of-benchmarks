# Board Path

Count the ways to move from a start position to an end position by rolling a six-sided die. Each move advances by 1 through 6 positions. This ports the three equivalent source approaches in Java (`bpR`, `bpRS`, and `bpIS`) using a bounded tabulation implementation.

## Contract

Input is a signed 64-bit array `[start, end]`, with `0 <= start <= end <= 30`. The function returns the number of paths as a signed 64-bit scalar. Equal positions have one path. Malformed shape, out-of-range positions, or `start > end` returns -1. The largest valid result is 437,513,522, which fits the Java source's signed 32-bit result type.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm board_path --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/b/board_path/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/board_path.c`](../../../c/b/board_path.c) |
| C3 | [`c3/b/board_path.c3`](../../../c3/b/board_path.c3) |
| C++ | [`cpp/b/board_path.cpp`](../../../cpp/b/board_path.cpp) |
| Elisa | [`elisa/b/board_path.elisa`](../../../elisa/b/board_path.elisa) |
| Nim | [`nim/b/board_path.nim`](../../../nim/b/board_path.nim) |
| Odin | [`odin/b/board_path.odin`](../../../odin/b/board_path.odin) |
| Rust | [`rust/b/board_path.rs`](../../../rust/b/board_path.rs) |
| V | [`v/b/board_path.v`](../../../v/b/board_path.v) |
| Zig | [`zig/b/board_path.zig`](../../../zig/b/board_path.zig) |

## Pinned source

- Java [`BoardPath.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/BoardPath.java)
