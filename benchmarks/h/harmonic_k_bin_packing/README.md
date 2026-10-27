# Parameterized HARM(k) online bin packing

This package implements the chapter-defined HARM(k) class for bounded integer
k. For each arriving item, classify its size immediately into one of the
intervals `(1/(i+1), 1/i]`, `i=1..k-1`, or the final `(0,1/k]` interval.
Each class has its own current bin and applies Next Fit in arrival order. A bin
is never reopened after a class advances to a new one. Bin IDs are global and
assigned when a new bin is first opened.

The source chapter specifies every class boundary and the independent
class-local Next-Fit rule for all `k>=3`; the benchmark bounds `k` to `3..8`.
Sizes are integer ticks in `[1,10000]`, representing exact fractions of a
capacity-10000 bin. Class comparisons use integer cross multiplication, so the
strict lower and inclusive upper endpoints are exact, including when a
fraction is not representable in ticks.

## Contract

ABI: `i64_array_bytes_output`. Input is `[k, item_count, size_0, ...]`, with
`3<=k<=8`, `1<=item_count<=32`, exactly `2+item_count` words, and sizes in
`[1,10000]`. The maximum valid and parseable input length is 34 words. Output
is little-endian signed-i64 `[bin_count, bin_id_for_each_item]`, requiring
`8*(item_count+1)` bytes, at most 264 bytes. Invalid input returns `-1` before
checking output; null output or insufficient capacity returns `-2` without
writing. Workspace is bounded to 32 assignments and 8 current-bin/load slots
(384 bytes in the C profile).

The `k=4` fixture preserves the previous HARM-4 behavior. HARM(k)'s stated
competitive analysis applies to the family/asymptotic setting; these bounded
runs make no competitive-ratio claim.

## Source

Leah Epstein, “Harmonic Algorithm for Online Bin Packing,” *Encyclopedia of
Algorithms*, 2016, DOI [10.1007/978-1-4939-2864-4_490](https://doi.org/10.1007/978-1-4939-2864-4_490).
The chapter attributes HARM(k) to Lee and Lee (1985) and explicitly defines
its `k-1` reciprocal intervals, final interval, and per-type Next Fit. This is
a clean-room implementation; it contains no copied book prose or upstream
code.

## Oracle and implementations

The primary oracle is `benchmarks/harmonic_k_bin_packing_oracle.py`; the
independent verifier uses a separate per-bin load/closed-state model in
`benchmarks/harmonic_k_bin_packing_verifier_oracle.py`.

| Language | Port |
|---|---|
| C | `c/h/harmonic_k_bin_packing.c` |
| C3 | `c3/h/harmonic_k_bin_packing.c3` |
| C++ | `cpp/h/harmonic_k_bin_packing.cpp` |
| Elisa | `elisa/h/harmonic_k_bin_packing.elisa` |
| Nim | `nim/h/harmonic_k_bin_packing.nim` |
| Odin | `odin/h/harmonic_k_bin_packing.odin` |
| Rust | `rust/h/harmonic_k_bin_packing.rs` |
| V | `v/h/harmonic_k_bin_packing.v` |
| Zig | `zig/h/harmonic_k_bin_packing.zig` |


## Rights

The implementation is clean-room and uses only the algorithmic description in
Epstein’s chapter. The source material is identified by its DOI above; no
source code or prose is redistributed.
