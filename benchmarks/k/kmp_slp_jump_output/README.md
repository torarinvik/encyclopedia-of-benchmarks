# KMP Jump/Output on a Straight-Line Program

This profile implements the all-occurrences KMP simulation over a bounded
straight-line program (SLP), following the `Jump` and `Output` definitions in
Masayuki Takeda and Ayumi Shinohara, “Pattern Matching on Compressed Text,”
*Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_81`](https://doi.org/10.1007/978-1-4939-2864-4_81).
Instead of expanding the text and running KMP over it, it composes the KMP
state transition and occurrence-offset summaries for each grammar variable.

## Contract

The ABI is `i64_array_bytes_output`. Input is
`[pattern_len,pattern_symbols...,variable_count,(kind,a,b)*,text_factor_count,factor_ids...]`.
The pattern has 1–6 symbols from alphabet `{0,1,2,3}`. There are 1–12
zero-based, topologically ordered variables. A terminal assignment is
`[0,symbol,0]`; a concatenation is `[1,left_id,right_id]`, where both
references are less than the current variable ID. The text is the ordered
concatenation of 1–8 supplied variable IDs. This profile is a terminal/concat
SLP subset: truncation and repetition assignments are invalid. Each variable
and the final expanded text must have length at most 64. The maximum input is
53 signed 64-bit values.

KMP states are prefix lengths from 0 through `pattern_len-1`. For every
variable `X` and state `q`, `Jump(q,X)` is the state after scanning `X`, and
`Output(q,X)` is a set of zero-based end offsets relative to `X` where a
pattern occurrence finishes. For a concatenation `X=YZ`, the package composes
`Jump(q,X)=Jump(Jump(q,Y),Z)` and shifts `Output(Jump(q,Y),Z)` by `|Y|` before
unioning it with `Output(q,Y)`. After reporting a full match, KMP continues
from the pattern's failure-function state, so overlapping occurrences are
retained. The final result is `[occurrence_count,zero_based_start_offsets...]`
in ascending order, with at most 520 bytes. Malformed input returns `-1`;
null or insufficient output returns `-2` without writes.

The primary oracle composes `Jump` and `Output` summaries. The independent
verifier expands this bounded SLP and checks every possible pattern start by
direct symbol comparison. The 64-symbol cap is only a workload bound; the
profile preserves the compressed-state transition method and does not
benchmark decompression.

This package does not implement collage-system truncation or repetition,
general LZW/LZ77/BPE encodings, Boyer–Moore variants, or the paper's succinct
data structures and asymptotic bounds.

## Workload and ports

The [workload](workload.json) exercises overlapping matches that cross a
variable boundary, a nonmatching pattern, repeated references to a shared
variable, the maximum 64-symbol expansion, and a 64-zero text that reaches the
full 520-byte occurrence output. It also covers invalid grammar references
and operations, null buffers, and capacity failure.

| Language | Port |
| --- | --- |
| C | [`c/k/kmp_slp_jump_output.c`](../../../c/k/kmp_slp_jump_output.c) |
| C3 | [`c3/k/kmp_slp_jump_output.c3`](../../../c3/k/kmp_slp_jump_output.c3) |
| C++ | [`cpp/k/kmp_slp_jump_output.cpp`](../../../cpp/k/kmp_slp_jump_output.cpp) |
| Elisa | [`elisa/k/kmp_slp_jump_output.elisa`](../../../elisa/k/kmp_slp_jump_output.elisa) |
| Nim | [`nim/k/kmp_slp_jump_output.nim`](../../../nim/k/kmp_slp_jump_output.nim) |
| Odin | [`odin/k/kmp_slp_jump_output.odin`](../../../odin/k/kmp_slp_jump_output.odin) |
| Rust | [`rust/k/kmp_slp_jump_output.rs`](../../../rust/k/kmp_slp_jump_output.rs) |
| V | [`v/k/kmp_slp_jump_output.v`](../../../v/k/kmp_slp_jump_output.v) |
| Zig | [`zig/k/kmp_slp_jump_output.zig`](../../../zig/k/kmp_slp_jump_output.zig) |

See [RIGHTS.md](RIGHTS.md), the [primary oracle](../../kmp_slp_jump_output_oracle.py),
and the [independent verifier](../../kmp_slp_jump_output_verifier_oracle.py).
