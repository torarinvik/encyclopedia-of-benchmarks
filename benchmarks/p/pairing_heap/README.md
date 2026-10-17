# Pairing heap

This package ports the pinned C# PairingHeap with `Sorting.Ascending`, which extracts the minimum key first.

## Contract

- Input uses the `i64_array_scalar` ABI and is laid out as `[n, value_0, ..., value_(n-1)]`.
- Require `2 <= n <= 128`, exact length `n + 1`, signed-i32 values, and distinct values. Invalid input returns `-1`.
- Construct a fresh ascending pairing heap, insert every value in input order, then extract exactly `n - 1` values. The final root is deliberately left in the heap.
- Fold the extracted values, in order, as four-byte little-endian signed-i32 encodings using FNV-1a-64. Start from offset basis `14695981039346656037`, multiply by `1099511628211` after each byte, and wrap modulo `2^64`. Return the low 63 bits of the final hash as a nonnegative signed-i64 scalar.

The source has no empty-extraction guard and retains a stale root after removing its sole value. Restricting inputs to at least two distinct keys and extracting exactly `n - 1` avoids that state while preserving the source’s min-heap extraction sequence.

## Workload and oracle

[workload.json](workload.json) covers small heaps, input-order variation, signed boundaries, the maximum heap size, and malformed sizes, duplicates, and out-of-range keys. The independent oracle sorts the accepted keys directly and hashes all but the maximum: [pairing_heap_oracle.py](../../pairing_heap_oracle.py).

Pinned source files share commit `96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c`:

- [PairingHeap.cs](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/Heap/PairingHeap/PairingHeap.cs)
- [Sorting.cs](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/Heap/PairingHeap/Sorting.cs)
- [PairingNodeComparer.cs](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/Heap/PairingHeap/PairingNodeComparer.cs)

## Implementations

| Language | Port |
|---|---|
| C | [c/p/pairing_heap.c](../../../c/p/pairing_heap.c) |
| C3 | [c3/p/pairing_heap.c3](../../../c3/p/pairing_heap.c3) |
| C++ | [cpp/p/pairing_heap.cpp](../../../cpp/p/pairing_heap.cpp) |
| Elisa | [elisa/p/pairing_heap.elisa](../../../elisa/p/pairing_heap.elisa) |
| Nim | [nim/p/pairing_heap.nim](../../../nim/p/pairing_heap.nim) |
| Odin | [odin/p/pairing_heap.odin](../../../odin/p/pairing_heap.odin) |
| Rust | [rust/p/pairing_heap.rs](../../../rust/p/pairing_heap.rs) |
| V | [v/p/pairing_heap.v](../../../v/p/pairing_heap.v) |
| Zig | [zig/p/pairing_heap.zig](../../../zig/p/pairing_heap.zig) |

Build a selected port with:

    python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm pairing_heap --language rust --with-checker

Record with:

    python3 benchmarks/run_i64_array_scalar.py --algorithm pairing_heap

Verify with:

    python3 benchmarks/verify_i64_array_scalar.py --algorithm pairing_heap --languages rust
