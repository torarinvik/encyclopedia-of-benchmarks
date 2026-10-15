# Shortest coprime segment

This benchmark follows the pinned Java [`ShortestCoprimeSegment`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/slidingwindow/ShortestCoprimeSegment.java). It returns the first shortest contiguous segment whose values have greatest common divisor 1. The source uses a two-stack sliding window with a running GCD aggregate on each stack.

## Contract

The `i64_array_bytes_output` input is the array itself, in order, with at most 128 elements. Every value must be an integer from 1 through 1,000. These positive bounded values preserve the source GCD semantics while avoiding signed-long corner cases. An empty array is valid.

The output contains the selected segment's original values in their original order, each encoded as one little-endian signed 64-bit integer. There is no length prefix; output byte count determines the number of values. Empty input and an input with no coprime segment both produce zero output bytes, matching the source's empty-array result. When multiple shortest segments have equal length, the source's strict shorter-only update keeps the earliest-ending segment, which is also the earliest-starting among equal-length minima.

Malformed lengths or values return `-1`. If the output buffer cannot hold the complete result, return `-2` without writing any bytes. The workload's maximum result is 1,024 bytes.

## Workload and recording

[`workload.json`](workload.json) covers empty/no-result inputs, singleton and length-two answers, leftmost tie selection, longer minima, invalid values, and an insufficient-capacity result. The shared `i64_array_bytes_output` runner validates each case against a source-specific bounded GCD oracle before recording.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm shortest_coprime_segment --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/s/shortest_coprime_segment/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/shortest_coprime_segment.c`](../../../c/s/shortest_coprime_segment.c) |
| C3 | [`c3/s/shortest_coprime_segment.c3`](../../../c3/s/shortest_coprime_segment.c3) |
| C++ | [`cpp/s/shortest_coprime_segment.cpp`](../../../cpp/s/shortest_coprime_segment.cpp) |
| Elisa | [`elisa/s/shortest_coprime_segment.elisa`](../../../elisa/s/shortest_coprime_segment.elisa) |
| Nim | [`nim/s/shortest_coprime_segment.nim`](../../../nim/s/shortest_coprime_segment.nim) |
| Odin | [`odin/s/shortest_coprime_segment.odin`](../../../odin/s/shortest_coprime_segment.odin) |
| Rust | [`rust/s/shortest_coprime_segment.rs`](../../../rust/s/shortest_coprime_segment.rs) |
| V | [`v/s/shortest_coprime_segment.v`](../../../v/s/shortest_coprime_segment.v) |
| Zig | [`zig/s/shortest_coprime_segment.zig`](../../../zig/s/shortest_coprime_segment.zig) |

## Pinned source

- Java [`ShortestCoprimeSegment.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/slidingwindow/ShortestCoprimeSegment.java)
