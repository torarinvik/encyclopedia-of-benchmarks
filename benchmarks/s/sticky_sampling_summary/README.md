# Sticky Sampling frequency summary (draft)

This reserved profile independently implements the singleton-stream algorithm
in Manku and Motwani's [2002 paper](https://www.vldb.org/conf/2002/S10P03.pdf),
section 4.1. Existing Lossy Counting, Misra–Gries, Space-Saving, and reservoir
sampling profiles use different update rules. This draft exposes the maintained
summary, without the paper's separate support-threshold query.

The proposed `i64_array_bytes_output` frame is
`[t,n,k,items[n],draws[k]]`, with `1<=t<=8`, `0<=n<=64`, `0<=k<=256`,
item IDs `0..15`, and draws `0..255`. Length must equal `3+n+k`. Draws are
replay input, not a generator: probabilistic claims require independent uniform
draws, which the ABI does not enforce.

Initially the sampling-rate denominator is 1; the first `2*t` stream items
use that denominator. Before processing the next item, double the denominator
and thin all currently retained counters in ascending item order. For each
counter, consume draws until an odd draw occurs or the counter becomes zero;
each even draw decrements it once, and reaching zero removes the entry without
consuming another draw. Subsequent phase lengths are `rate*t`, with the rate
doubling before each new phase. There is no transition after the final item.
For each stream item, increment a retained counter; otherwise consume one draw
and insert it with count one exactly when `draw % rate == 0`. Even at rate one
an absent item consumes a draw. All draws must be consumed exactly; shortage,
surplus, null input, or any malformed frame returns -1.

The output consists of little-endian signed i64 words
`[entry_count,(item,count)*entry_count]`, sorted by item ID. A valid frame with
null output or insufficient capacity returns -2 without writes, after complete
input and draw-consumption validation. Maximum valid/parseable frame lengths
are 323/324 words; maximum output is 264 bytes. With this fixed alphabet and
bounded tape, time is `O(n + k + 16 * transitions)` and space is `O(16)`.

Two independently structured reference drafts and [C](../../../c/s/sticky_sampling_summary.c),
[C++](../../../cpp/s/sticky_sampling_summary.cpp), [Elisa](../../../elisa/s/sticky_sampling_summary.elisa),
[C3](../../../c3/s/sticky_sampling_summary.c3), [Nim](../../../nim/s/sticky_sampling_summary.nim),
[Odin](../../../odin/s/sticky_sampling_summary.odin), [Rust](../../../rust/s/sticky_sampling_summary.rs),
[V](../../../v/s/sticky_sampling_summary.v), [Mojo](../../../mojo/s/sticky_sampling_summary.mojo),
and [Zig](../../../zig/s/sticky_sampling_summary.zig) drafts are present but unexecuted.
Workload fixtures, an inventory checker, and byte-output suite integration are
drafted but unexecuted. Paper prose, code, and examples are not
copied; its reuse terms are recorded in [RIGHTS.md](RIGHTS.md).
