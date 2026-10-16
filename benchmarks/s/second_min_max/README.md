# Second minimum and maximum

This benchmark ports TheAlgorithms/Java's `SecondMinMax.findSecondMin` and `findSecondMax` methods. A one-pass scan tracks the best value and the next distinct value. Operation `0` returns the second-smallest distinct value; operation `1` returns the second-largest distinct value.

## Contract

- The `i64_array_scalar` input is `[operation, n, values...]`. `operation` is `0` for second minimum or `1` for second maximum. `n` is in `2..=256`, the packed length is exactly `n + 2`, and every array value is a signed 32-bit integer.
- Equal copies of the best value do not count as the second value. The scan follows the source's input order and strict comparisons.
- The pinned Java methods throw for arrays shorter than two, arrays without two distinct values, and cases where the true second result collides with the method's `Integer.MAX_VALUE`/`Integer.MIN_VALUE` sentinel. This bounded ABI represents those cases with `INT64_MIN`.
- The maximum parseable input length is 259 slots so an over-limit count can reach the ABI; the maximum valid input is 258 slots.

## Pinned source

- Java [`SecondMinMax.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/SecondMinMax.java)

The JavaScript [`find_second_largest_element`](../../f/find_second_largest_element/README.md) benchmark returns the same second-largest-distinct value for its own source. This package also covers the source's second-minimum operation and preserves Java's one-pass scan and sentinel behavior.

[`workload.json`](workload.json) covers both modes, duplicates, ascending/descending input, signed int32 boundaries, insufficient distinct values, sentinel collisions, malformed lengths, and over-limit counts. The independent oracle is [`second_min_max_oracle.py`](../../second_min_max_oracle.py).

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm second_min_max --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/s/second_min_max/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms second_min_max
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/second_min_max.c`](../../../c/s/second_min_max.c) |
| C3 | [`c3/second_min_max.c3`](../../../c3/s/second_min_max.c3) |
| C++ | [`cpp/second_min_max.cpp`](../../../cpp/s/second_min_max.cpp) |
| Elisa | [`elisa/second_min_max.elisa`](../../../elisa/s/second_min_max.elisa) |
| Nim | [`nim/second_min_max.nim`](../../../nim/s/second_min_max.nim) |
| Odin | [`odin/second_min_max.odin`](../../../odin/s/second_min_max.odin) |
| Rust | [`rust/second_min_max.rs`](../../../rust/s/second_min_max.rs) |
| V | [`v/second_min_max.v`](../../../v/s/second_min_max.v) |
| Zig | [`zig/second_min_max.zig`](../../../zig/s/second_min_max.zig) |
