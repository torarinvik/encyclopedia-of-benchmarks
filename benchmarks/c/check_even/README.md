# Check even

Checks whether a signed 64-bit integer is even using the remainder test from the pinned PHP source.

## Contract

The exported C ABI entry point is:

```c
int64_t check_even(int64_t value);
```

Return `1` when `value % 2 == 0`, otherwise return `0`. The full signed 64-bit range is supported, including `INT64_MIN`; the algorithm does not negate or otherwise transform the input.

## Workload

[`workload.json`](workload.json) covers zero, positive and negative odd/even values, and both signed endpoints.

Verify the nine ports against the independent oracle with `python3 benchmarks/verify_scalar.py --algorithms check_even`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/check_even.c`](../../../c/c/check_even.c) |
| C3 | [`c3/c/check_even.c3`](../../../c3/c/check_even.c3) |
| C++ | [`cpp/c/check_even.cpp`](../../../cpp/c/check_even.cpp) |
| Elisa | [`elisa/c/check_even.elisa`](../../../elisa/c/check_even.elisa) |
| Nim | [`nim/c/check_even.nim`](../../../nim/c/check_even.nim) |
| Odin | [`odin/c/check_even.odin`](../../../odin/c/check_even.odin) |
| Rust | [`rust/c/check_even.rs`](../../../rust/c/check_even.rs) |
| V | [`v/c/check_even.v`](../../../v/c/check_even.v) |
| Zig | [`zig/c/check_even.zig`](../../../zig/c/check_even.zig) |

## Pinned source

- [PHP `CheckEven.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Maths/CheckEven.php)
- Related odd predicate: [PHP `CheckOdd.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Maths/CheckOdd.php), mapped to the existing [`is_odd`](../../i/is_odd/README.md) benchmark.
