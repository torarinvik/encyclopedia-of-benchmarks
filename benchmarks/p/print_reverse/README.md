# Print reverse

This package ports `in_reverse` from the pinned Python linked-list implementation. The function returns the linked-list values in reverse order as decimal text joined by the literal separator ` <- `. An empty list returns the empty string. Although the docstring says “Prints,” `in_reverse` returns a string; printing occurs only in the module's example block.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is the list's values directly, in forward order, with length 0..256. Each value must fit a signed 32-bit integer. A null input pointer with length zero represents the empty list; a null pointer with positive length is invalid. Extra values past the 256-item domain are invalid.
- The output is the ASCII/UTF-8 encoding of the decimal values in reverse order, separated by exactly four bytes, ` <- `. There is no prefix, suffix, or newline. A valid empty list returns zero bytes.
- Invalid input returns `-1` before output storage is checked. A null output pointer or insufficient capacity returns `-2` without writes, including for an empty result. A nonnull output pointer with capacity zero is valid for the empty result.
- The maximum output is 3,836 bytes: 256 values of up to 11 characters each (including `-2147483648`) plus 255 four-byte separators.

The pinned source builds a tuple from its linked list, reverses that tuple, converts each value with Python's decimal `str`, and joins the results. The benchmark input represents the list contents directly, so the measured work is formatting in reverse order rather than linked-list construction.

## Workload and source

[`workload.json`](workload.json) covers empty, singleton, signed, duplicate, reverse-order, full-length/full-output, malformed input, and output-capacity cases. The independent [oracle](../../print_reverse_oracle.py) returns the expected UTF-8 bytes and ABI status.

Pinned source: [TheAlgorithms/Python `print_reverse.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/linked_list/print_reverse.py), function `in_reverse`.

| Language | Port |
|---|---|
| C | [`c/p/print_reverse.c`](../../../c/p/print_reverse.c) |
| C3 | [`c3/p/print_reverse.c3`](../../../c3/p/print_reverse.c3) |
| C++ | [`cpp/p/print_reverse.cpp`](../../../cpp/p/print_reverse.cpp) |
| Elisa | [`elisa/p/print_reverse.elisa`](../../../elisa/p/print_reverse.elisa) |
| Nim | [`nim/p/print_reverse.nim`](../../../nim/p/print_reverse.nim) |
| Odin | [`odin/p/print_reverse.odin`](../../../odin/p/print_reverse.odin) |
| Rust | [`rust/p/print_reverse.rs`](../../../rust/p/print_reverse.rs) |
| V | [`v/p/print_reverse.v`](../../../v/p/print_reverse.v) |
| Zig | [`zig/p/print_reverse.zig`](../../../zig/p/print_reverse.zig) |
