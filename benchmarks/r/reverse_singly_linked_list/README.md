# Reverse singly linked list

Reverse the order of the payloads in a singly linked list. The pinned JavaScript implementation walks from the head to the end, rewires each node to point at its previous node, and returns the new head. The benchmark represents the list as its payload array, so the observable result is the array in reverse order.

## Contract

The `i32_array_bytes_output` ABI accepts a direct signed-32-bit array with length 0 through 256. The array models the list from head to tail. Any signed 32-bit payload is valid, including duplicates. A nonnull empty input is valid and returns zero output bytes. A null input pointer is invalid even when the length is zero; lengths above 256 are invalid. Invalid input returns `-1` before output checks.

The result is the payload array in reverse order, encoded as little-endian signed-32-bit values. The function returns `4 * length`, up to 1024 bytes. Output storage must be nonnull even for an empty result; a null output pointer or a capacity below `4 * length` returns `-2`. Errors write no output. The maximum parseable input length is 257 values (1028 bytes), allowing one over-limit element to be rejected.

## Workload and source

[`workload.json`](workload.json) covers empty, singleton, ordinary reversal, duplicates, signed integer boundaries, a 256-element list, an over-limit length, null input/output, and insufficient output capacity.

The source performs the standard iterative pointer reversal and does not inspect or modify node payloads:

- JavaScript [`ReverseSinglyLinkedList.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Linked-List/ReverseSinglyLinkedList.js)

## Ports

| Language | Source |
| --- | --- |
| C | [`c/r/reverse_singly_linked_list.c`](../../../c/r/reverse_singly_linked_list.c) |
| C3 | [`c3/r/reverse_singly_linked_list.c3`](../../../c3/r/reverse_singly_linked_list.c3) |
| C++ | [`cpp/r/reverse_singly_linked_list.cpp`](../../../cpp/r/reverse_singly_linked_list.cpp) |
| Elisa | [`elisa/r/reverse_singly_linked_list.elisa`](../../../elisa/r/reverse_singly_linked_list.elisa) |
| Nim | [`nim/r/reverse_singly_linked_list.nim`](../../../nim/r/reverse_singly_linked_list.nim) |
| Odin | [`odin/r/reverse_singly_linked_list.odin`](../../../odin/r/reverse_singly_linked_list.odin) |
| Rust | [`rust/r/reverse_singly_linked_list.rs`](../../../rust/r/reverse_singly_linked_list.rs) |
| V | [`v/r/reverse_singly_linked_list.v`](../../../v/r/reverse_singly_linked_list.v) |
| Zig | [`zig/r/reverse_singly_linked_list.zig`](../../../zig/r/reverse_singly_linked_list.zig) |

## Build and run

```sh
python3 benchmarks/build_abi.py --family i32_array_bytes_output --algorithm reverse_singly_linked_list --language rust
python3 benchmarks/run_i32_array_bytes_output.py --build-manifest build/i32_array_bytes_output/r/reverse_singly_linked_list/rust/build.json
```
