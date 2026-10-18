# Lua `uint` base conversion

This benchmark maps to `uint:convert_base_to` in the pinned Lua implementation. It keeps Lua's unsigned integer representation as canonical little-endian digits in a configurable base from 2 through 2^26. The conversion is exact and has no fixed-width overflow.

## Contract

The ABI is `i64_array_bytes_output`. Input is `[source_base, target_base, digit_count, digit_0, ..., digit_(digit_count-1)]`. Digits are little-endian and each lies in `[0, source_base-1]`. A zero is represented by `digit_count = 0`; otherwise the most-significant digit must be nonzero. The digit count is 0 through 64 and the input length must be exactly `3 + digit_count`.

The adapter constructs the source value with `uint.from_digits`, calls `convert_base_to` using a `uint` class for `target_base`, and returns its canonical target-base digits in little-endian order. Each output digit is one unsigned 32-bit little-endian word; no count header is included. The result is the byte count, so the digit count is `result / 4`. Zero produces an empty output. A null output pointer returns `-2` even for zero; capacity 0 succeeds for the empty result. Insufficient capacity returns `-2` without writes. Invalid input returns `-1` before output checks.

The source accepts bases in `[2, 2^26]`, keeping digit products within exact Lua-number integer bounds. The 64-digit input cap bounds output to at most 1664 binary digits (6656 bytes), attained when converting a maximum-base value to base 2. Division and modulo are not part of this contract because the source marks them unimplemented.

## Pinned source

[TheAlgorithms/Lua `uint.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/math/uint.lua), commit `cedc141018ad48884318fe08a6db278664b17128`, function `uint:convert_base_to`.

The independent oracle is [`uint_oracle.py`](../../uint_oracle.py); workload cases are in [`workload.json`](workload.json).

## Ports

| Language | Source |
| --- | --- |
| C | [`c/u/uint.c`](../../../c/u/uint.c) |
| C3 | [`c3/u/uint.c3`](../../../c3/u/uint.c3) |
| C++ | [`cpp/u/uint.cpp`](../../../cpp/u/uint.cpp) |
| Elisa | [`elisa/u/uint.elisa`](../../../elisa/u/uint.elisa) |
| Nim | [`nim/u/uint.nim`](../../../nim/u/uint.nim) |
| Odin | [`odin/u/uint.odin`](../../../odin/u/uint.odin) |
| Rust | [`rust/u/uint.rs`](../../../rust/u/uint.rs) |
| V | [`v/u/uint.v`](../../../v/u/uint.v) |
| Zig | [`zig/u/uint.zig`](../../../zig/u/uint.zig) |
