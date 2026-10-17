# Sliding-window aggregator

This benchmark follows the pinned Java fixed-capacity sliding-window
aggregator. It appends a stream of signed integers to a FIFO window, evicts the
oldest item whenever the window is full, and returns the sum of the remaining
items.

## Contract

The `i64_array_scalar` input is `[capacity, count, values...]`. Values are
listed from oldest to newest. `capacity` is in 1..64, `count` is in 1..256,
and the input contains exactly `count` values. Every value is in
`-1,000,000..1,000,000`; these bounds keep all window sums within signed
64-bit range. The final window contains the last `min(capacity, count)` input
values, in their original order, and the result is their sum. Malformed
framing, out-of-range fields, or an empty stream return
`-9223372036854775808`, a sentinel that cannot be a valid sum under these
bounds.

The maximum valid input length is 258 integers; the maximum parseable input
length is 259. An empty stream is excluded because the Java `aggregate()` API
throws when the window is empty. The benchmark uses the source's
`sumOfLongs` specialization: identity mapping with `Long::sum`. The general
source constructor accepts a positive capacity, requires non-null mapper and
combiner functions, rejects null elements and null mapped/combined results,
and requires an associative combiner. It combines aggregates oldest-first;
the selected sum operation is commutative, while the stream order still
determines FIFO eviction. Adding to a full window evicts its oldest value.

The workload includes a capacity-one window, a stream shorter than capacity,
an exact fill, repeated evictions that exercise front/back transfers,
negative values, the maximum accepted capacity and stream length, and invalid
framing and bounds.

## Pinned source

- TheAlgorithms/Java [`SlidingWindowAggregator.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/buffers/SlidingWindowAggregator.java), commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`

## Workload

The workload is [`workload.json`](workload.json); the independent FIFO-sum
oracle is [`benchmarks/sliding_window_aggregator_oracle.py`](../../sliding_window_aggregator_oracle.py).

## Implementations

| Language | Source |
|---|---|
| C | [`c/s/sliding_window_aggregator.c`](../../../c/s/sliding_window_aggregator.c) |
| C3 | [`c3/s/sliding_window_aggregator.c3`](../../../c3/s/sliding_window_aggregator.c3) |
| C++ | [`cpp/s/sliding_window_aggregator.cpp`](../../../cpp/s/sliding_window_aggregator.cpp) |
| Elisa | [`elisa/s/sliding_window_aggregator.elisa`](../../../elisa/s/sliding_window_aggregator.elisa) |
| Nim | [`nim/s/sliding_window_aggregator.nim`](../../../nim/s/sliding_window_aggregator.nim) |
| Odin | [`odin/s/sliding_window_aggregator.odin`](../../../odin/s/sliding_window_aggregator.odin) |
| Rust | [`rust/s/sliding_window_aggregator.rs`](../../../rust/s/sliding_window_aggregator.rs) |
| V | [`v/s/sliding_window_aggregator.v`](../../../v/s/sliding_window_aggregator.v) |
| Zig | [`zig/s/sliding_window_aggregator.zig`](../../../zig/s/sliding_window_aggregator.zig) |
