# Bandwidth Allocation

This benchmark ports `BandwidthAllocation.maxValue` from the pinned TheAlgorithms/Java source. It is a fractional greedy allocation: users are ordered by value per demand, full demands are allocated in that order, and the last demand may be partially funded.

## Contract

- Input is `[bandwidth, user_count, demands..., values...]`, with at most 64 users. Bandwidth is from 0 through 100,000; each demand is from 1 through 1,000; each value is from 0 through 10,000.
- Users are sorted by descending `value / demand`. Equal ratios retain input order, matching Java's stable object-array sort. If bandwidth cannot fund a complete demand, the source computes `ratio * remaining_bandwidth`, truncates that positive fractional gain to an integer, and stops.
- Invalid input returns `-1`. The maximum output is bounded to fit in a signed 32-bit integer, as in the Java source.
- Implementations use portable scalar floating-point and integer operations only.

The source comment's example says the result for bandwidth 10, demands `[3, 5, 7]`, and values `[10, 20, 30]` is 40. The executable code orders ratios as `30/7`, `20/5`, `10/3`, then allocates 7 units to the first user and 3 units fractionally to the second, returning 42. The workload records the executable result.

## Build and run

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm bandwidth_allocation --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/b/bandwidth_allocation/rust/build.json
```

## Implementations

| Language | Source |
|---|---|
| C | [`c/b/bandwidth_allocation.c`](../../../c/b/bandwidth_allocation.c) |
| C3 | [`c3/b/bandwidth_allocation.c3`](../../../c3/b/bandwidth_allocation.c3) |
| C++ | [`cpp/b/bandwidth_allocation.cpp`](../../../cpp/b/bandwidth_allocation.cpp) |
| Elisa | [`elisa/b/bandwidth_allocation.elisa`](../../../elisa/b/bandwidth_allocation.elisa) |
| Nim | [`nim/b/bandwidth_allocation.nim`](../../../nim/b/bandwidth_allocation.nim) |
| Odin | [`odin/b/bandwidth_allocation.odin`](../../../odin/b/bandwidth_allocation.odin) |
| Rust | [`rust/b/bandwidth_allocation.rs`](../../../rust/b/bandwidth_allocation.rs) |
| V | [`v/b/bandwidth_allocation.v`](../../../v/b/bandwidth_allocation.v) |
| Zig | [`zig/b/bandwidth_allocation.zig`](../../../zig/b/bandwidth_allocation.zig) |

## Pinned source

- TheAlgorithms/Java [`BandwidthAllocation.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/greedyalgorithms/BandwidthAllocation.java)
