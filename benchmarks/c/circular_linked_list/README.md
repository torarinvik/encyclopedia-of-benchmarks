# Singly circular linked list operation trace

Model a bounded singly linked list whose tail points back to a sentinel before the first element. Each operation follows one forward link at a time. The trace normalizes the append/traversal behavior in C and C++, positional removal in Java, and the wider API in JavaScript.

## Contract

The `i64_array_scalar` function accepts zero to 1,024 signed 64-bit values encoded as `[opcode, payload]` pairs, for up to 512 operations:

- `0`: append a value in `[-1,000,000, 1,000,000]`
- `1`: prepend a value in the same range
- `2`: remove and return the first value, with payload zero
- `3`: remove and return the last value, with payload zero
- `4`: remove the first matching value, returning `1` if found or `0` if absent
- `5`: report whether a value is present, returning `1` or `0`
- `6`: report the list length, with payload zero
- `7`: return the value at a strict zero-based index
- `8`: remove and return the value at a strict zero-based index

The list holds at most 256 values. Odd-length input, an unknown opcode, an out-of-range value or index, a nonzero payload for operations 2, 3, or 6, an empty pop or indexed access, a capacity overflow, or input longer than 1,024 values returns `-1`. Empty input is valid. Indexes do not wrap: valid positions are `0` through `length - 1`.

Each value-returning operation contributes `(operation_index + 1) * (observed_value + 1,000,000)` to the checksum. A final forward traversal visits every remaining node exactly once and adds `(operation_count + node_index + 1) * (node_value + 1,000,000)`. The valid checksum is nonnegative and fits signed 64-bit.

The benchmark uses a fixed node pool and a circular sentinel. Removed nodes return to the free list. Each node stores only its value and one next link; finding the tail for a deletion scans forward. Runtime is `O(1)` for append/prepend/front removal and `O(n)` for searches, indexed operations, and tail removal.

## Relationship to other list candidates

The C source appends nodes, deletes the first matching value, and traverses from the head; C++ appends and exposes one-pass traversal; Java appends and removes at a strict zero-based position; JavaScript offers insert, indexed access, deletion, and traversal methods. The normalized trace uses one shared set of list operations and first-match deletion semantics. JavaScript's broken singleton ring setup, unbounded circular `indexOf`, invalid-index condition, and loss of stored zero values are source defects outside this contract.

This is the singly linked structure shared by `circular_linked_list`, `circle_linked_list`, and `singly_circular_linked_list`. It differs from [`circular_doubly_linked_list`](../circular_doubly_linked_list/README.md), which maintains previous links and modular indexed access.

## Implementations

The nine ports are in `c/s/circular_linked_list.c`, `c3/s/circular_linked_list.c3`, `cpp/s/circular_linked_list.cpp`, `elisa/s/circular_linked_list.elisa`, `nim/s/circular_linked_list.nim`, `odin/s/circular_linked_list.odin`, `rust/s/circular_linked_list.rs`, `v/s/circular_linked_list.v`, and `zig/s/circular_linked_list.zig`.

## Pinned sources

- [C `circular_linked_list.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/linked_list/circular_linked_list.c)
- [C++ `circular_linked_list.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/operations_on_datastructures/circular_linked_list.cpp)
- [Java `CircleLinkedList.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/lists/CircleLinkedList.java)
- [JavaScript `SinglyCircularLinkedList.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Linked-List/SinglyCircularLinkedList.js)

Build with the `i64_array_scalar` ABI family and record with `benchmarks/run_i64_array_scalar.py`.
