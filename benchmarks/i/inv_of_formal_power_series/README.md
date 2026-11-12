# Inverse of a Formal Power Series

This package implements the Library Checker operation `inv_of_formal_power_series`: given the first `N` coefficients of `f(x)` over `F_998244353` with nonzero constant term, return the first `N` coefficients of its reciprocal modulo `x^N`.

## Bounded contract

The byte-output call uses the `i64_array_bytes_output` ABI. Input is `[N, a_0, ..., a_(N-1)]`, with `1 <= N <= 64`, each coefficient in `[0, 998244352]`, and `a_0 != 0`. Each port computes

`g_0 = a_0^(-1)` and `g_k = -a_0^(-1) * sum(a_i * g_(k-i), i=1..k) mod 998244353`.

This direct coefficient recurrence costs `O(N^2)` arithmetic operations and at most 4,096 multiply-accumulate terms. The bound is intentionally small and does not claim the official `N <= 500,000` scale or Newton/NTT complexity. Success writes `N` little-endian signed 64-bit coefficients and returns `8*N` bytes. Invalid input returns `-1`; valid input with a null output or capacity below `8*N` returns `-2` without writing output. The maximum valid input is 65 words, the maximum parseable input is 66 words, and output and workspace are each bounded at 512 bytes.

## Distinctness

This is the truncated reciprocal in the quotient ring `F_p[[x]]/(x^N)`, where invertibility is exactly the condition `a_0 != 0`. The local inventory has polynomial evaluation and convolution/NTT primitives, but neither evaluates a reciprocal series as an operation. Library Checker's separate [`inv_of_polynomials`](https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/inv_of_polynomials/task.md) asks for an inverse of one polynomial modulo another arbitrary polynomial, requires nonzero leading coefficients, and can have no inverse when the two polynomials are not coprime. That general polynomial Euclidean-algorithm problem has different inputs, existence conditions, and output degree; this package covers only the formal-series operation.

The primary oracle uses the same coefficient recurrence as the bounded ports. The independent verifier uses precision-doubling Newton iteration with direct truncated polynomial multiplication. Both are package-local and independently validate the input and output-capacity contract.

## Source and rights

The operation and field modulus are attributed to the Apache-2.0 Library Checker problem repository: [task statement](https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/inv_of_formal_power_series/task.md), [task limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/polynomial/inv_of_formal_power_series/info.toml), and [repository license](https://github.com/yosupo06/library-checker-problems/blob/master/LICENSE). The general polynomial inverse comparison uses its own [official task statement](https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/inv_of_polynomials/task.md). This profile uses the problem semantics only; code, local bound, fixtures, and oracles are clean-room.

See [RIGHTS.md](RIGHTS.md), [workload.json](workload.json), [primary_oracle.py](primary_oracle.py), [independent_oracle.py](independent_oracle.py), and the package-local [static checker](verify_workload.py).

The workload is registered with the shared byte-output runner and verifier. No programs, tests, or checkers were run during the write-only suite integration.

## Ports

| Language | Source |
|---|---|
| C | [`c/i/inv_of_formal_power_series.c`](../../../c/i/inv_of_formal_power_series.c) |
| C3 | [`c3/i/inv_of_formal_power_series.c3`](../../../c3/i/inv_of_formal_power_series.c3) |
| C++ | [`cpp/i/inv_of_formal_power_series.cpp`](../../../cpp/i/inv_of_formal_power_series.cpp) |
| Elisa | [`elisa/i/inv_of_formal_power_series.elisa`](../../../elisa/i/inv_of_formal_power_series.elisa) |
| Mojo | [`mojo/i/inv_of_formal_power_series.mojo`](../../../mojo/i/inv_of_formal_power_series.mojo) |
| Nim | [`nim/i/inv_of_formal_power_series.nim`](../../../nim/i/inv_of_formal_power_series.nim) |
| Odin | [`odin/i/inv_of_formal_power_series.odin`](../../../odin/i/inv_of_formal_power_series.odin) |
| Rust | [`rust/i/inv_of_formal_power_series.rs`](../../../rust/i/inv_of_formal_power_series.rs) |
| V | [`v/i/inv_of_formal_power_series.v`](../../../v/i/inv_of_formal_power_series.v) |
| Zig | [`zig/i/inv_of_formal_power_series.zig`](../../../zig/i/inv_of_formal_power_series.zig) |
