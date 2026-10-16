# Binomial Expansion

This package evaluates the binomial expansion of `(a + b)^n` by summing `C(n, i) * a^(n-i) * b^i` for every `i` from zero through `n`. Input is `[a, b, n]`; the array must contain exactly three signed 64-bit integers.

The contract uses the exact integer subset of the pinned Python API: `a` and `b` are integers in `[-2, 2]`, and the exponent is in `[0, 31]`. The source annotates `a` and `b` as floats and supports negative exponents, but this package excludes those cases so all nine ports return the same exact integer result. For these bounds, the sum of the absolute term values is at most `(|a| + |b|)^n <= 4^31`, which fits in signed 64-bit arithmetic. Malformed input or an out-of-domain value returns `-9223372036854775808`, which cannot be a valid result in this domain.

The ports generate each binomial coefficient from Pascal's recurrence and sum the corresponding powered terms. Exponent zero follows the source's integer behavior, including `0^0 = 1` in each term.

| Language | Port |
|---|---|
| C | [`c/b/binomial_expansion.c`](../../../c/b/binomial_expansion.c) |
| C3 | [`c3/b/binomial_expansion.c3`](../../../c3/b/binomial_expansion.c3) |
| C++ | [`cpp/b/binomial_expansion.cpp`](../../../cpp/b/binomial_expansion.cpp) |
| Elisa | [`elisa/b/binomial_expansion.elisa`](../../../elisa/b/binomial_expansion.elisa) |
| Nim | [`nim/b/binomial_expansion.nim`](../../../nim/b/binomial_expansion.nim) |
| Odin | [`odin/b/binomial_expansion.odin`](../../../odin/b/binomial_expansion.odin) |
| Rust | [`rust/b/binomial_expansion.rs`](../../../rust/b/binomial_expansion.rs) |
| V | [`v/b/binomial_expansion.v`](../../../v/b/binomial_expansion.v) |
| Zig | [`zig/b/binomial_expansion.zig`](../../../zig/b/binomial_expansion.zig) |

Pinned source: [TheAlgorithms/Python `binomial_expansion.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/binomial_expansion.py). It computes the same coefficient sum using the pinned [`binomial_coefficient.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/binomial_coefficient.py) helper, and takes a reciprocal for negative exponents; the latter behavior is outside this exact-integer workload. See [`workload.json`](workload.json) for exponent, base, and malformed-input boundaries.
