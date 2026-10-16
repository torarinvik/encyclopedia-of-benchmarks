# Lyndon factorization

The pinned Java `LyndonFactorization.factorize` uses Duval's algorithm. It compares UTF-16 code units and emits the standard Lyndon factors in non-increasing lexicographic order. When the matched period is shorter than the current word, the source emits that factor repeatedly before continuing.

## Contract

Input is `[n, byte_0, ..., byte_(n-1)]`, where `n` is from 0 through 256 and each byte is lowercase ASCII (`a` through `z`). Lowercase ASCII preserves Java's code-unit ordering while avoiding differences in Unicode representation between ports. Output concatenates each factor followed by a zero byte; empty input produces no factors and empty output. The output buffer must have at least `2*n` bytes, the maximum encoded size. Invalid input returns `-1`, and insufficient output capacity returns `-2` before writing.

The implementation uses the source's linear scan. See [workload](workload.json), [oracle](../../lyndon_factorization_oracle.py), and the pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/LyndonFactorization.java).

| Language | Port |
|---|---|
| C | c/l/lyndon_factorization.c |
| C3 | c3/l/lyndon_factorization.c3 |
| C++ | cpp/l/lyndon_factorization.cpp |
| Elisa | elisa/l/lyndon_factorization.elisa |
| Nim | nim/l/lyndon_factorization.nim |
| Odin | odin/l/lyndon_factorization.odin |
| Rust | rust/l/lyndon_factorization.rs |
| V | v/l/lyndon_factorization.v |
| Zig | zig/l/lyndon_factorization.zig |
