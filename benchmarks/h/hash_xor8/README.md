# XOR8 hash

Benchmark the pinned C implementation named `xor8`. Its code sums the ASCII
characters modulo 256 and returns the 8-bit two's complement of that sum.

## Contract

- Input uses the `i64_array_scalar` ABI. Values before the first zero byte must
  be ASCII bytes in `0..=127`; arrays may contain up to 100,001 values.
- The first zero byte acts as the C-string terminator. Values after it are
  ignored by the algorithm. An array with no zero byte is treated as ending
  at its array boundary. Empty input returns `0`.
- Starting from `hash = 0`, for each character before the first zero set
  `hash = (hash + byte) & 0xff`. Return `((hash ^ 0xff) + 1) & 0xff`, the
  two's complement modulo 256.
- Arrays longer than the supported limit or containing a value outside
  `0..=127` before the first zero byte return `-1`. Values after the terminator
  are ignored, including values outside the ASCII range.

The name says XOR, but the pinned routine does not XOR the characters together:
it adds them, then applies two's-complement finalization. The ASCII-byte domain
avoids the signed-`char` differences that the C source would have for bytes
above 127.

## Pinned source

The pinned [C `hash_xor8.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/hash/hash_xor8.c)
accepts a NUL-terminated string, keeps an 8-bit sum, and returns the finalized
byte. Its examples include `Hello World` → 228 and `Hello World!` → 195.

## Workload and build

[`workload.json`](workload.json) includes the source examples, empty and
single-character strings, embedded terminators, and invalid bytes before and
after the terminator. The independent oracle is
[`hash_xor8_oracle.py`](../../hash_xor8_oracle.py).
Build and record with:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm hash_xor8 --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/h/hash_xor8/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms hash_xor8
```

| Language | Source |
| --- | --- |
| C | [`c/h/hash_xor8.c`](../../../c/h/hash_xor8.c) |
| C3 | [`c3/h/hash_xor8.c3`](../../../c3/h/hash_xor8.c3) |
| C++ | [`cpp/h/hash_xor8.cpp`](../../../cpp/h/hash_xor8.cpp) |
| Elisa | [`elisa/h/hash_xor8.elisa`](../../../elisa/h/hash_xor8.elisa) |
| Nim | [`nim/h/hash_xor8.nim`](../../../nim/h/hash_xor8.nim) |
| Odin | [`odin/h/hash_xor8.odin`](../../../odin/h/hash_xor8.odin) |
| Rust | [`rust/h/hash_xor8.rs`](../../../rust/h/hash_xor8.rs) |
| V | [`v/h/hash_xor8.v`](../../../v/h/hash_xor8.v) |
| Zig | [`zig/h/hash_xor8.zig`](../../../zig/h/hash_xor8.zig) |
