# Merge Linked Lists

This package ports the pinned C `merge()` routine from [TheAlgorithms/C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/linked_list/merge_linked_lists.c). The routine alternately splices nodes from the second list between nodes of the first list. It does not sort or compare node values. The demonstration globals, allocation code, printing, and `main` are excluded.

## Contract

Input is `[first_length, second_length, first_values..., second_values...]`. Each finite acyclic input list has 0–32 distinct local nodes, with at most 64 nodes total. Node values are signed 32-bit integers. The exact packed length must equal `2 + first_length + second_length`; malformed framing, invalid counts, or out-of-range values return `-1`.

The output traverses from the original first head after the same alternating pointer splices. Values are sign-extended to signed 64-bit and encoded little-endian; the return value is the number of output bytes. A null or undersized output buffer returns `-2`, and invalid input takes precedence. The maximum output is 512 bytes. As in the source, an empty first list has a null head, so the result traversal is empty even if the second list contains nodes. An empty second list leaves the first list unchanged.

[`workload.json`](workload.json) contains 29 cases covering the published example, both length orderings, equal lengths, duplicate and boundary values, all empty-list combinations, maximum size, malformed framing, invalid counts, signed 32-bit range failures, null/short/exact output capacities, and invalid-input-before-null-output precedence. It also checks a valid empty result with a nonnull output pointer and zero capacity. The independent oracle is [`merge_linked_lists_oracle.py`](../../merge_linked_lists_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`merge_linked_lists.c`](../../../c/m/merge_linked_lists.c) |
| C3 | [`merge_linked_lists.c3`](../../../c3/m/merge_linked_lists.c3) |
| C++ | [`merge_linked_lists.cpp`](../../../cpp/m/merge_linked_lists.cpp) |
| Elisa | [`merge_linked_lists.elisa`](../../../elisa/m/merge_linked_lists.elisa) |
| Nim | [`merge_linked_lists.nim`](../../../nim/m/merge_linked_lists.nim) |
| Odin | [`merge_linked_lists.odin`](../../../odin/m/merge_linked_lists.odin) |
| Rust | [`merge_linked_lists.rs`](../../../rust/m/merge_linked_lists.rs) |
| V | [`merge_linked_lists.v`](../../../v/m/merge_linked_lists.v) |
| Zig | [`merge_linked_lists.zig`](../../../zig/m/merge_linked_lists.zig) |

Build, record, and verify a port with the `i64_array_bytes_output` ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm merge_linked_lists --language c
python3 benchmarks/run_i64_array_bytes_output.py --algorithm merge_linked_lists
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm merge_linked_lists
```

## Pinned source

[TheAlgorithms/C `merge_linked_lists.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/linked_list/merge_linked_lists.c)
