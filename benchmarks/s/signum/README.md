# Signum

## Contract

Return `-1` for a negative signed 64-bit integer, `0` for zero, and `1` for a positive signed 64-bit integer. The implementation uses comparisons, so it handles both signed endpoints without negating the input.

The exported C ABI entry point is:

```c
int64_t signum(int64_t value);
```

The pinned JavaScript, Python, and Rust sources accept real-number inputs. The shared benchmark selects the integer domain supported by the scalar ABI; fractional values, NaN, and infinities are outside this workload.

## Workload and verification

[`workload.json`](workload.json) includes signed boundaries, negative values, zero, and positive values. [`verify_scalar.py`](../../verify_scalar.py) checks every integer from -1,024 through 1,024, deterministic full-width signed values, and both 64-bit endpoints against the comparison oracle before checking the recording flow.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/signum.c`](../../../c/s/signum.c) |
| C3 | [`c3/s/signum.c3`](../../../c3/s/signum.c3) |
| C++ | [`cpp/s/signum.cpp`](../../../cpp/s/signum.cpp) |
| Elisa | [`elisa/s/signum.elisa`](../../../elisa/s/signum.elisa) |
| Nim | [`nim/s/signum.nim`](../../../nim/s/signum.nim) |
| Odin | [`odin/s/signum.odin`](../../../odin/s/signum.odin) |
| Rust | [`rust/s/signum.rs`](../../../rust/s/signum.rs) |
| V | [`v/s/signum.v`](../../../v/s/signum.v) |
| Zig | [`zig/s/signum.zig`](../../../zig/s/signum.zig) |

All nine implementations are portable and use the same signed 64-bit contract.

## TheAlgorithms references

- [JavaScript `Signum.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/Signum.js)
- [Python `signum.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/signum.py)
- [Rust `signum.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/signum.rs)
- [TypeScript `signum.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/signum.ts)
