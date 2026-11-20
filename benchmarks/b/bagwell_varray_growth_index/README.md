# Bagwell VArray append and indexed lookup

This benchmark builds a signed 64-bit VArray by appending `n` values, then
returns `q` indexed reads in the supplied order. It measures Bagwell's
non-copying, two-dimensional block growth and the lookup path through its
pointer-block levels.

## Contract

Input is `[n, q, values[0..n), indices[0..q))`. `0 <= n <= 321` and
`0 <= q <= 256`; when `n=0`, `q` must be zero. Each index must satisfy
`0 <= index < n`. The frame must contain exactly `2+n+q` signed 64-bit words.
Malformed input returns `-1`. Valid input with a null output or capacity below
`8*(q+1)` returns `-2`, without writing. Success returns the number of output
bytes written.

Output is little-endian signed 64-bit words `[q, values[indices[0]], ...]`.
The count is included even when `q=0`. Maximum valid input is 579 words;
the one-extra-word parseable frame is 580 words. Maximum output is 2,056 bytes.
The fixed workspace cap is 4,096 bytes, excluding input and output buffers.

## Source-derived layout and indexing

Bagwell's §4 and Fig. 7 show one VArray profile with `r=0.25`, equal-sided
two-dimensional blocks, and initial side `s=8`. Its first pointer block has
eight child pointers; each child points to an eight-element data sub-block,
so that level holds 64 values. When it fills, the array starts a side-16 level
and links that level to the completed side-8 level. After 256 more values, the
side-32 level begins. The bounded profile stops after the first side-32 data
sub-block, at length 321.

The paper gives the block geometry and growth rule but not indexing
pseudocode. This package derives the lookup map from Fig. 7. For level `l`,
let `s=8*2^l`, `P_l` be the number of values in earlier levels, `B_l` the
number of earlier pointer slots, and `D_l` the number of earlier data slots.
For an absolute index `i` in that level, let `r=i-P_l`:

| Level | `s` | `P_l` | `B_l` | `D_l` | Covered indices |
|---|---:|---:|---:|---:|---|
| 0 | 8 | 0 | 0 | 0 | 0–63 |
| 1 | 16 | 64 | 8 | 64 | 64–319 |
| 2 | 32 | 320 | 24 | 320 | 320 only (`n=321`) |

The child pointer slot is `B_l + floor(r/s)`; the in-child offset is `r mod s`,
and the child data block begins at `D_l + s*floor(r/s)`. Each level header
stores a link to the preceding completed level. At append indices 64 and 320,
the implementation creates the next header, links it to the current header,
and makes it current; it then allocates a child pointer once and writes to the
next unused offset. A lookup starts from the current header and follows these
previous-level links while the queried index is below that level's start. It
then applies that selected level's child-block mapping. No existing value is
copied when a level or child block is added. The bounded profile exercises
three linked levels and every boundary among them.

For `n<=321`, the fixed data pool is 352 i64 slots (all of levels 0 and 1,
plus one side-32 child), and the pointer table has 56 entries. Three i64
header-prev slots (a root sentinel and two predecessor links) add 24 bytes,
for 3,288 bytes of fixed table storage.
The current-header scalar and bounded locals fit within the remaining 808
bytes of the 4,096-byte workspace cap. Append is O(1) under the paper's
profile. Lookup follows at most two previous-level links in this bounded
three-level profile, then performs the child and element access. The
independent oracle uses a flat list and direct indexing.

The workload includes empty and singleton arrays, child-block edges at every
side-8 and side-16 boundary, the 64/65 and 320/321 level transitions, maximum
`n` and `q`, a 580-word maximum-parseable trailing-frame rejection, and
malformed/null/capacity probes. See [`workload.json`](workload.json),
[`RIGHTS.md`](RIGHTS.md), and [`INVENTORY.md`](INVENTORY.md).

The primary source is Phil Bagwell, *Fast Functional Lists, Hash-Lists, Deques
and Variable Length Arrays*, §4, Fig. 7, and §4.1. The report's one-million
append/sequential/random probe benchmark motivates this append-then-probe
profile; this package uses small deterministic bounded traces. No source code,
report text, or protected examples are copied.

## Implementations

| Language | Source |
|---|---|
| C | [`c/b/bagwell_varray_growth_index.c`](../../../c/b/bagwell_varray_growth_index.c) |
| C3 | [`c3/b/bagwell_varray_growth_index.c3`](../../../c3/b/bagwell_varray_growth_index.c3) |
| C++ | [`cpp/b/bagwell_varray_growth_index.cpp`](../../../cpp/b/bagwell_varray_growth_index.cpp) |
| Elisa | [`elisa/b/bagwell_varray_growth_index.elisa`](../../../elisa/b/bagwell_varray_growth_index.elisa) |
| Mojo | [`mojo/b/bagwell_varray_growth_index.mojo`](../../../mojo/b/bagwell_varray_growth_index.mojo) |
| Nim | [`nim/b/bagwell_varray_growth_index.nim`](../../../nim/b/bagwell_varray_growth_index.nim) |
| Odin | [`odin/b/bagwell_varray_growth_index.odin`](../../../odin/b/bagwell_varray_growth_index.odin) |
| Rust | [`rust/b/bagwell_varray_growth_index.rs`](../../../rust/b/bagwell_varray_growth_index.rs) |
| V | [`v/b/bagwell_varray_growth_index.v`](../../../v/b/bagwell_varray_growth_index.v) |
| Zig | [`zig/b/bagwell_varray_growth_index.zig`](../../../zig/b/bagwell_varray_growth_index.zig) |

`check_inventory.py` checks package metadata and source paths without compiling
or running the ports. `verify_workload.py` exposes static reference/workload
reconciliation for later suite integration.
