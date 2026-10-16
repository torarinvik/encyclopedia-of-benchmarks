# Rayleigh Quotient

This package ports the real-valued bounded domain of `rayleigh_quotient` from the pinned [TheAlgorithms/Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/linear_algebra/src/rayleigh_quotient.py). For a real symmetric matrix `A` and nonzero vector `v`, it computes `(vᵀ A v) / (vᵀ v)`. The source returns a NumPy `1×1` array; the benchmark ABI exposes its single scalar value.

The float64 input is `[n, A row-major (n*n entries), v (n entries)]`. `n` must be an exact integer in `[1, 16]`; matrix entries must be finite and in `[-1000, 1000]`; vector entries must be finite and in `[-100, 100]`; `A` must be exactly symmetric and `vᵀv` must evaluate to a positive value in float64. The output is `[quotient]`. The source computes `vᵀA` first, then dots that row with `v`, and divides by `vᵀv`; the ports preserve that operation order. Symmetry is an input-domain restriction, since the source's separate Hermitian helper is not called by `rayleigh_quotient` itself.

Invalid input returns `-1` without writing output. A null or undersized output buffer returns `-2`, also without writing. Output comparison uses absolute tolerance `1e-9` and relative tolerance `1e-12`. The independent oracle and corpus are [`rayleigh_quotient_oracle.py`](../../rayleigh_quotient_oracle.py) and [`workload.json`](workload.json).

| Language | Port |
|---|---|
| C | [`c/r/rayleigh_quotient.c`](../../../c/r/rayleigh_quotient.c) |
| C3 | [`c3/r/rayleigh_quotient.c3`](../../../c3/r/rayleigh_quotient.c3) |
| C++ | [`cpp/r/rayleigh_quotient.cpp`](../../../cpp/r/rayleigh_quotient.cpp) |
| Elisa | [`elisa/r/rayleigh_quotient.elisa`](../../../elisa/r/rayleigh_quotient.elisa) |
| Nim | [`nim/r/rayleigh_quotient.nim`](../../../nim/r/rayleigh_quotient.nim) |
| Odin | [`odin/r/rayleigh_quotient.odin`](../../../odin/r/rayleigh_quotient.odin) |
| Rust | [`rust/r/rayleigh_quotient.rs`](../../../rust/r/rayleigh_quotient.rs) |
| V | [`v/r/rayleigh_quotient.v`](../../../v/r/rayleigh_quotient.v) |
| Zig | [`zig/r/rayleigh_quotient.zig`](../../../zig/r/rayleigh_quotient.zig) |
