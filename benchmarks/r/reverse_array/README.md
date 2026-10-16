# Reverse array

Reverse a nonempty bounded byte array in place using two pointers moving inward. The pinned Python and JavaScript implementations return the reversed array, while the Solidity implementation exposes the same operation through a pure contract method.

## Contract

- Input is `[n, value_0, ..., value_(n-1)]`, where `n` is 1 through 256 and each value is a byte in 0 through 255.
- The benchmark excludes empty arrays because the Solidity source computes `length - 1` with unsigned arithmetic and reverts on an empty array.
- Output is the reversed byte sequence. Return the output length on success, `-1` for invalid shape or values, and `-2` if the output buffer is too small.
- The source mutates its array; the ABI adapter copies into the output buffer and performs the same inward swaps there.

[`workload.json`](workload.json) covers singleton, even and odd lengths, duplicates, byte boundaries, maximum size, malformed counts, and invalid values. The independent oracle is [`reverse_array_oracle.py`](../../reverse_array_oracle.py).

## Pinned sources

- [Python `reverse_array.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/arrays/reverse_array.py)
- [Solidity `ReverseArray.sol`](https://github.com/TheAlgorithms/Solidity/blob/08cba51fb38e276062b0c9791d7e0ee494ffa903/src/Maths/ReverseArray.sol)
- [JavaScript `Reverse.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Array/Reverse.js)

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm reverse_array --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm reverse_array
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/reverse_array.c`](../../../c/r/reverse_array.c) |
| C3 | [`c3/r/reverse_array.c3`](../../../c3/r/reverse_array.c3) |
| C++ | [`cpp/r/reverse_array.cpp`](../../../cpp/r/reverse_array.cpp) |
| Elisa | [`elisa/r/reverse_array.elisa`](../../../elisa/r/reverse_array.elisa) |
| Nim | [`nim/r/reverse_array.nim`](../../../nim/r/reverse_array.nim) |
| Odin | [`odin/r/reverse_array.odin`](../../../odin/r/reverse_array.odin) |
| Rust | [`rust/r/reverse_array.rs`](../../../rust/r/reverse_array.rs) |
| V | [`v/r/reverse_array.v`](../../../v/r/reverse_array.v) |
| Zig | [`zig/r/reverse_array.zig`](../../../zig/r/reverse_array.zig) |
