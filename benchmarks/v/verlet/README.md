# Verlet integration

This package ports the pinned Julia [`verlet_integration`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/verlet.jl) recurrence. Since the source accepts an arbitrary acceleration callback, the portable benchmark fixes it to `f(x) = -x`, the one-dimensional unit harmonic oscillator.

The `float64_slice_io` input is `[N, x0, v0, dt_code]`. `N` must be an exact integer in `2..32`, and `x0` and `v0` must be in `[-1, 1]`. `dt_code` must be an exact integer in `0..4`, mapping to step sizes `1/256`, `1/128`, `1/64`, `1/32`, and `1/16`. These binary step sizes map to the source span `(0, N*dt)` without floating-point quotient ambiguity.

The output concatenates the `N` positions and the `N` time points: `[x[1..N], t[1..N]]`, where `t[i] = (i-1)*dt`. It preserves the source's initialization and recurrence order and its endpoint behavior: the last position is at `(N-1)*dt`, so the span endpoint is omitted. A successful call returns `2N`; invalid input returns `-1`, and a null or short output buffer returns `-2`. The source's arbitrary callback and error cases caused by `N < 2`, nonpositive step sizes, or invalid spans are outside this bounded contract.

The independent oracle and workload are in [`verlet_oracle.py`](../../verlet_oracle.py) and [`workload.json`](workload.json).

| Language | Port |
|---|---|
| C | [`c/v/verlet.c`](../../../c/v/verlet.c) |
| C3 | [`c3/v/verlet.c3`](../../../c3/v/verlet.c3) |
| C++ | [`cpp/v/verlet.cpp`](../../../cpp/v/verlet.cpp) |
| Elisa | [`elisa/v/verlet.elisa`](../../../elisa/v/verlet.elisa) |
| Nim | [`nim/v/verlet.nim`](../../../nim/v/verlet.nim) |
| Odin | [`odin/v/verlet.odin`](../../../odin/v/verlet.odin) |
| Rust | [`rust/v/verlet.rs`](../../../rust/v/verlet.rs) |
| V | [`v/v/verlet.v`](../../../v/v/verlet.v) |
| Zig | [`zig/v/verlet.zig`](../../../zig/v/verlet.zig) |
