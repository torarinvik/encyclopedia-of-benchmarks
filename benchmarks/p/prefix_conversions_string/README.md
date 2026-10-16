# Automatic prefix formatting

The pinned Python module provides `add_si_prefix` and `add_binary_prefix`. Each scans its descending prefix enum and returns the first value/prefix pair whose quotient is greater than one; otherwise it returns `str(value)`. For nonpositive values the SI function scans only negative SI exponents, but its strict positive quotient check never matches, so it returns the original representation.

## Contract

Input is `[mode, integer_value]`, where mode 0 selects SI and mode 1 selects binary. Values are bounded to `[-10^12, 10^12]`. Positive values that select a prefix must be divisible by that prefix's scale, ensuring exact quotient formatting as `<integer>.0 <prefix>`; other positive values return their decimal integer string if no prefix threshold is exceeded. Nonpositive values return their signed decimal integer string. Positive values that exceed a threshold but are not divisible by the selected scale, invalid modes, and out-of-range values return `-1`.

The domain limit means larger SI and binary entries cannot be selected. Binary exponents in the source are powers of two; for the bounded domain the selectable scales are 2^30, 2^20, and 2^10. Output is ASCII bytes.

See [`workload.json`](workload.json) and the runtime [oracle](../../prefix_conversions_string_oracle.py). Pinned source: [TheAlgorithms/Python `prefix_conversions_string.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/prefix_conversions_string.py).

| Language | Port |
|---|---|
| C | [`c/p/prefix_conversions_string.c`](../../../c/p/prefix_conversions_string.c) |
| C3 | [`c3/p/prefix_conversions_string.c3`](../../../c3/p/prefix_conversions_string.c3) |
| C++ | [`cpp/p/prefix_conversions_string.cpp`](../../../cpp/p/prefix_conversions_string.cpp) |
| Elisa | [`elisa/p/prefix_conversions_string.elisa`](../../../elisa/p/prefix_conversions_string.elisa) |
| Nim | [`nim/p/prefix_conversions_string.nim`](../../../nim/p/prefix_conversions_string.nim) |
| Odin | [`odin/p/prefix_conversions_string.odin`](../../../odin/p/prefix_conversions_string.odin) |
| Rust | [`rust/p/prefix_conversions_string.rs`](../../../rust/p/prefix_conversions_string.rs) |
| V | [`v/p/prefix_conversions_string.v`](../../../v/p/prefix_conversions_string.v) |
| Zig | [`zig/p/prefix_conversions_string.zig`](../../../zig/p/prefix_conversions_string.zig) |
