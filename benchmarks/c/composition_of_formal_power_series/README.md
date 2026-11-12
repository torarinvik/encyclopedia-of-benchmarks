# Composition of Formal Power Series

This package implements Library Checker `composition_of_formal_power_series`: compute the first `N` coefficients of `f(g(x))` over `F_998244353`, where the inner series has zero constant term.

## Bounded contract

The `i64_array_bytes_output` input is `[N, a_0, ..., a_(N-1), b_0, ..., b_(N-1)]`. The local bound is `1 <= N <= 16`; all coefficients are in `[0, 998244352]`, and `b_0 = 0`. Success writes `N` little-endian signed 64-bit output coefficients and returns `8*N` bytes. Malformed input returns `-1`; valid input with a null output or capacity below `8*N` returns `-2` without writing. Maximum valid input is 33 words, maximum parseable input is 34 words, output is at most 128 bytes, and workspace is 128 bytes.

The primary port uses Horner composition. When multiplying the current result by `g`, it updates output degrees from high to low. Since `b_0=0`, degree `d` depends only on old coefficients below `d`, which have not yet been overwritten. It then writes the next `a_i` into the constant term. This direct recurrence uses at most a few thousand modular products at `N=16` and makes no claim about the official large bound (`N <= 8,000`).

## Distinctness

The local `polynomial_evaluation` and `polynomial_evaluation_direct` profiles evaluate at a single scalar `x`; they do not substitute a formal series. Convolution/NTT profiles multiply coefficient arrays but do not compose one series into another. The formal series inverse and exponential packages perform different algebraic operations and have different input conditions. The primary oracle mirrors Horner composition, while the independent oracle accumulates `a_i*g^i` using separate truncated polynomial products.

## Source and rights

The operation, inner-series condition, and modulus are attributed to the Apache-2.0 Library Checker repository: [task statement](https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/composition_of_formal_power_series/task.md), [task limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/polynomial/composition_of_formal_power_series/info.toml), and [repository license](https://github.com/yosupo06/library-checker-problems/blob/master/LICENSE). The official limits are `N <= 8,000`, with `N_SMALL_MAX=10`; this profile uses `N<=16` under a direct Horner kernel. The bounded ports, fixtures, and oracles are clean-room implementations of the task semantics.

See [RIGHTS.md](RIGHTS.md), [workload.json](workload.json), [primary_oracle.py](primary_oracle.py), [independent_oracle.py](independent_oracle.py), and the package-local [static checker](verify_workload.py).

The workload is registered with the shared byte-output runner and verifier. No programs, tests, or checkers were run during suite integration.

## Ports

| Language | Source |
|---|---|
| C | [`c/c/composition_of_formal_power_series.c`](../../../c/c/composition_of_formal_power_series.c) |
| C3 | [`c3/c/composition_of_formal_power_series.c3`](../../../c3/c/composition_of_formal_power_series.c3) |
| C++ | [`cpp/c/composition_of_formal_power_series.cpp`](../../../cpp/c/composition_of_formal_power_series.cpp) |
| Elisa | [`elisa/c/composition_of_formal_power_series.elisa`](../../../elisa/c/composition_of_formal_power_series.elisa) |
| Mojo | [`mojo/c/composition_of_formal_power_series.mojo`](../../../mojo/c/composition_of_formal_power_series.mojo) |
| Nim | [`nim/c/composition_of_formal_power_series.nim`](../../../nim/c/composition_of_formal_power_series.nim) |
| Odin | [`odin/c/composition_of_formal_power_series.odin`](../../../odin/c/composition_of_formal_power_series.odin) |
| Rust | [`rust/c/composition_of_formal_power_series.rs`](../../../rust/c/composition_of_formal_power_series.rs) |
| V | [`v/c/composition_of_formal_power_series.v`](../../../v/c/composition_of_formal_power_series.v) |
| Zig | [`zig/c/composition_of_formal_power_series.zig`](../../../zig/c/composition_of_formal_power_series.zig) |
