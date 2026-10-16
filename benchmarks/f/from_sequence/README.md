# Linked list from sequence

This benchmark follows the pinned Python `make_linked_list` constructor. It creates one singly linked node per sequence element, in input order. The observable output is the source node representation: each node prints as `<value> ---> `, followed by `<END>`.

## Contract

Input is `[node_count, values...]`, with 1–128 signed 64-bit values. The packed length must equal `node_count + 1`. Output is the exact ASCII representation produced by `Node.__repr__`, including the trailing arrow and spaces before `<END>`. Empty input and malformed lengths return `-1`; insufficient output capacity returns `-2`.

At the maximum count, 128 signed 64-bit minimum values produce the maximum output size of 3,589 bytes. The 129-value parser bound also admits the count-129 rejection probe, which reaches the function and returns `-1`.

| Language | Source |
|---|---|
| C | [`c/f/from_sequence.c`](../../../c/f/from_sequence.c) |
| C3 | [`c3/f/from_sequence.c3`](../../../c3/f/from_sequence.c3) |
| C++ | [`cpp/f/from_sequence.cpp`](../../../cpp/f/from_sequence.cpp) |
| Elisa | [`elisa/f/from_sequence.elisa`](../../../elisa/f/from_sequence.elisa) |
| Nim | [`nim/f/from_sequence.nim`](../../../nim/f/from_sequence.nim) |
| Odin | [`odin/f/from_sequence.odin`](../../../odin/f/from_sequence.odin) |
| Rust | [`rust/f/from_sequence.rs`](../../../rust/f/from_sequence.rs) |
| V | [`v/f/from_sequence.v`](../../../v/f/from_sequence.v) |
| Zig | [`zig/f/from_sequence.zig`](../../../zig/f/from_sequence.zig) |

Pinned source: [TheAlgorithms/Python `from_sequence.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/linked_list/from_sequence.py).
