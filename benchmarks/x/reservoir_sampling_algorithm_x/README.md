# Reservoir sampling: quantized Algorithm X

This bounded profile uses Vitter's skip-based Algorithm X to choose reservoir
replacement positions. It is distinct from the local
[`reservoir_sampling_algorithm_r`](../../r/reservoir_sampling_algorithm_r/README.md),
which consumes one replacement decision for every record after the initial
reservoir. Algorithm X samples a skip length and then consumes a slot draw only
when a later record is selected.

Input is `[n,k,values[n],(skip_draw,slot_draw)*(n-k)]`. `n` defines the
bounded replay horizon and frame; the Algorithm X skip distribution itself
depends on `k` and processed count `t`, not on the remaining stream length.
Require
`1<=n<=16`, `k` in `{1,2,4,8}` with `k<=n`, and item values in
`[-1000000,1000000]`. There are exactly `n-k` draw pairs, even when the scan
ends before consuming every pair. Each draw is an integer in
`0..2^32-1`; exact input length is `2+3*n-2*k`, at most 48 words, with a
49-word parseable limit for one trailing-word rejection.

After filling the first `k` slots, let `t` be the number of stream records
processed. Algorithm X draws a skip length `s` from the tail

`H_t(s) = (t falling k) / ((t+s+1) falling k)`,

where `(a falling k)=a*(a-1)*...*(a-k+1)`. The selected skip is the smallest
nonnegative `s` for which `H_t(s) <= u`. Here
`u=(skip_draw+1)/(2^32+1)`, a finite interior grid that avoids floating-point
and random-number-generator differences. This makes the profile a discrete,
quantized adaptation of Algorithm X; a fixed supplied tape does not claim the
continuous-uniform distribution from Vitter's analysis. Search only candidate
records that remain in this bounded stream. If no threshold is met before the
end, the current reservoir is final. Otherwise record `t+s` replaces slot
`slot_draw mod k`; the power-of-two restriction makes this slot mapping
unbiased for a uniform 32-bit slot draw. The slot draw paired with a terminal
skip is validated but unused.

The primary implementation updates the exact rational tail by multiplying
`(t+s+1-k)/(t+s+1)` and reducing by gcd. The independent reference recomputes
each falling-factorial ratio directly for every candidate skip, without using
that recurrence. With `k<=8` and `n<=16`, all cross-products fit signed 64-bit:
the largest falling product is `16 falling 8 = 518918400`, and multiplying by
`2^32+1` stays below `2^61`. Each recurrence step multiplies stored reduced
factors by at most 16 before reducing again, which also stays far below the
signed 64-bit limit. The bounded recurrence uses `O(k)` additional
state and at most `n-k` candidate skip tests; computing the initial products
at each replacement costs `O(k(n-k)+n)` arithmetic operations. The workspace
reserves 64 bytes for eight sample values. The output is the final reservoir
values in slot order, encoded as little-endian signed 64-bit integers, and
success returns `8*k`. Invalid
input returns -1; null output or capacity below `8*k` returns -2 without
writes.

The primary description is Vitter's [*Random Sampling with a Reservoir*](https://doi.org/10.1145/3147.3165)
(1985), especially the skip distribution
and Algorithm X. [NIST DADS](https://xlinux.nist.gov/dads/HTML/reservoirSampling.html)
summarizes that Vitter's methods choose how many records to skip. Algorithmic
ideas only; the code, draw-tape adaptation, references, and fixtures are
independently authored.

Ten language drafts, two references, workload, static inventory helper, and
rights/provenance note are present. No program, test, checker, build, compiler,
or benchmark has been run.

| Language | Draft source |
| --- | --- |
| C | [C](../../../c/x/reservoir_sampling_algorithm_x.c) |
| C3 | [C3](../../../c3/x/reservoir_sampling_algorithm_x.c3) |
| C++ | [C++](../../../cpp/x/reservoir_sampling_algorithm_x.cpp) |
| Elisa | [Elisa](../../../elisa/x/reservoir_sampling_algorithm_x.elisa) |
| Mojo | [Mojo](../../../mojo/x/reservoir_sampling_algorithm_x.mojo) |
| Nim | [Nim](../../../nim/x/reservoir_sampling_algorithm_x.nim) |
| Odin | [Odin](../../../odin/x/reservoir_sampling_algorithm_x.odin) |
| Rust | [Rust](../../../rust/x/reservoir_sampling_algorithm_x.rs) |
| V | [V](../../../v/x/reservoir_sampling_algorithm_x.v) |
| Zig | [Zig](../../../zig/x/reservoir_sampling_algorithm_x.zig) |
