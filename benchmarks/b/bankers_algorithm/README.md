# Banker's algorithm

Determine whether a bounded resource-allocation state is safe: can every process finish in some order while each process's remaining need stays within the currently available resources?

## Contract

- The `i64_array_scalar` input is `[process_count, resource_count, available[m], maximum[n*m row-major], allocation[n*m row-major]]`.
- Process count is 1..16, resource count is 1..8, and available, maximum, and allocation entries are each 0..100.
- For every process/resource pair, `allocation <= maximum`. The packed input length must be exactly `2 + m + 2*n*m`.
- The algorithm scans unfinished processes by ascending index. If a process's need (`maximum - allocation`) fits in `work`, it is marked finished and its allocation is added to `work`. Scans repeat until all processes finish or a full scan makes no progress.
- Return `1` for a safe state, `0` for an unsafe state, and `-1` for invalid packed input or values outside the bounds.

## Source semantics

The benchmark follows Java's `checkSafeSystem` boolean result and index-ordered repeated safety scans. The pinned Python source is a related demonstration with a printed-sequence API and different bookkeeping for duplicate need rows; this package uses Java as the oracle reference and exposes only the safe/unsafe decision.

## Workload

[`workload.json`](workload.json) covers a safe multi-resource state, an unsafe state, immediate completion, a state that releases resources for a later process, and malformed dimensions/resource values. The source-backed expected-value check is in [`benchmarks/run_i64_array_scalar.py`](../../run_i64_array_scalar.py).

## Pinned sources

- [Java `BankersAlgorithm.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/BankersAlgorithm.java)
- [Python `bankers_algorithm.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/other/bankers_algorithm.py) — related printed-sequence variant, not the package oracle.

## Ports

| Language | Source |
| --- | --- |
| C | [`c/b/bankers_algorithm.c`](../../../c/b/bankers_algorithm.c) |
| C3 | [`c3/b/bankers_algorithm.c3`](../../../c3/b/bankers_algorithm.c3) |
| C++ | [`cpp/b/bankers_algorithm.cpp`](../../../cpp/b/bankers_algorithm.cpp) |
| Elisa | [`elisa/b/bankers_algorithm.elisa`](../../../elisa/b/bankers_algorithm.elisa) |
| Nim | [`nim/b/bankers_algorithm.nim`](../../../nim/b/bankers_algorithm.nim) |
| Odin | [`odin/b/bankers_algorithm.odin`](../../../odin/b/bankers_algorithm.odin) |
| Rust | [`rust/b/bankers_algorithm.rs`](../../../rust/b/bankers_algorithm.rs) |
| V | [`v/b/bankers_algorithm.v`](../../../v/b/bankers_algorithm.v) |
| Zig | [`zig/b/bankers_algorithm.zig`](../../../zig/b/bankers_algorithm.zig) |
