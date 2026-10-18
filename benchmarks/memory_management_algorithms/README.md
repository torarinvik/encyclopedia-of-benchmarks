# Memory Management Algorithms

This package benchmarks four allocation policies from the pinned Java `MemoryManagementAlgorithms` family. A call selects one policy, supplies a nonempty list of memory blocks and an ordered process-size list, then returns the block selected for each process.

## Contract

Input is a signed-i64 array:

```text
[policy, block_count, process_count, block_size_0, ..., process_size_0, ...]
```

Policy selectors are `0` FirstFitCPU, `1` BestFitCPU, `2` WorstFitCPU, and `3` NextFit. The exact input length is `3 + block_count + process_count`. There must be 1–16 initial blocks and 0–32 processes. Block and process sizes are positive signed-i32 values no greater than 10,000. Every call uses a fresh policy instance and fresh block sizes.

Each process is handled in order. A successful allocation subtracts its size from the selected block. If no block fits, the result for that process is `-255`, and block sizes remain unchanged. FirstFit picks the first block large enough. BestFit picks the feasible block with the smallest leftover size, retaining the first block on ties. WorstFit selects the largest block (first on ties) only when it can fit the process. The block array must be nonempty for every policy because WorstFit indexes its maximum element without checking for an empty array.

NextFit starts its `counter` at zero for each call and retains it across that call's process requests. For each request it scans offsets `i=0..block_count-1`; before examining `blocks[i + counter]`, it sets `counter=-i` when `counter+i >= block_count`. On a success it updates `counter += i` and returns that counter as the selected block index. After a complete failed scan it executes `counter += block_count`. This failure update does not always reset the counter immediately: when it reaches the block count, the next request's first wrap check resets the effective cursor to zero; after a failure from a nonzero counter, the value can remain nonzero. These source-specific updates are preserved.

Output is one signed-i64 result per process, in process order, encoded as little-endian words. The value is the zero-based chosen block index or `-255` when allocation fails. The maximum valid input length is 51 words; 52 words are parseable for a trailing-data probe. Output and workspace are bounded at 256 bytes. A valid call returns the output byte count; an empty process list succeeds with zero bytes when given a non-null output pointer. Null input, malformed framing, an invalid policy, an empty block array, or an out-of-domain size returns `-1` before output checks. Null output or insufficient capacity returns `-2` after input validation. Errors write no bytes.

## Pinned source

- Java [`MemoryManagementAlgorithms.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/MemoryManagementAlgorithms.java), policies `FirstFitCPU`, `BestFitCPU`, `WorstFitCPU`, and `NextFit`, commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`benchmarks/memory_management_algorithms_oracle.py`](../memory_management_algorithms_oracle.py)

## Language ports

| Language | Port |
|---|---|
| C | [`c/m/memory_management_algorithms.c`](../../../c/m/memory_management_algorithms.c) |
| C3 | [`c3/m/memory_management_algorithms.c3`](../../../c3/m/memory_management_algorithms.c3) |
| C++ | [`cpp/m/memory_management_algorithms.cpp`](../../../cpp/m/memory_management_algorithms.cpp) |
| Elisa | [`elisa/m/memory_management_algorithms.elisa`](../../../elisa/m/memory_management_algorithms.elisa) |
| Nim | [`nim/m/memory_management_algorithms.nim`](../../../nim/m/memory_management_algorithms.nim) |
| Odin | [`odin/m/memory_management_algorithms.odin`](../../../odin/m/memory_management_algorithms.odin) |
| Rust | [`rust/m/memory_management_algorithms.rs`](../../../rust/m/memory_management_algorithms.rs) |
| V | [`v/m/memory_management_algorithms.v`](../../../v/m/memory_management_algorithms.v) |
| Zig | [`zig/m/memory_management_algorithms.zig`](../../../zig/m/memory_management_algorithms.zig) |
