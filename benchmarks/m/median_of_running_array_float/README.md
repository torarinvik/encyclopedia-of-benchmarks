# Running median for floats

This benchmark specializes the pinned Java `MedianOfRunningArrayFloat`
subclass. It returns the median after each insertion into a growing stream of
finite IEEE-754 binary32 values transported through the `float64_slice_io`
ABI.

## Contract

- Input is `[sample_count, sample_0, ..., sample_(sample_count-1)]`. The count
  must be an exact integer from 1 through 64. Samples must be finite, in
  `[-1,000,000, 1,000,000]`, and exactly representable as binary32. Exactness
  is checked by converting binary64 to binary32 and back, preserving the sign
  of zero. This models the Java `Float` values without silently narrowing an
  arbitrary binary64 input.
- The inherited Java base inserts into the max-heap only when the min-heap is
  nonempty and the sample is strictly less than its root. It moves a root only
  when one heap exceeds the other by more than one element. Odd prefixes
  return the root of the larger heap; even prefixes call the subclass's
  `(a + b) / 2.0f` expression.
- Java `Float.compareTo` orders `-0.0f` below `+0.0f`. NaN and infinities are
  rejected. Each even median rounds the sum to binary32, divides that value by
  `2.0f` with binary32 rounding, then widens the final result exactly to
  binary64 for the ABI output. The sample bound prevents sum overflow.
- The valid packed input has at most 65 values. One additional value is
  parseable only so trailing data can be rejected (maximum parseable length
  66). Output contains one widened binary32 median per sample, in insertion
  order, and has at most 64 elements. Success returns `sample_count`.
- Malformed, null, nonfinite, non-binary32, or out-of-range input returns
  `-1` before output checks. Null output or capacity below `sample_count`
  returns `-2` without writes. Output comparisons use zero absolute and
  relative tolerance.

The oracle and workload preserve signed-zero ordering and results. The C ABI
checker compares zero numerically, while the recorder validation checks the
observed and expected zero sign bits for this median specialization.

The pinned subclass is Java
[`MedianOfRunningArrayFloat`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/misc/MedianOfRunningArrayFloat.java).
It inherits insertion, rebalancing, and root selection from
[`MedianOfRunningArray`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/misc/MedianOfRunningArray.java).
Both files are pinned at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.
The Java API specifies that `Float.compareTo` orders negative zero below
positive zero ([Java `Float` API](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/lang/Float.html#compareTo(java.lang.Float))).

## Language ports

| Language | Source |
| --- | --- |
| C | [c/m/median_of_running_array_float.c](../../../c/m/median_of_running_array_float.c) |
| C3 | [c3/m/median_of_running_array_float.c3](../../../c3/m/median_of_running_array_float.c3) |
| C++ | [cpp/m/median_of_running_array_float.cpp](../../../cpp/m/median_of_running_array_float.cpp) |
| Elisa | [elisa/m/median_of_running_array_float.elisa](../../../elisa/m/median_of_running_array_float.elisa) |
| Nim | [nim/m/median_of_running_array_float.nim](../../../nim/m/median_of_running_array_float.nim) |
| Odin | [odin/m/median_of_running_array_float.odin](../../../odin/m/median_of_running_array_float.odin) |
| Rust | [rust/m/median_of_running_array_float.rs](../../../rust/m/median_of_running_array_float.rs) |
| V | [v/m/median_of_running_array_float.v](../../../v/m/median_of_running_array_float.v) |
| Zig | [zig/m/median_of_running_array_float.zig](../../../zig/m/median_of_running_array_float.zig) |

See [workload.json](workload.json) and the independent
[oracle](../../median_of_running_array_float_oracle.py).

## Reproduce

~~~
python3 benchmarks/build_abi.py --family float64_slice_io --algorithm median_of_running_array_float --language rust
python3 benchmarks/run_float64_slice_io.py --algorithm median_of_running_array_float
python3 benchmarks/verify_float64_slice_io.py --algorithm median_of_running_array_float --languages rust
~~~
