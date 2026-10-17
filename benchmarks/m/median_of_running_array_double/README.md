# Running median for doubles

This benchmark specializes the pinned Java `MedianOfRunningArrayDouble` subclass. It returns the median after each insertion into a growing stream of finite binary64 values.

## Contract

- The ABI is `float64_slice_io`. Input is `[sample_count, sample_0, ..., sample_(count-1)]`, with an exact integral count from 1 through 64. Samples must be finite and within `[-1,000,000,1,000,000]`. The maximum valid input has 65 values; one extra parseable value is allowed only to reject trailing data.
- The inherited Java base class inserts into the max-heap only when the min-heap is nonempty and a sample is strictly less than its root; otherwise it inserts into the min-heap. It moves a root only when one heap exceeds the other by more than one element. For odd prefixes it returns the root of the larger heap; the heap ordering makes either selected root equal to the sorted center. For even prefixes the subclass returns `(lowerRoot + upperRoot) / 2.0d` in that operation order.
- Java `Double.compareTo` orders `-0.0` below `+0.0`. The oracle preserves this order while sorting each prefix, including signed-zero fixtures. NaN and infinities are invalid. The sample bound prevents average overflow.
- The output contains one binary64 median per sample, in insertion order. Success returns `sample_count`. Malformed, nonfinite, out-of-range, or null input returns `-1` before output checks. A null output or capacity below the sample count returns `-2` without writes. Comparisons use zero absolute and relative tolerance.

The workload covers both heap-root orientations, positive and negative even medians, signed zero ordering, duplicates, endpoint values, maximum stream length, malformed input, and output-buffer errors. See [workload.json](workload.json) and the independent [oracle](../../median_of_running_array_double_oracle.py).

The subclass is Java [`MedianOfRunningArrayDouble`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/misc/MedianOfRunningArrayDouble.java). It inherits insertion, rebalancing, and root selection from [`MedianOfRunningArray`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/misc/MedianOfRunningArray.java). Both files are pinned at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

## Reproduce

~~~
python3 benchmarks/build_abi.py --family float64_slice_io --algorithm median_of_running_array_double --language rust
python3 benchmarks/run_float64_slice_io.py --algorithm median_of_running_array_double
python3 benchmarks/verify_float64_slice_io.py --algorithm median_of_running_array_double --languages rust
~~~

## Language ports

| Language | Source |
| --- | --- |
| C | [c/m/median_of_running_array_double.c](../../../c/m/median_of_running_array_double.c) |
| C3 | [c3/m/median_of_running_array_double.c3](../../../c3/m/median_of_running_array_double.c3) |
| C++ | [cpp/m/median_of_running_array_double.cpp](../../../cpp/m/median_of_running_array_double.cpp) |
| Elisa | [elisa/m/median_of_running_array_double.elisa](../../../elisa/m/median_of_running_array_double.elisa) |
| Nim | [nim/m/median_of_running_array_double.nim](../../../nim/m/median_of_running_array_double.nim) |
| Odin | [odin/m/median_of_running_array_double.odin](../../../odin/m/median_of_running_array_double.odin) |
| Rust | [rust/m/median_of_running_array_double.rs](../../../rust/m/median_of_running_array_double.rs) |
| V | [v/m/median_of_running_array_double.v](../../../v/m/median_of_running_array_double.v) |
| Zig | [zig/m/median_of_running_array_double.zig](../../../zig/m/median_of_running_array_double.zig) |
