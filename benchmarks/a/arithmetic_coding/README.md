# Arithmetic Coding

This benchmark is based on the pinned [TheAlgorithms/Java `ArithmeticCoding`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/compression/ArithmeticCoding.java). Its compressor builds a character-frequency model, orders symbols by character value, and narrows a `[low, high)` interval for each input symbol. The benchmark ports that encoder operation; it does not include the source's separate decompressor.

The source's inverse operation is available as the paired [arithmetic decoding benchmark](../arithmetic_decoding/README.md), which accepts the model and encoded interval endpoint explicitly.

The `i64_array_scalar` input is `[symbol_count, symbol_0, ..., symbol_n]`. Symbols are byte values from 0 through 255. The count is 1 through 12, and the input must contain exactly that many symbols. Invalid input returns `-1`.

To make the result exact and consistent across languages, the contract represents the final lower interval bound as an integer numerator over `symbol_count ** symbol_count`. It returns that numerator. The denominator is determined by the input count. The source uses `BigDecimal` with `DECIMAL128` when calculating probabilities; this bounded contract uses the equivalent exact rational frequencies rather than floating-point interval endpoints. With at most 12 symbols, the largest denominator is `12 ** 12`, which fits in signed 64-bit arithmetic.

The interval starts at `[0, 1)`. For each symbol, its subinterval is selected from the cumulative frequencies of the byte-sorted alphabet. Runtime is O(σ + n), where `σ=256` and `n` is the message length; auxiliary space is O(σ).

[`workload.json`](workload.json) covers repeated and distinct symbols, ordering, small intervals, and invalid input.

| Language | Implementation |
| --- | --- |
| C | [`c/a/arithmetic_coding.c`](../../../c/a/arithmetic_coding.c) |
| C3 | [`c3/a/arithmetic_coding.c3`](../../../c3/a/arithmetic_coding.c3) |
| C++ | [`cpp/a/arithmetic_coding.cpp`](../../../cpp/a/arithmetic_coding.cpp) |
| Elisa | [`elisa/a/arithmetic_coding.elisa`](../../../elisa/a/arithmetic_coding.elisa) |
| Nim | [`nim/a/arithmetic_coding.nim`](../../../nim/a/arithmetic_coding.nim) |
| Odin | [`odin/a/arithmetic_coding.odin`](../../../odin/a/arithmetic_coding.odin) |
| Rust | [`rust/a/arithmetic_coding.rs`](../../../rust/a/arithmetic_coding.rs) |
| V | [`v/a/arithmetic_coding.v`](../../../v/a/arithmetic_coding.v) |
| Zig | [`zig/a/arithmetic_coding.zig`](../../../zig/a/arithmetic_coding.zig) |
