# Celebrity Finder

Find a person who is known by every other person and knows none of them. The implementation follows the pinned Java stack elimination and candidate verification algorithm.

## Contract

Input is a signed 64-bit array `[person_count, row-major knowledge matrix...]`. The matrix must contain exactly `person_count²` binary values, where cell `(i,j)` is 1 when person `i` knows `j`, otherwise 0. The bounded domain has 1 to 64 people. Diagonal cells are ignored. The function returns the zero-based celebrity index, or -1 if there is no celebrity. Malformed shape, person count, or nonbinary matrix values returns -2. A single person is a celebrity regardless of their diagonal cell, matching the source's verification loop.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm celebrity_finder --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/c/celebrity_finder/rust/build.json
```

## Verification

Check all nine ports against the independent direct-definition oracle with:

```sh
python3 benchmarks/verify_i64_array_scalar.py --algorithms celebrity_finder
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/celebrity_finder.c`](../../../c/c/celebrity_finder.c) |
| C3 | [`c3/c/celebrity_finder.c3`](../../../c3/c/celebrity_finder.c3) |
| C++ | [`cpp/c/celebrity_finder.cpp`](../../../cpp/c/celebrity_finder.cpp) |
| Elisa | [`elisa/c/celebrity_finder.elisa`](../../../elisa/c/celebrity_finder.elisa) |
| Nim | [`nim/c/celebrity_finder.nim`](../../../nim/c/celebrity_finder.nim) |
| Odin | [`odin/c/celebrity_finder.odin`](../../../odin/c/celebrity_finder.odin) |
| Rust | [`rust/c/celebrity_finder.rs`](../../../rust/c/celebrity_finder.rs) |
| V | [`v/c/celebrity_finder.v`](../../../v/c/celebrity_finder.v) |
| Zig | [`zig/c/celebrity_finder.zig`](../../../zig/c/celebrity_finder.zig) |

## Pinned source

- Java [`CelebrityFinder.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/stacks/CelebrityFinder.java)
