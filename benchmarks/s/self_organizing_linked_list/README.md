# Self-organizing linked-list trace

This benchmark follows the pinned Java `SelfOrganizingLinkedList<Integer>`
using a bounded append and search trace. It records each operation's result
and a final list snapshot as little-endian signed 64-bit fields.

## Contract

The input is `[operation_count, (opcode, value) * operation_count]`. The count
is 0 through 64, the list may contain at most 64 values, and values are signed
32-bit integers. Opcode 0 appends the value at the tail and records `[0, 0]`.
Opcode 1 searches for the value and records `[1, 1, found]`, where `found` is 1
or 0. On a hit, the source moves the first matching node to the head; a miss
leaves the order unchanged. Duplicate values are allowed, and search observes
the first equal value in head-to-tail order.

After the operations, append `[2, list_length, values...]` to the output, with
the current list in head-to-tail order. The maximum output is 194 signed-i64
fields (1,552 bytes). Integer values are sign-extended into each eight-byte
little-endian field. A successful call returns the number of output bytes
written.

Malformed or null input returns -1 and writes no output. A null output buffer or
one with insufficient capacity returns -2 and writes no output; input validity
is checked first. An empty valid trace still emits the final snapshot `[2,0]`
and returns 16. The largest valid input contains 129 signed-i64 cells; the
largest parseable input contains 130 cells, allowing a trailing-cell rejection
case. The bounded source values and list length keep all source `int` fields in
range.

## Pinned source

- TheAlgorithms/Java [`SelfOrganizingLinkedList.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/lists/SelfOrganizingLinkedList.java), commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`

## Workload

The workload is [`workload.json`](workload.json); the independent list-model
oracle is [`benchmarks/self_organizing_linked_list_oracle.py`](../../self_organizing_linked_list_oracle.py).
