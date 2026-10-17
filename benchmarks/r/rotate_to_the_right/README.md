# Rotate to the right

This package ports `rotate_to_the_right` from the pinned Python singly linked-list implementation. It rotates a nonempty list to the right by `places`; Python's modulo operation reduces the rotation and normalizes negative values. The pinned function raises `ValueError("The linked list is empty.")` for an empty list and returns a singleton unchanged.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[n, places, value_0, ..., value_(n-1)]`. The length must be exactly `n + 2`; `n` is 1..64, `places` is -1,000,000..1,000,000, and each value fits signed i32.
- Rotate the values right by `places % n`, with the remainder normalized to 0..n-1 as in Python. Duplicate and negative values are retained in their original relative order.
- The output contains the rotated values as little-endian signed-i64 values, with no count prefix. The function returns `8*n` bytes, up to 512.
- Empty lists, malformed input, out-of-range fields, and null input return `-1`. Invalid input is checked before output storage. A null output pointer or a short capacity returns `-2` without writes.

The packed value array cannot represent pointer cycles, so cycles are outside this bounded input format.

The pinned function first measures the list, computes the cut point, detaches the suffix, and links the old tail to the old head. The benchmark input represents list contents directly, so ports compute the same cut point and serialize the rotated sequence without measuring node allocation or list construction.

## Workload and source

[`workload.json`](workload.json) covers positive and negative rotations, multiples of the list length, a singleton, signed and duplicate values, maximum size, malformed input, and output-capacity errors. The independent [oracle](../../rotate_to_the_right_oracle.py) computes the normalized rotation and serializes each result as a signed-i64 little-endian value.

Pinned source: [TheAlgorithms/Python `rotate_to_the_right.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/linked_list/rotate_to_the_right.py), function `rotate_to_the_right`.

| Language | Port |
|---|---|
| C | [`c/r/rotate_to_the_right.c`](../../../c/r/rotate_to_the_right.c) |
| C3 | [`c3/r/rotate_to_the_right.c3`](../../../c3/r/rotate_to_the_right.c3) |
| C++ | [`cpp/r/rotate_to_the_right.cpp`](../../../cpp/r/rotate_to_the_right.cpp) |
| Elisa | [`elisa/r/rotate_to_the_right.elisa`](../../../elisa/r/rotate_to_the_right.elisa) |
| Nim | [`nim/r/rotate_to_the_right.nim`](../../../nim/r/rotate_to_the_right.nim) |
| Odin | [`odin/r/rotate_to_the_right.odin`](../../../odin/r/rotate_to_the_right.odin) |
| Rust | [`rust/r/rotate_to_the_right.rs`](../../../rust/r/rotate_to_the_right.rs) |
| V | [`v/r/rotate_to_the_right.v`](../../../v/r/rotate_to_the_right.v) |
| Zig | [`zig/r/rotate_to_the_right.zig`](../../../zig/r/rotate_to_the_right.zig) |
