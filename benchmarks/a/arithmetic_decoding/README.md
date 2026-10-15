# Arithmetic Decoding

This benchmark ports the decompression operation from the pinned [TheAlgorithms/Java `ArithmeticCoding`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/compression/ArithmeticCoding.java). The source scans its symbol intervals in character order and selects the interval containing the compressed value. The shared contract supplies that probability model explicitly and represents the compressed value as the exact lower-bound numerator from the paired [arithmetic coding benchmark](../arithmetic_coding/README.md).

The `i64_array_bytes_output` input is `[symbol_count, alphabet_size, lower_bound_numerator, symbol_0, frequency_0, ...]`. Symbols are byte values in strictly increasing order; each frequency is positive and all frequencies sum to `symbol_count`. The numerator represents a value over `symbol_count ** symbol_count`. The benchmark returns the decoded message bytes, with exactly `symbol_count` bytes. Invalid input returns `-1`; insufficient output capacity or a missing output buffer returns `-2`.

The symbol count is 1–12 and the alphabet contains 1–`symbol_count` entries. The lower-bound numerator must be in `[0, symbol_count ** symbol_count)`. Exact integer interval comparisons reproduce the source's half-open interval selection without floating-point rounding. Runtime is O(n × k), where `n` is the message length and `k` is the number of symbols in the model; auxiliary space is O(k).

[`workload.json`](workload.json) covers decode boundaries, different frequency models, and malformed inputs.

| Language | Implementation |
| --- | --- |
| C | [`c/a/arithmetic_decoding.c`](../../../c/a/arithmetic_decoding.c) |
| C3 | [`c3/a/arithmetic_decoding.c3`](../../../c3/a/arithmetic_decoding.c3) |
| C++ | [`cpp/a/arithmetic_decoding.cpp`](../../../cpp/a/arithmetic_decoding.cpp) |
| Elisa | [`elisa/a/arithmetic_decoding.elisa`](../../../elisa/a/arithmetic_decoding.elisa) |
| Nim | [`nim/a/arithmetic_decoding.nim`](../../../nim/a/arithmetic_decoding.nim) |
| Odin | [`odin/a/arithmetic_decoding.odin`](../../../odin/a/arithmetic_decoding.odin) |
| Rust | [`rust/a/arithmetic_decoding.rs`](../../../rust/a/arithmetic_decoding.rs) |
| V | [`v/a/arithmetic_decoding.v`](../../../v/a/arithmetic_decoding.v) |
| Zig | [`zig/a/arithmetic_decoding.zig`](../../../zig/a/arithmetic_decoding.zig) |
