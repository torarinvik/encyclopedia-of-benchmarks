# Exponential of a Formal Power Series

This package implements the Library Checker operation `exp_of_formal_power_series`. Given the first `N` coefficients of `f(x)` over the field of 998244353 elements, with zero constant coefficient, it returns the first `N` coefficients of `exp(f(x))`.

## Bounded contract

The package uses the `i64_array_bytes_output` ABI. Input is `[N, a_0, ..., a_(N-1)]`, with `1 <= N <= 64`, each coefficient in `[0, 998244352]`, and `a_0 = 0`. Each port computes `g_0 = 1` and, for `1 <= k < N`,

`g_k = k^(-1) * sum(i * a_i * g_(k-i), i=1..k) mod 998244353`.

This follows from `g' = f' * g`. The bound guarantees every `k` is invertible modulo 998244353. The direct coefficient recurrence costs `O(N^2)` modular multiply-accumulate terms, at most 2,016 for `N=64`. It does not claim the official `N <= 500,000` scale or Newton/NTT complexity. Success writes `N` little-endian signed 64-bit coefficients and returns `8*N` bytes. Invalid input returns `-1`; valid input with a null output or capacity below `8*N` returns `-2` without writing. Maximum valid input is 65 words, maximum parseable input is 66 words, output is bounded at 512 bytes, and workspace is bounded at 1,024 bytes for the integer-inverse table and recurrence coefficients.

## Distinctness

This operation requires `a_0 = 0` and computes the exponential. The nearby [`inv_of_formal_power_series`](../i/inv_of_formal_power_series/README.md) instead requires `a_0 != 0` and computes the reciprocal; the input conditions and resulting series differ. Local convolution/NTT packages provide multiplication primitives rather than this series exponential operation. The primary oracle uses the derivative recurrence above. The independent verifier expands `sum(f^k/k!)` with direct truncated polynomial products, a separate algorithm.

## Source and rights

The operation, zero-constant condition, field modulus, and official limit come from the Apache-2.0 Library Checker repository: [task statement](https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/exp_of_formal_power_series/task.md), [task limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/polynomial/exp_of_formal_power_series/info.toml), and [repository license](https://github.com/yosupo06/library-checker-problems/blob/master/LICENSE). This profile uses the task semantics only; the local bound, fixtures, oracles, and ports are clean-room.

See [RIGHTS.md](RIGHTS.md), [workload.json](workload.json), [primary_oracle.py](primary_oracle.py), [independent_oracle.py](independent_oracle.py), and the package-local [static checker](verify_workload.py).

The workload is registered with the shared byte-output runner and verifier. No programs, tests, or checkers were run during the write-only suite integration.

## Ports

| Language | Source |
|---|---|
| C | [`c/e/exp_of_formal_power_series.c`](../../../c/e/exp_of_formal_power_series.c) |
| C3 | [`c3/e/exp_of_formal_power_series.c3`](../../../c3/e/exp_of_formal_power_series.c3) |
| C++ | [`cpp/e/exp_of_formal_power_series.cpp`](../../../cpp/e/exp_of_formal_power_series.cpp) |
| Elisa | [`elisa/e/exp_of_formal_power_series.elisa`](../../../elisa/e/exp_of_formal_power_series.elisa) |
| Mojo | [`mojo/e/exp_of_formal_power_series.mojo`](../../../mojo/e/exp_of_formal_power_series.mojo) |
| Nim | [`nim/e/exp_of_formal_power_series.nim`](../../../nim/e/exp_of_formal_power_series.nim) |
| Odin | [`odin/e/exp_of_formal_power_series.odin`](../../../odin/e/exp_of_formal_power_series.odin) |
| Rust | [`rust/e/exp_of_formal_power_series.rs`](../../../rust/e/exp_of_formal_power_series.rs) |
| V | [`v/e/exp_of_formal_power_series.v`](../../../v/e/exp_of_formal_power_series.v) |
| Zig | [`zig/e/exp_of_formal_power_series.zig`](../../../zig/e/exp_of_formal_power_series.zig) |
