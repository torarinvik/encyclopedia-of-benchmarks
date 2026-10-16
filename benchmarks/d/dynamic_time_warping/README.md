# Dynamic time warping

Measure the minimum absolute-difference cost for aligning two bounded sample series inside a Sakoe–Chiba band.

## Contract

- The i64_array_float64 ABI receives `[first_length, second_length, band, first_samples..., second_samples...]`.
- Each series length is in `[1, 16]`; the array length must be exactly `3 + first_length + second_length`. Every sample is an integer in `[-1,000, 1,000]`, a finite discrete subset of the Java `double[]` source API.
- `band` is in `[abs(first_length - second_length), 16]`, matching the source guard that the band be wide enough to contain a complete alignment. A band larger than either series is permitted within this benchmark bound.
- The rolling recurrence preserves the Java source order: `cost = abs(first[i - 1] - second[j - 1])`; `best = min(previous[j], min(current[j - 1], previous[j - 1]))`; `current[j] = cost + best`. The answer is the final cell. With the integer sample subset, every cost is an exact integer and the maximum result is below `2^53`.
- Invalid shapes, bands, or sample values return `-1e300`. Results use relative and absolute tolerance `1e-12`.
- Time is `O(first_length * min(second_length, 2 * band + 1))`; auxiliary space is `O(second_length)`.

## Source

This follows the pinned [TheAlgorithms/Java DynamicTimeWarping.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/streaming/DynamicTimeWarping.java) scalar `distance(first, second, band)` overload. The source also returns the full alignment path; this benchmark records the scalar distance through the existing result ABI.

## Workload and build

[`workload.json`](workload.json) covers identical and shifted series, zero-width and minimum-width bands, unequal lengths, maximum dimensions, sample limits, and invalid inputs. The source-backed expected-value check belongs in the shared i64_array_float64 runner.

Run the independent bounded corpus through each available implementation with:

```sh
python3 benchmarks/verify_dynamic_time_warping.py
```

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm dynamic_time_warping --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/d/dynamic_time_warping/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [c/d/dynamic_time_warping.c](../../../c/d/dynamic_time_warping.c) |
| C3 | [c3/d/dynamic_time_warping.c3](../../../c3/d/dynamic_time_warping.c3) |
| C++ | [cpp/d/dynamic_time_warping.cpp](../../../cpp/d/dynamic_time_warping.cpp) |
| Elisa | [elisa/d/dynamic_time_warping.elisa](../../../elisa/d/dynamic_time_warping.elisa) |
| Nim | [nim/d/dynamic_time_warping.nim](../../../nim/d/dynamic_time_warping.nim) |
| Odin | [odin/d/dynamic_time_warping.odin](../../../odin/d/dynamic_time_warping.odin) |
| Rust | [rust/d/dynamic_time_warping.rs](../../../rust/d/dynamic_time_warping.rs) |
| V | [v/d/dynamic_time_warping.v](../../../v/d/dynamic_time_warping.v) |
| Zig | [zig/d/dynamic_time_warping.zig](../../../zig/d/dynamic_time_warping.zig) |
