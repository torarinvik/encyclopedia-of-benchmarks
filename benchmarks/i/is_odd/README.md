# Is odd

## Contract

Return `1` when the signed 64-bit integer is odd, and `0` when it is even.
Remainder comparison covers the full signed range, including `INT64_MIN`.

The exported C ABI entry point is:

```c
int64_t is_odd(int64_t value);
```

The JavaScript source exposes both modulo and bitwise variants. The TypeScript
source checks integer input before testing its remainder. This benchmark uses
the signed 64-bit integer domain shared by all nine target languages and
returns an integer `0`/`1` result.

## Workload

[`workload.json`](workload.json) includes negative and positive odd/even values,
zero, and the signed endpoints.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/i/is_odd.c`](../../../c/i/is_odd.c) |
| C3 | [`c3/i/is_odd.c3`](../../../c3/i/is_odd.c3) |
| C++ | [`cpp/i/is_odd.cpp`](../../../cpp/i/is_odd.cpp) |
| Elisa | [`elisa/i/is_odd.elisa`](../../../elisa/i/is_odd.elisa) |
| Nim | [`nim/i/is_odd.nim`](../../../nim/i/is_odd.nim) |
| Odin | [`odin/i/is_odd.odin`](../../../odin/i/is_odd.odin) |
| Rust | [`rust/i/is_odd.rs`](../../../rust/i/is_odd.rs) |
| V | [`v/i/is_odd.v`](../../../v/i/is_odd.v) |
| Zig | [`zig/i/is_odd.zig`](../../../zig/i/is_odd.zig) |

## TheAlgorithms references

- [JavaScript `IsOdd.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/IsOdd.js)
- [TypeScript `is_odd.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/is_odd.ts)
