# Balanced ternary conversion

Convert a signed 64-bit integer to canonical balanced ternary. Digits are
`-1`, `0`, and `1`; the letter `Z` represents `-1`, so negative integers need
no separate sign. The encoding is most-significant digit first.

## Contract

The `i64_array_bytes_output` symbol is `balanced_ternary_conversion`. Input is
exactly `[value]`, where `value` may be any signed 64-bit integer. The output
is the ASCII byte sequence over `Z01`, with no terminator. Zero is encoded as
`0`; every other result has no leading zero. The largest signed 64-bit value
in magnitude needs at most 41 digits, so maximum output and workspace capacity
are 41 bytes. Invalid input returns `-1`. Null or insufficient output capacity
returns `-2` without writes.

The primary repeatedly divides by three, correcting remainders `2` and `-2`
into a balanced digit and a carry to the next quotient. The independent oracle
first forms ordinary base-three digits for the magnitude, propagates carry
through `2` and `3`, then inverts every digit for negative inputs. Both take
`O(log |value|)` time and `O(log |value|)` temporary storage.

## Distinctness and provenance

[`any_base_to_any_base`](../any_base_to_any_base/README.md) and
[`decimal_to_any_base`](../decimal_to_any_base/README.md) use nonnegative digits
in ordinary radices 2 through 36. [`base_neg2_conversion`](../base_neg2_conversion/README.md)
uses radix -2 with digits 0 and 1. This package instead normalizes signed
digits in radix +3 and represents negative values without a sign.

The conversion method is described in [CP-Algorithms, “Balanced Ternary”](https://cp-algorithms.com/algebra/balanced-ternary.html),
licensed CC BY-SA 4.0. Only its algorithm description was used; the contract,
oracles, workload, and ten ports are clean-room work. See [`RIGHTS.md`](RIGHTS.md),
[`workload.json`](workload.json), the [primary oracle](../../balanced_ternary_conversion_oracle.py),
the [independent verifier](../../balanced_ternary_conversion_verifier_oracle.py),
and the [static inventory checker](../../check_balanced_ternary_conversion_package.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/b/balanced_ternary_conversion.c`](../../../c/b/balanced_ternary_conversion.c) |
| C3 | [`c3/b/balanced_ternary_conversion.c3`](../../../c3/b/balanced_ternary_conversion.c3) |
| C++ | [`cpp/b/balanced_ternary_conversion.cpp`](../../../cpp/b/balanced_ternary_conversion.cpp) |
| Elisa | [`elisa/b/balanced_ternary_conversion.elisa`](../../../elisa/b/balanced_ternary_conversion.elisa) |
| Mojo | [`mojo/b/balanced_ternary_conversion.mojo`](../../../mojo/b/balanced_ternary_conversion.mojo) |
| Nim | [`nim/b/balanced_ternary_conversion.nim`](../../../nim/b/balanced_ternary_conversion.nim) |
| Odin | [`odin/b/balanced_ternary_conversion.odin`](../../../odin/b/balanced_ternary_conversion.odin) |
| Rust | [`rust/b/balanced_ternary_conversion.rs`](../../../rust/b/balanced_ternary_conversion.rs) |
| V | [`v/b/balanced_ternary_conversion.v`](../../../v/b/balanced_ternary_conversion.v) |
| Zig | [`zig/b/balanced_ternary_conversion.zig`](../../../zig/b/balanced_ternary_conversion.zig) |
