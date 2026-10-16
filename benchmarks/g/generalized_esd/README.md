# Generalized ESD

This bounded benchmark implements Rosner's generalized extreme Studentized deviate test with fixed significance level `alpha = 0.05`.

## Contract

- Input is `[sample_count, maximum_outliers, sample_value...]`; sample count is 3–8, maximum outliers is 1 through `min(3, sample_count - 2)`, and each value is an integer in `[-10000,10000]`.
- At each step, compute the current arithmetic mean and sample standard deviation, remove the first current sample with maximal absolute deviation, and compare its standardized deviation with the two-sided ESD critical value. The result includes the largest passing step, even if an earlier step did not pass. The index mask is over original zero-based sample positions.
- Fixed critical values are for alpha 0.05 and current remaining sizes 3–8. Invalid arrays return -1.

## Source and distinctions

The pinned [Java implementation](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/streaming/GeneralizedEsd.java) implements Rosner's test, including the iterative removal, Student-t threshold, and largest-passing-step rule. This is distinct from the local IQR fence benchmark and from streaming EWMA/Hampel detectors.

The runtime oracle is [`generalized_esd_oracle.py`](../../generalized_esd_oracle.py). Workloads cover high and low outliers, multiple outliers, clean and constant samples, and malformed inputs.

Focused verification passed for C, C3, C++, Nim, Odin, Rust, V, and Zig against 271 oracle arrays each. The configured Elisa stage1 compiler produced an object containing only the local `ltmp0` symbol; it did not emit `_generalized_esd`, so the Elisa source is present but is not counted as runtime-verified.

## Ports

| Language | Source |
| --- | --- |
| C | [`c/g/generalized_esd.c`](../../../c/g/generalized_esd.c) |
| C3 | [`c3/g/generalized_esd.c3`](../../../c3/g/generalized_esd.c3) |
| C++ | [`cpp/g/generalized_esd.cpp`](../../../cpp/g/generalized_esd.cpp) |
| Elisa | [`elisa/g/generalized_esd.elisa`](../../../elisa/g/generalized_esd.elisa) |
| Nim | [`nim/g/generalized_esd.nim`](../../../nim/g/generalized_esd.nim) |
| Odin | [`odin/g/generalized_esd.odin`](../../../odin/g/generalized_esd.odin) |
| Rust | [`rust/g/generalized_esd.rs`](../../../rust/g/generalized_esd.rs) |
| V | [`v/g/generalized_esd.v`](../../../v/g/generalized_esd.v) |
| Zig | [`zig/g/generalized_esd.zig`](../../../zig/g/generalized_esd.zig) |
