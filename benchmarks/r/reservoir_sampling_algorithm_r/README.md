# Reservoir sampling: Algorithm R

This draft samples stream positions without replacement using Algorithm R.
The first `k` items fill the reservoir; for each subsequent zero-based stream
position `i`, a supplied draw `j` in `0..i` replaces slot `j` only when `j<k`.
The existing [`counting_triangles_stream_reservoir`](../../c/counting_triangles_stream_reservoir/README.md)
maintains independent one-item reservoirs with replacement between slots.

Input is `[n,k,values[n],draws[n-k]]`, with `0<=k<=n<=64` and values in
`[-1000000,1000000]`. Draw `draws[i-k]` for each `i` in `k..n-1` must lie in
`0..i`; draws are validated even when `k=0`. Exact frame length is `2+2*n-k`,
at most 130 i64 words. Output is the final reservoir in slot order as `k`
little-endian signed i64 values; success returns `8*k`. Null or malformed
input returns -1. Valid input with null output or capacity below `8*k` returns
-2 without writes; null output is an error even when `k=0`.

The supplied draw tape isolates the update algorithm from RNG implementation.
When the supplied draws are independent and uniform in their stated ranges,
Algorithm R samples positions uniformly without replacement; one deterministic
tape alone does not demonstrate that distribution. Construction takes `O(n)`
time and `O(k)` space. The algorithm is described in Vitter, [*Random Sampling
with a Reservoir*](https://doi.org/10.1145/3147.3165) (1985); no source code,
examples, or tests are copied.

Ten language drafts, two references, workload, inventory checker, and
byte-output runner/verifier integration are present. Verifier source specifies
all small draw tapes, equal subset frequencies, maximum frames, capacity errors,
and null pointers. The
Elisa draft uses bounded views and indexed arrays. Nothing has been compiled or
run.

| Language | Draft source |
| --- | --- |
| C | [C](../../../c/r/reservoir_sampling_algorithm_r.c) |
| C3 | [C3](../../../c3/r/reservoir_sampling_algorithm_r.c3) |
| C++ | [C++](../../../cpp/r/reservoir_sampling_algorithm_r.cpp) |
| Elisa | [Elisa](../../../elisa/r/reservoir_sampling_algorithm_r.elisa) |
| Mojo | [Mojo](../../../mojo/r/reservoir_sampling_algorithm_r.mojo) |
| Nim | [Nim](../../../nim/r/reservoir_sampling_algorithm_r.nim) |
| Odin | [Odin](../../../odin/r/reservoir_sampling_algorithm_r.odin) |
| Rust | [Rust](../../../rust/r/reservoir_sampling_algorithm_r.rs) |
| V | [V](../../../v/r/reservoir_sampling_algorithm_r.v) |
| Zig | [Zig](../../../zig/r/reservoir_sampling_algorithm_r.zig) |
