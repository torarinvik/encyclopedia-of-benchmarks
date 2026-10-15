# Max heap

## Contract

Process a bounded sequence of max-heap operations over signed 64-bit keys. The input array is `[operation_count, operation, value, ...]`; each operation occupies two words. Operation `0` inserts `value`, operation `1` peeks at the maximum, and operation `2` extracts the maximum. The unused value word for peek and extract must be zero. Insert produces no output; peek and extract append one signed 64-bit result to the output stream. An empty peek or extract appends `INT64_MIN`, representing the absent result or empty-heap exception in the pinned APIs. Equal keys are allowed. The heap begins empty.

Inputs contain at most 512 operations, at most 256 inserted values, and values in the signed 32-bit range used by the pinned C source. Malformed inputs return `-1`; insufficient output capacity returns `-2`. The result count is the number of emitted words and each word is written as little-endian signed 64-bit data.

The shared ABI is:

```c
int64_t max_heap(const int64_t *input, size_t length,
                 uint8_t *output, size_t output_capacity);
```

The operation sequence projects the common insert, maximum lookup, and maximum removal behavior of the pinned C, Dart, Haskell, Java, Python, and Ruby implementations. The benchmark bounds total insertions to 256 so the C source's dynamic storage growth stays within a modest, fixed workload.

## Workload

[`workload.json`](workload.json) contains hand-written operation streams for empty access, duplicate keys, negative values, interleaved operations, and the operation limit. It also defines a 256-key drain sequence within the 512-operation bound.

The shared byte-output runner models the same operation sequence and packs each peek or extract result as one little-endian signed 64-bit word.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm max_heap --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm max_heap
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/max_heap.c`](../../../c/m/max_heap.c) |
| C3 | [`c3/m/max_heap.c3`](../../../c3/m/max_heap.c3) |
| C++ | [`cpp/m/max_heap.cpp`](../../../cpp/m/max_heap.cpp) |
| Elisa | [`elisa/m/max_heap.elisa`](../../../elisa/m/max_heap.elisa) |
| Nim | [`nim/m/max_heap.nim`](../../../nim/m/max_heap.nim) |
| Odin | [`odin/m/max_heap.odin`](../../../odin/m/max_heap.odin) |
| Rust | [`rust/m/max_heap.rs`](../../../rust/m/max_heap.rs) |
| V | [`v/m/max_heap.v`](../../../v/m/max_heap.v) |
| Zig | [`zig/m/max_heap.zig`](../../../zig/m/max_heap.zig) |

## Upstream references

- [C `max_heap.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/heap/max_heap.c)
- [Dart `Max_heap.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/data_structures/Heap/Binary_Heap/Max_heap.dart)
- [Haskell `MaxHeap.hs`](https://github.com/TheAlgorithms/Haskell/blob/9dcabef99fb8995a760ff25a9e0d659114c0b9d3/src/DataStructures/MaxHeap.hs)
- [Java `MaxHeap.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/heaps/MaxHeap.java)
- [Python `max_heap.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/heap/max_heap.py)
- [Ruby `max_heap.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/heaps/max_heap.rb)
