# Banker's algorithm Python demonstration

This package preserves the safe/unsafe decision made by TheAlgorithms/Python's printed-sequence Banker's demonstration, including its duplicate-need bookkeeping.

## Contract

- `i64_array_scalar` input is `[process_count, resource_count, total_claim[m], allocation[n*m row-major], maximum[n*m row-major]]`.
- Process count is 1..16; resource count is 1..8; all resource values are 0..100. For every cell, `allocation <= maximum`, and each resource's total allocation must not exceed its total claim. Input length must equal `2 + m + 2*n*m`.
- Initial available resources are `total_claim - sum(allocation)` for each resource. A remaining process is selected by the first feasible need row in original order.
- The source maps equal need vectors to the first process with that need. Completing a duplicate need row therefore adds the mapped first process's allocation, preserving the source demonstration's bookkeeping behavior.
- Return `1` if every need row is removed, `0` if no remaining row is feasible, and `-1` for invalid packed input.

## Source behavior

The pinned Python demonstration stores need rows and uses a dictionary keyed by each row's first equal occurrence. Duplicate vectors consequently reuse the first matching process's allocation during release, which can change the reported result relative to the canonical Java safety check. For example, `[3,1,2,0,1,0,1,2,2]` reports unsafe in this variant while the Java check reports safe.

## Workload

[`workload.json`](workload.json) includes a case where duplicate needs change the outcome, ordinary safe and unsafe states, and malformed inputs. The source-backed expected-value check in [`benchmarks/run_i64_array_scalar.py`](../../run_i64_array_scalar.py) preserves the first-index allocation release for duplicate need rows.

## Pinned source

- [Python `bankers_algorithm.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/other/bankers_algorithm.py)

## Ports

| Language | Source |
| --- | --- |
| C | [`c/b/bankers_algorithm_python_demo.c`](../../../c/b/bankers_algorithm_python_demo.c) |
| C3 | [`c3/b/bankers_algorithm_python_demo.c3`](../../../c3/b/bankers_algorithm_python_demo.c3) |
| C++ | [`cpp/b/bankers_algorithm_python_demo.cpp`](../../../cpp/b/bankers_algorithm_python_demo.cpp) |
| Elisa | [`elisa/b/bankers_algorithm_python_demo.elisa`](../../../elisa/b/bankers_algorithm_python_demo.elisa) |
| Nim | [`nim/b/bankers_algorithm_python_demo.nim`](../../../nim/b/bankers_algorithm_python_demo.nim) |
| Odin | [`odin/b/bankers_algorithm_python_demo.odin`](../../../odin/b/bankers_algorithm_python_demo.odin) |
| Rust | [`rust/b/bankers_algorithm_python_demo.rs`](../../../rust/b/bankers_algorithm_python_demo.rs) |
| V | [`v/b/bankers_algorithm_python_demo.v`](../../../v/b/bankers_algorithm_python_demo.v) |
| Zig | [`zig/b/bankers_algorithm_python_demo.zig`](../../../zig/b/bankers_algorithm_python_demo.zig) |
