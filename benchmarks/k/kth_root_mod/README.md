# Kth root modulo a prime

## Contract

Input is `[T, (K_0,Y_0,P_0), ...]`, with `1 <= T <= 8`,
`0 <= K <= 1,000,000,000`, prime `2 <= P <= 1,000`, and `0 <= Y < P`.
For each case return any `X` satisfying `X^K = Y (mod P)`, or `-1` if no
solution exists. The official convention `0^0 = 1` is preserved. The profile
chooses a deterministic result by reducing nonzero roots to a linear
congruence in the cyclic group of order `P-1`; the root found this way need not
be the smallest one.

For nonzero `Y` and positive `K`, find a primitive root `g`, compute
`d = log_g(Y)`, and solve `K*x = d (mod P-1)`. A solution exists exactly when
`gcd(K,P-1)` divides `d`. The implementation then returns `g^x mod P`. Zero
and `K=0` cases are handled directly. Primitive-root factorization, exponent
scanning, and primality checks are all bounded by the profile limit `P <=
1000`; multiplication therefore fits in signed 64-bit arithmetic.

## Distinctness

The local `primitive_root` package returns a generator, and the discrete-log
packages return exponents; neither extracts a Kth root. `tonelli_shanks`
solves the special case `K=2`, while this profile handles arbitrary K, zero
exponents, and no-solution cases.

Official task: [Library Checker — Kth Root (Mod)](https://github.com/yosupo06/library-checker-problems/blob/master/number_theory/kth_root_mod/task.md).

## Workload and ports

[`workload.json`](workload.json) covers the `0^0` convention, zero roots,
solvable and unsolvable exponents, multiple records, the largest profile prime,
invalid composites and out-of-range values, and output-capacity errors. The
independent Python oracle is
[`benchmarks/kth_root_mod_oracle.py`](../../kth_root_mod_oracle.py).

| Language | Port |
|---|---|
| C | [`c/k/kth_root_mod.c`](../../../c/k/kth_root_mod.c) |
| C3 | [`c3/k/kth_root_mod.c3`](../../../c3/k/kth_root_mod.c3) |
| C++ | [`cpp/k/kth_root_mod.cpp`](../../../cpp/k/kth_root_mod.cpp) |
| Elisa | [`elisa/k/kth_root_mod.elisa`](../../../elisa/k/kth_root_mod.elisa) |
| Nim | [`nim/k/kth_root_mod.nim`](../../../nim/k/kth_root_mod.nim) |
| Odin | [`odin/k/kth_root_mod.odin`](../../../odin/k/kth_root_mod.odin) |
| Rust | [`rust/k/kth_root_mod.rs`](../../../rust/k/kth_root_mod.rs) |
| V | [`v/k/kth_root_mod.v`](../../../v/k/kth_root_mod.v) |
| Zig | [`zig/k/kth_root_mod.zig`](../../../zig/k/kth_root_mod.zig) |
| Mojo | [`mojo/k/kth_root_mod.mojo`](../../../mojo/k/kth_root_mod.mojo) |
