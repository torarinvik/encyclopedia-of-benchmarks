# ADTFraction

Port of the pinned Java `ADTFraction` record. It stores the numerator and denominator as supplied; it does not normalize signs or reduce by a greatest common divisor. The source exposes addition, multiplication by an integer, fraction multiplication, reciprocal, and a binary32 `value()` result.

Source: [TheAlgorithms/Java `ADTFraction.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/ADTFraction.java).

## Contract

The `i64_array_scalar` input is exactly `[operation, numerator, denominator, other_numerator, other_denominator]`. Selectors are `0` add the two fractions, `1` multiply by `other_numerator` as an integer, `2` multiply by the second fraction, `3` reciprocal, and `4` return `value()`.

Each input slot must be in `[-100000, 100000]`; fraction denominators must be nonzero. The source's Java `int` numerator and denominator arithmetic wraps modulo 2^32. Operations that would construct a zero denominator, or take the reciprocal of a zero numerator, return `-1` in this ABI to represent the source constructor's exception. The result for selectors 0–3 packs the signed 32-bit numerator in the high word and the denominator's raw 32-bit representation in the low word, interpreted as a signed 64-bit integer. Selector 4 returns the IEEE-754 binary32 result bits as a nonnegative integer, preserving negative zero.

## Workload and implementations

The workload includes positive and negative denominators, every source operation, negative zero, and Java `int` overflow during fraction addition. The benchmark uses the shared i64-array/scalar ABI.

| Language | Source |
|---|---|
| C | [`c/a/adtfraction.c`](../../../c/a/adtfraction.c) |
| C3 | [`c3/a/adtfraction.c3`](../../../c3/a/adtfraction.c3) |
| C++ | [`cpp/a/adtfraction.cpp`](../../../cpp/a/adtfraction.cpp) |
| Elisa | [`elisa/a/adtfraction.elisa`](../../../elisa/a/adtfraction.elisa) |
| Nim | [`nim/a/adtfraction.nim`](../../../nim/a/adtfraction.nim) |
| Odin | [`odin/a/adtfraction.odin`](../../../odin/a/adtfraction.odin) |
| Rust | [`rust/a/adtfraction.rs`](../../../rust/a/adtfraction.rs) |
| V | [`v/a/adtfraction.v`](../../../v/a/adtfraction.v) |
| Zig | [`zig/a/adtfraction.zig`](../../../zig/a/adtfraction.zig) |
