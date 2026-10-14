# Is even

## Contract

Return `1` when the signed 64-bit integer is even, and `0` when it is odd. The modulo-based implementation covers the full signed 64-bit range, including `INT64_MIN`.

The exported C ABI entry point is:

```c
int64_t is_even(int64_t value);
```

The inspected sources use both parity and bitwise checks and have differing host-language input types. This benchmark standardizes on signed 64-bit integers and an integer `0`/`1` result.

## Workload and verification

[`workload.json`](workload.json) includes negative and positive odd/even values, zero, and the signed endpoints. [`verify_scalar.py`](../../verify_scalar.py) checks every integer from -1,024 through 1,024, deterministic full-width values, and both signed endpoints before checking the recording flow.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/i/is_even.c`](../../../c/i/is_even.c) |
| C3 | [`c3/i/is_even.c3`](../../../c3/i/is_even.c3) |
| C++ | [`cpp/i/is_even.cpp`](../../../cpp/i/is_even.cpp) |
| Elisa | [`elisa/i/is_even.elisa`](../../../elisa/i/is_even.elisa) |
| Nim | [`nim/i/is_even.nim`](../../../nim/i/is_even.nim) |
| Odin | [`odin/i/is_even.odin`](../../../odin/i/is_even.odin) |
| Rust | [`rust/i/is_even.rs`](../../../rust/i/is_even.rs) |
| V | [`v/i/is_even.v`](../../../v/i/is_even.v) |
| Zig | [`zig/i/is_even.zig`](../../../zig/i/is_even.zig) |

All nine implementations use the same ABI and portable integer operations.

## TheAlgorithms references

- [Java `IsEven.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/IsEven.java)
- [JavaScript `IsEven.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/IsEven.js)
- [Python `is_even.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/bit_manipulation/is_even.py)
- [TypeScript `is_even.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/is_even.ts)
