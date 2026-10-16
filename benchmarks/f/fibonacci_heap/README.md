# Fibonacci heap

Insert the signed keys into an initially empty Fibonacci min-heap, then repeatedly extract and emit the minimum until the heap is empty. The benchmark covers the shared core of the pinned C# and Java implementations: insertion and minimum removal. It does not measure decrease-key, union/meld, handles, or the Java implementation's counters.

## Contract

- Input is a signed 64-bit integer array containing 0 through 128 keys. Each key must fit in signed 32-bit range, matching the pinned Java implementation.
- Duplicate keys are distinct heap items.
- Output is each extracted key in extraction order, encoded as an 8-byte little-endian signed integer. Equal keys may appear in either order because their values are identical.
- Empty input is valid and produces zero output bytes. Inputs longer than 128 keys return `-1`; insufficient output capacity returns `-2`.
- The implementations use Fibonacci-heap root lists and degree consolidation after each minimum extraction. The independent oracle sorts the same multiset to define the expected extraction sequence.

The workload covers empty and singleton heaps, duplicates, negative and signed-boundary keys, ascending and descending insertion order, capacity failure, and the maximum supported input length.

## Sources

- [Pinned C# `FibonacciHeap.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/Heap/FibonacciHeap/FibonacciHeap.cs)
- [Pinned Java `FibonacciHeap.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/heaps/FibonacciHeap.java)

Build and run with the `i64_array_bytes_output` ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm fibonacci_heap --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm fibonacci_heap
```
