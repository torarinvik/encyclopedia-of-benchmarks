# K-mismatch LZ binary-division kernel

This package isolates the intra-block binary-division stage of Kolpakov and
Kucherov's search for maximal K-mismatch globally-defined repetitions. It is
distinct from [`approximate_tandem_k_repetitions`](../../a/approximate_tandem_k_repetitions/README.md),
which directly enumerates approximate tandem-repeat factors, and from
[`k_mismatch_longest_extension_table`](../k_mismatch_longest_extension_table/README.md),
which returns a reusable per-suffix extension table.

## Contract

ABI: `i64_array_bytes_output`; symbol: `k_repetition_binary_division_kernel`.
Input is exactly `[n,K,w0,...,w(n-1)]`, with `1<=n<=32`, `0<=K<=3`, and
symbols in `0..4`. The last symbol must occur nowhere earlier in the text;
this is the factorization precondition stated in the source. The valid input
bound is 34 i64 words and the parser bound is 35 words.

The method builds the copy-overlap Lempel-Ziv factorization. It partitions the
factor sequence into consecutive blocks of at most `K+2` factors. For each
block with at least two factors, it recursively splits a factor interval at
`mid = floor((first+last)/2)`. On the current interval it applies the paper's
Algorithm 1 at the head of factor `mid`, then discards candidates that touch
the interval's final factor head or contain the interval's first character.
It then visits the left and right factor intervals. Duplicate candidates
from the recursion are treated as a set.

Algorithm 1 uses the forward extension `LP_k(p)` and backward extension
`LS_(K-k)(p)`. For each period `p` and split of the mismatch budget, it emits
the maximal global repetition when
`LP_k(p) <= p` and `LP_k(p) + LS_(K-k)(p) >= p`; the symmetric pass handles a
right root beginning to the right of the split character. The primary uses
bounded direct extension walks to evaluate these equations. It does not build
a suffix tree or claim the paper's asymptotic running time.

This package returns only the paper's intra-block binary-division stage. It
does not include the preceding block-head pass or the final within-factor
recovery stage, which the report delegates to an earlier exact-repetition
routine. Output is `[record_count,(start,length,period,mismatches)...]` as
little-endian signed-64 words, ordered by start, length, then period. Positions
are zero-based. A record is a maximal factor in the current recursive block
whose shifted positions have at most `K` mismatches and length at least twice
its period. The maximum possible record count at `n=32` is bounded by the
number of `(start,end,period)` triples with `end-start+1 >= 2*period`, namely
2,856; the output cap is 91,400 bytes including the count word. Workspace is
capped at 8,192 bytes and excludes caller buffers; the primary's 272-word
candidate bitset uses 2,176 bytes, with factor bounds, text, and recursion
state well below the remaining space.

Invalid input returns `-1`; a null output or insufficient capacity returns
`-2`, with no bytes written on error. The full frame is validated before
output-capacity handling.

## Complexity

For text length `n` and mismatch budget `K`, the bounded primary takes
`O(n^4 + (K+1)n^3)` worst-case time: direct copy-overlap factorization costs
`O(n^3)`, the recursive midpoint extension walks cost `O((K+1)n^3)`, and
enumerating marked output candidates while recounting mismatches costs
`O(n^4)`. Workspace is `O(n^3)` bits for candidate deduplication plus
`O(n)` factor, text, and recursion state; the caller-owned output buffer is
excluded. The contract fixes `n<=32`, `K<=3`, and caps the native workspace at
8,192 bytes.

## Sources and provenance

Chapter context: Gregory Kucherov and Dina Sokol, “Approximate Tandem
Repeats,” *Encyclopedia of Algorithms*, Chapter 24,
[DOI 10.1007/978-1-4939-2864-4_24](https://doi.org/10.1007/978-1-4939-2864-4_24).

Operational procedure: Roman Kolpakov and Gregory Kucherov, “Finding
Approximate Repetitions under Hamming Distance,” INRIA Research Report
RR-4163 (2001), §3, Algorithm 1 and the binary-division stage; journal version
in *Theoretical Computer Science* 303(1), 135–156 (2003),
[DOI 10.1016/S0304-3975(02)00448-6](https://doi.org/10.1016/S0304-3975(02)00448-6).
The report's [open archive record](https://inria.hal.science/inria-00072459v1/document)
contains the detailed procedure. The references provide algorithm ideas and
definitions only. The benchmark contract, implementation, and fixtures are
clean-room work; no source code or published examples were copied. See
[`RIGHTS.md`](RIGHTS.md).

The primary and structurally independent bounded references are
[`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py). The latter enumerates
interval/period candidates directly and checks maximality instead of using
the split-budget extension equations.

| Language | Source |
|---|---|
| C | [`c/k/k_repetition_binary_division_kernel.c`](../../../c/k/k_repetition_binary_division_kernel.c) |
| C3 | [`c3/k/k_repetition_binary_division_kernel.c3`](../../../c3/k/k_repetition_binary_division_kernel.c3) |
| C++ | [`cpp/k/k_repetition_binary_division_kernel.cpp`](../../../cpp/k/k_repetition_binary_division_kernel.cpp) |
| Elisa | [`elisa/k/k_repetition_binary_division_kernel.elisa`](../../../elisa/k/k_repetition_binary_division_kernel.elisa) |
| Mojo | [`mojo/k/k_repetition_binary_division_kernel.mojo`](../../../mojo/k/k_repetition_binary_division_kernel.mojo) |
| Nim | [`nim/k/k_repetition_binary_division_kernel.nim`](../../../nim/k/k_repetition_binary_division_kernel.nim) |
| Odin | [`odin/k/k_repetition_binary_division_kernel.odin`](../../../odin/k/k_repetition_binary_division_kernel.odin) |
| Rust | [`rust/k/k_repetition_binary_division_kernel.rs`](../../../rust/k/k_repetition_binary_division_kernel.rs) |
| V | [`v/k/k_repetition_binary_division_kernel.v`](../../../v/k/k_repetition_binary_division_kernel.v) |
| Zig | [`zig/k/k_repetition_binary_division_kernel.zig`](../../../zig/k/k_repetition_binary_division_kernel.zig) |

See [`workload.json`](workload.json), [`INVENTORY.md`](INVENTORY.md), and
[`INVENTORY.json`](INVENTORY.json). Shared suite and catalog registration is
left for the repository integrator.
