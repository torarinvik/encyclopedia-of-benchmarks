# Running median for signed 64-bit integers

This benchmark specializes the pinned Java `MedianOfRunningArrayLong` subclass. It emits one median after each insertion into a growing stream of bounded signed 64-bit values.

## Contract

- The ABI is `i64_array_bytes_output`. Input is signed-i64 words `[sample_count, sample_0, ..., sample_(count-1)]`. The count is 1–64 and the exact input length is `1 + sample_count`, so the maximum valid input is 65 words; one additional parseable word is reserved to reject trailing data.
- Samples are restricted to `[-2^62, 2^62-1]`. This ensures the source's even-median addition `(lowerRoot + upperRoot)` stays within signed-i64 range. The output is one signed-i64 median for each nonempty prefix, in insertion order.
- The inherited Java base class inserts into the max-heap only when the min-heap is nonempty and a sample is strictly less than its root; otherwise it inserts into the min-heap. It moves one root only when one heap exceeds the other by more than one element. For odd prefixes it returns the larger heap's root, which is the sorted center. For even prefixes the subclass computes `(lowerRoot + upperRoot) / 2L` using Java division truncating toward zero.
- Output values are encoded as little-endian signed-i64 words with no count prefix. Success returns the output byte count, `8 * sample_count`, up to 512. Invalid or null input returns `-1` before output checks. A null output pointer or insufficient capacity returns `-2` without writes.

The workload covers odd-prefix root selection in both heap orientations, positive and negative even averages, signed endpoints, duplicates, maximum stream length, malformed framing including the maximum-parseable trailing-data boundary, null input, and output-buffer errors. See [workload.json](workload.json) and the independent [oracle](../../median_of_running_array_long_oracle.py).

The subclass is Java [`MedianOfRunningArrayLong`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/misc/MedianOfRunningArrayLong.java). It inherits insertion, rebalancing, and root selection from [`MedianOfRunningArray`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/misc/MedianOfRunningArray.java). Both files are pinned at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

## Reproduce

~~~
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm median_of_running_array_long --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm median_of_running_array_long
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm median_of_running_array_long --languages rust
~~~

## Language ports

| Language | Source |
| --- | --- |
| C | [c/m/median_of_running_array_long.c](../../../c/m/median_of_running_array_long.c) |
| C3 | [c3/m/median_of_running_array_long.c3](../../../c3/m/median_of_running_array_long.c3) |
| C++ | [cpp/m/median_of_running_array_long.cpp](../../../cpp/m/median_of_running_array_long.cpp) |
| Elisa | [elisa/m/median_of_running_array_long.elisa](../../../elisa/m/median_of_running_array_long.elisa) |
| Nim | [nim/m/median_of_running_array_long.nim](../../../nim/m/median_of_running_array_long.nim) |
| Odin | [odin/m/median_of_running_array_long.odin](../../../odin/m/median_of_running_array_long.odin) |
| Rust | [rust/m/median_of_running_array_long.rs](../../../rust/m/median_of_running_array_long.rs) |
| V | [v/m/median_of_running_array_long.v](../../../v/m/median_of_running_array_long.v) |
| Zig | [zig/m/median_of_running_array_long.zig](../../../zig/m/median_of_running_array_long.zig) |
