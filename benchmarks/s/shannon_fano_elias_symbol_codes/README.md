# Shannon–Fano–Elias symbol codes

This profile assigns one truncated cumulative-midpoint codeword to each symbol
in the supplied order. It is the Gilbert–Moore/Shannon–Fano–Elias construction,
not the repository's recursive Shannon–Fano partitioner or its separate
greedy compressor.

## Contract

The `i64_array_bytes_output` input is `[n,w_0,...,w_(n-1)]`. Accept
`1<=n<=8`, with each integer weight in `1..15` and total `W<=120`; the exact
frame contains `n+1` words. The maximum valid and one-extra-word parseable
frames contain 9 and 10 words. Input order defines symbol order; no sorting or
frequency tie-breaking occurs.

For symbol `i`, let `P_i` be the sum of preceding weights. Its probability
interval midpoint is `(2*P_i+w_i)/(2*W)`. Define `L_i` as the smallest positive
integer for which `2^(L_i-1)*w_i >= W`, equivalent to
`ceil(log2(W/w_i))+1`. The codeword integer is
`C_i=floor((2*P_i+w_i)*2^(L_i-1)/W)`. Emit a symbol-count byte followed, in
input order, by `(L_i, C_i << (8-L_i))` bytes. The second byte stores exactly
the `L_i` code bits from most significant to least significant, with low bits
zero-padded; `L_i` disambiguates those padding bits. Since `W<=120`, the code
length is at most 8 and output is at most 17 bytes. A one-symbol source emits
the single codeword `1`.

Malformed or null input returns `-1` before output validation. Valid input
with null output or capacity below `1+2*n` returns `-2` and writes no bytes.
Successful calls return the output byte count. Workspace is capped at 1,024
bytes. The integer midpoint implementation takes `O(n log W)` time and
`O(n)` scratch; the independent rational bit-expansion reference has the same
bounded time and scratch order.

The workload includes equal and unequal weights, a one-symbol alphabet,
maximum input/output, short and null output, malformed bounds, a maximum
parseable overlong frame, and null input. Expected bytes are pinned in
[`workload.json`](workload.json), with independently structured references in
[`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py). The package is registered in
the `i64_array_bytes_output` runner and verifier.

## Source and distinction

The [NIST DADS Shannon–Fano entry](https://xlinux.nist.gov/dads/HTML/shannonFano.html)
was used as a discovery cross-check. The precise midpoint construction is
described by Gilbert and Moore, [“Variable-Length Binary Encodings,” *Bell
System Technical Journal* 38(4), 1959](https://doi.org/10.1002/j.1538-7305.1959.tb01583.x).
The existing [`shannon_fano`](../shannon_fano/README.md) repeatedly splits
frequency-sorted contiguous symbol groups; this package computes each code
from an exact cumulative interval midpoint. Existing
[`arithmetic_coding`](../../a/arithmetic_coding/README.md) maps a whole message
to a nested interval, while this profile constructs a per-symbol prefix code.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/s/shannon_fano_elias_symbol_codes.c`](../../../c/s/shannon_fano_elias_symbol_codes.c) |
| C3 | [`c3/s/shannon_fano_elias_symbol_codes.c3`](../../../c3/s/shannon_fano_elias_symbol_codes.c3) |
| C++ | [`cpp/s/shannon_fano_elias_symbol_codes.cpp`](../../../cpp/s/shannon_fano_elias_symbol_codes.cpp) |
| Elisa | [`elisa/s/shannon_fano_elias_symbol_codes.elisa`](../../../elisa/s/shannon_fano_elias_symbol_codes.elisa) |
| Mojo | [`mojo/s/shannon_fano_elias_symbol_codes.mojo`](../../../mojo/s/shannon_fano_elias_symbol_codes.mojo) |
| Nim | [`nim/s/shannon_fano_elias_symbol_codes.nim`](../../../nim/s/shannon_fano_elias_symbol_codes.nim) |
| Odin | [`odin/s/shannon_fano_elias_symbol_codes.odin`](../../../odin/s/shannon_fano_elias_symbol_codes.odin) |
| Rust | [`rust/s/shannon_fano_elias_symbol_codes.rs`](../../../rust/s/shannon_fano_elias_symbol_codes.rs) |
| V | [`v/s/shannon_fano_elias_symbol_codes.v`](../../../v/s/shannon_fano_elias_symbol_codes.v) |
| Zig | [`zig/s/shannon_fano_elias_symbol_codes.zig`](../../../zig/s/shannon_fano_elias_symbol_codes.zig) |

No executable checks were run while drafting this package.
