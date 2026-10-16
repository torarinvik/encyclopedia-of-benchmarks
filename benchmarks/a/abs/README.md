# Absolute value

This benchmark returns the nonnegative magnitude of a signed integer. The reviewed `abs` sources include generic integer and floating-point functions, an ordinary sign check, and a Go bit-manipulation variant. The shared benchmark selects signed 64-bit integers and returns `-1` for `INT64_MIN`, whose positive magnitude cannot be represented by the result type.

## Contract

- Input is any signed 64-bit integer.
- For every input except `INT64_MIN`, the result is its nonnegative magnitude.
- `INT64_MIN` returns `-1` to signal signed 64-bit result overflow.
- The C ABI symbol is `abs_i64`, keeping the benchmark name `abs` separate from the standard C library's `abs` symbol.
- Implementations use portable comparison and negation; no architecture-specific instructions are used.

## Workload and verification

[`workload.json`](workload.json) covers zero, both signs, signed 32-bit and 64-bit boundaries, and the unrepresentable minimum magnitude. [`verify_abs.py`](../../verify_abs.py) checks the ports against Python's arbitrary-precision `abs` oracle on exhaustive small values, boundary cases, and deterministic random signed 64-bit inputs.

## Reviewed TheAlgorithms sources

- [Java `AbsoluteValue.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/AbsoluteValue.java) and [TypeScript `absolute_value.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/absolute_value.ts) expose the same integer mapping, subject to the benchmark's signed 64-bit overflow contract.
- [Rust `abs.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/abs.rs) — generic signed numeric absolute value.
- [Nim `abs.nim`](https://github.com/TheAlgorithms/Nim/blob/63eec16614b46c91078653e8d3c049fe99ad36b3/maths/abs.nim) — integer and floating-point variants, plus absolute min/max helpers.
- [Python `abs.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/abs.py) — numeric magnitude and absolute min/max helpers.
- [Go binary `abs.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/binary/abs.go) — bitwise absolute value.

The separate `absolute_value` filename candidate describes the same integer mapping and is cataloged as an alias. Generic floating-point helpers and sequence min/max helpers are outside this benchmark contract.
