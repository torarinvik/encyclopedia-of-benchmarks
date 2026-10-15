# Hexagonal number

The pinned JavaScript and Python implementations return the `n`th hexagonal number using `n * (2*n - 1)` and require a positive integer index.

## Contract

- Input is one signed 64-bit integer `n` in `[1, 67,108,864]`.
- Valid input returns `n * (2*n - 1)`; invalid input returns `-1`.
- The upper bound is the largest index for which the result is at most `2^53 - 1`, so the JavaScript source's binary64 result remains an exact integer. The next index exceeds that exact-integer limit.
- The largest result in the contract is `9,007,199,187,632,128`, which fits signed 64-bit range.

## Workload

[`workload.json`](workload.json) covers source examples, the first values, the JavaScript exact-integer boundary, and invalid input boundaries.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/hexagonal_number.c`](../../../c/h/hexagonal_number.c) |
| C3 | [`c3/h/hexagonal_number.c3`](../../../c3/h/hexagonal_number.c3) |
| C++ | [`cpp/h/hexagonal_number.cpp`](../../../cpp/h/hexagonal_number.cpp) |
| Elisa | [`elisa/h/hexagonal_number.elisa`](../../../elisa/h/hexagonal_number.elisa) |
| Nim | [`nim/h/hexagonal_number.nim`](../../../nim/h/hexagonal_number.nim) |
| Odin | [`odin/h/hexagonal_number.odin`](../../../odin/h/hexagonal_number.odin) |
| Rust | [`rust/h/hexagonal_number.rs`](../../../rust/h/hexagonal_number.rs) |
| V | [`v/h/hexagonal_number.v`](../../../v/h/hexagonal_number.v) |
| Zig | [`zig/h/hexagonal_number.zig`](../../../zig/h/hexagonal_number.zig) |

## Upstream sources

- [TheAlgorithms/JavaScript `HexagonalNumber.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/HexagonalNumber.js)
- [TheAlgorithms/Python `hexagonal_number.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/special_numbers/hexagonal_number.py)
