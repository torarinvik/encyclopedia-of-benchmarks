# BFPRT Selection

This package returns the one-based `k`th smallest value in a bounded unsorted array, using median-of-medians selection. Input is `[length, k, values...]`. The array length is 1 through 1,024, `k` is in the range 1 through `length`, and values are signed 32-bit integers, matching the pinned Java API. Duplicate values count as separate positions in the order statistic. The caller's input is not modified.

The ports sort groups of at most five, move each group's upper median into a compact prefix, recursively select the median of that prefix, then partition the active range into values below, equal to, and above the pivot. This keeps the selection worst-case linear while handling repeated values without repeatedly recursing over the equal region.

The signed 64-bit result is the selected value. A malformed input, invalid rank, or out-of-range value returns `-2147483649`, a sentinel outside the supported signed 32-bit value domain. The pinned scalar helper assumes a valid rank; its companion `getMinKNumsByBFPRT` returns a vector of the `k` smallest values and returns `null` for an invalid `k`, so that separate vector operation is outside this scalar workload.

| Language | Port |
|---|---|
| C | [`c/b/bfprt.c`](../../../c/b/bfprt.c) |
| C3 | [`c3/b/bfprt.c3`](../../../c3/b/bfprt.c3) |
| C++ | [`cpp/b/bfprt.cpp`](../../../cpp/b/bfprt.cpp) |
| Elisa | [`elisa/b/bfprt.elisa`](../../../elisa/b/bfprt.elisa) |
| Nim | [`nim/b/bfprt.nim`](../../../nim/b/bfprt.nim) |
| Odin | [`odin/b/bfprt.odin`](../../../odin/b/bfprt.odin) |
| Rust | [`rust/b/bfprt.rs`](../../../rust/b/bfprt.rs) |
| V | [`v/b/bfprt.v`](../../../v/b/bfprt.v) |
| Zig | [`zig/b/bfprt.zig`](../../../zig/b/bfprt.zig) |

Pinned source: [TheAlgorithms/Java `BFPRT.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/BFPRT.java). Its public `getMinKthByBFPRT` method uses one-based ranks, copies the array before partitioning, and returns the selected value. The workload isolates that scalar operation. See [`workload.json`](workload.json) for duplicates, signed boundaries, group-size boundaries, and invalid input cases.
