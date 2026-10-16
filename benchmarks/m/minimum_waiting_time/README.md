# Minimum Waiting Time

## Contract

Given up to 64 nonnegative query durations, schedule the shortest query first and return the sum of the waiting times for all queries. The input is a signed 64-bit integer array with every duration in `0..=1000`; empty and one-item inputs return 0. Inputs outside these bounds return `INT64_MIN`.

The ports copy and sort the durations in ascending order, then add `duration[i] * (count - i - 1)` for each item. This equals the sum of the waiting times incurred by the remaining queries. The maximum valid result is 2,016,000, so Java's signed 32-bit accumulator and the shared signed 64-bit ABI are both exact.

This benchmark measures the duration-ordering greedy rule and waiting-time sum. It does not model query arrival times or scheduling metadata. The separate [`fcfs_scheduling`](../../f/fcfs_scheduling/README.md) package preserves input process metadata and orders by arrival time.

## Workload

[`workload.json`](workload.json) includes the pinned examples, empty and singleton inputs, ties, zeros, reverse order, the 64-query upper bound, and invalid durations and lengths.

## TheAlgorithms references

- Java [`MinimumWaitingTime`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/greedyalgorithms/MinimumWaitingTime.java) sorts in ascending order and sums each duration weighted by the number of later queries.
- Python [`minimum_waiting_time`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/greedy_methods/minimum_waiting_time.py) returns 0 for zero or one query and uses the same sorted weighted sum.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/m/minimum_waiting_time.c](../../../c/m/minimum_waiting_time.c) |
| C3 | [c3/m/minimum_waiting_time.c3](../../../c3/m/minimum_waiting_time.c3) |
| C++ | [cpp/m/minimum_waiting_time.cpp](../../../cpp/m/minimum_waiting_time.cpp) |
| Elisa | [elisa/m/minimum_waiting_time.elisa](../../../elisa/m/minimum_waiting_time.elisa) |
| Nim | [nim/m/minimum_waiting_time.nim](../../../nim/m/minimum_waiting_time.nim) |
| Odin | [odin/m/minimum_waiting_time.odin](../../../odin/m/minimum_waiting_time.odin) |
| Rust | [rust/m/minimum_waiting_time.rs](../../../rust/m/minimum_waiting_time.rs) |
| V | [v/m/minimum_waiting_time.v](../../../v/m/minimum_waiting_time.v) |
| Zig | [zig/m/minimum_waiting_time.zig](../../../zig/m/minimum_waiting_time.zig) |
