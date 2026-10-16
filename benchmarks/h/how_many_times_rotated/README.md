# How many times rotated

Find the minimum element's index in an array that was formed by rotating a strictly increasing array to the left. For the source's distinct-value precondition, that index equals the number of rotations. An already sorted array returns 0, and an empty array also returns 0 as in the pinned Java method.

## Contract

- The `i64_array_scalar` input is the array values directly, without a count prefix. It contains 0 through 256 signed 32-bit integers.
- Nonempty arrays must contain distinct values and be a cyclic rotation of a strictly increasing array. This is the pinned source's precondition; the workload does not include arrays that violate it.
- A malformed length or a value outside the signed 32-bit range returns `-1`. The ports validate these ABI bounds before running the source's lower-bound binary search.
- The result is the index of the minimum value, in the range 0 through 255. For an empty array it is 0.
- The workload includes a 257-value malformed length so the one-over-bound input reaches the function and returns the invalid sentinel.

## Pinned source

The source is Java [`HowManyTimesRotated.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/searches/HowManyTimesRotated.java). It returns the index of the minimum by comparing the middle and high values until the search interval has one element. The independent oracle scans for the minimum over the promised input domain.

[`workload.json`](workload.json) covers the source examples, empty and singleton arrays, unrotated and small rotations, signed 32-bit boundaries, maximum length, and malformed ABI bounds.

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm how_many_times_rotated --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/h/how_many_times_rotated/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms how_many_times_rotated
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/how_many_times_rotated.c`](../../../c/h/how_many_times_rotated.c) |
| C3 | [`c3/h/how_many_times_rotated.c3`](../../../c3/h/how_many_times_rotated.c3) |
| C++ | [`cpp/h/how_many_times_rotated.cpp`](../../../cpp/h/how_many_times_rotated.cpp) |
| Elisa | [`elisa/h/how_many_times_rotated.elisa`](../../../elisa/h/how_many_times_rotated.elisa) |
| Nim | [`nim/h/how_many_times_rotated.nim`](../../../nim/h/how_many_times_rotated.nim) |
| Odin | [`odin/h/how_many_times_rotated.odin`](../../../odin/h/how_many_times_rotated.odin) |
| Rust | [`rust/h/how_many_times_rotated.rs`](../../../rust/h/how_many_times_rotated.rs) |
| V | [`v/h/how_many_times_rotated.v`](../../../v/h/how_many_times_rotated.v) |
| Zig | [`zig/h/how_many_times_rotated.zig`](../../../zig/h/how_many_times_rotated.zig) |
