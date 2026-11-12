# Brent–Kung formal power-series composition

This package computes the first `N` coefficients of `f(g(x))` over `F_998244353`, where `g(0)=0`, using Brent–Kung baby-step/giant-step composition. The same operation appears in the [Library Checker large composition task](https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/composition_of_formal_power_series_large/task.md) and its [base task](https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/composition_of_formal_power_series/task.md). The algorithm comes from Brent and Kung's [1978 paper](https://doi.org/10.1145/322092.322099); the [FLINT composition notes](https://github.com/flintlib/flint/blob/main/doc/src/algorithms/polynomials/composition.md) provide a modern description.

## Contract

The input words are `[N, a_0, ..., a_(N-1), b_0, ..., b_(N-1)]`. For `1 <= N <= 32`, all coefficients must lie in `[0, 998244352]` and `b_0` must be zero. The output is `f(g(x)) mod x^N`, encoded as `N` little-endian signed 64-bit coefficients. Malformed input returns `-1`; a valid input with a null output or insufficient capacity returns `-2` without writing. Negative or non-integer output capacity is invalid.

## Method and bounds

Choose `m=ceil(sqrt(N))` and split the outer polynomial into blocks of `m` coefficients:

`f(g) = Σ_i F_i(g) (g^m)^i`, where `F_i(g)=Σ_(j<m) a_(im+j) g^j`.

The ports build the baby powers `1,g,...,g^m` modulo `x^N`, evaluate each coefficient block as a linear combination of the baby powers, then combine the blocks by Horner's rule in `g^m`. Products use a direct truncated coefficient loop. This bounded version takes `O(N^(5/2))` field operations and `O(N^(3/2))` table storage. The local cap is deliberately small and does not claim to meet the official large input limit.

This measures a different composition algorithm from [`composition_of_formal_power_series`](../../c/composition_of_formal_power_series/README.md), whose current ports use descending Horner composition. The shared operation and modulus remain the same. A Brent–Kung primary oracle is checked against an independent coefficient-scaled power-sum oracle using Horner's rule.

See [workload.json](workload.json), [RIGHTS.md](RIGHTS.md), [primary_oracle.py](primary_oracle.py), [independent_oracle.py](independent_oracle.py), and the package-local [static checker](verify_workload.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/b/brent_kung_fps_composition.c`](../../../c/b/brent_kung_fps_composition.c) |
| C3 | [`c3/b/brent_kung_fps_composition.c3`](../../../c3/b/brent_kung_fps_composition.c3) |
| C++ | [`cpp/b/brent_kung_fps_composition.cpp`](../../../cpp/b/brent_kung_fps_composition.cpp) |
| Elisa | [`elisa/b/brent_kung_fps_composition.elisa`](../../../elisa/b/brent_kung_fps_composition.elisa) |
| Mojo | [`mojo/b/brent_kung_fps_composition.mojo`](../../../mojo/b/brent_kung_fps_composition.mojo) |
| Nim | [`nim/b/brent_kung_fps_composition.nim`](../../../nim/b/brent_kung_fps_composition.nim) |
| Odin | [`odin/b/brent_kung_fps_composition.odin`](../../../odin/b/brent_kung_fps_composition.odin) |
| Rust | [`rust/b/brent_kung_fps_composition.rs`](../../../rust/b/brent_kung_fps_composition.rs) |
| V | [`v/b/brent_kung_fps_composition.v`](../../../v/b/brent_kung_fps_composition.v) |
| Zig | [`zig/b/brent_kung_fps_composition.zig`](../../../zig/b/brent_kung_fps_composition.zig) |
