# C++ `uint128_t` division and remainder

This benchmark maps to the pinned C++ `uint128_t::divide`, `/`, and `%` operations. The value is an unsigned 128-bit integer represented internally by two 64-bit halves. Division and remainder are measured as distinct operations.

## Contract

The ABI is `i64_array_bytes_output`. Input is `[operation, dividend_limb_0, ..., dividend_limb_3, divisor_limb_0, ..., divisor_limb_3]`. Each operand is four little-endian unsigned 32-bit limbs carried in signed i64 words. Operation 0 returns the integer quotient; operation 1 returns the remainder. The divisor must be nonzero. The input length must be exactly 9.

Output is the full 16-byte unsigned result in little-endian byte order, equivalent to four little-endian 32-bit limbs. Leading zero limbs remain present. The return value is 16 on success. Invalid input, including a zero divisor or malformed limb, returns `-1` before output checks. A null output pointer or capacity below 16 returns `-2` without writes.

The two pinned repository copies have matching division and arithmetic operator bodies. A raw-source comparison records only non-semantic differences: the additional copy has three `std` type-trait specializations and a named unused post-decrement parameter; include lists differ. The arithmetic behavior therefore shares this width-specific contract. Zero divisors are excluded because the source implementation does not define division-by-zero behavior.

## Pinned sources

- [TheAlgorithms/C-Plus-Plus `uint128_t.hpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/ciphers/uint128_t.hpp), commit `fdcc29b0ac2848e9d1a8d926e171cc5b39f97759`.
- [TheAlgorithms/C-Plus-Plus-1 `uint128_t.hpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/ciphers/uint128_t.hpp), commit `0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680`.

The independent Python-integer oracle is [`uint128_t_oracle.py`](../../uint128_t_oracle.py); workload cases are in [`workload.json`](workload.json).

## Ports

| Language | Source |
| --- | --- |
| C | [`c/u/uint128_t.c`](../../../c/u/uint128_t.c) |
| C3 | [`c3/u/uint128_t.c3`](../../../c3/u/uint128_t.c3) |
| C++ | [`cpp/u/uint128_t.cpp`](../../../cpp/u/uint128_t.cpp) |
| Elisa | [`elisa/u/uint128_t.elisa`](../../../elisa/u/uint128_t.elisa) |
| Nim | [`nim/u/uint128_t.nim`](../../../nim/u/uint128_t.nim) |
| Odin | [`odin/u/uint128_t.odin`](../../../odin/u/uint128_t.odin) |
| Rust | [`rust/u/uint128_t.rs`](../../../rust/u/uint128_t.rs) |
| V | [`v/u/uint128_t.v`](../../../v/u/uint128_t.v) |
| Zig | [`zig/u/uint128_t.zig`](../../../zig/u/uint128_t.zig) |
