# Monotone constant-interval partition

Given the monotone integer function
`f(i) = floor((step*i + offset) / divisor)` on `[0,n)`, emit its maximal
half-open intervals of constant value, in increasing index order. This is a
bounded profile of the recursive endpoint-pruning method in KACTL's
`ConstantIntervals.h`.

## Contract

The exported byte-output ABI symbol is `constant_intervals`. Input is the
four-word frame `[n, step, offset, divisor]` in the `i64_array_bytes_output`
family. `0 <= n <= 256`, `0 <= step, offset <= 65535`, and
`1 <= divisor <= 65535`. The construction guarantees a nondecreasing function.
The packed input length must be exactly four words; one trailing word is
accepted by the parser bound only so it can be rejected as malformed.

Output consists of `k` records, each three little-endian signed 32-bit values
`[lo, hi, f(lo)]`. Records partition `[0,n)` without gaps or overlaps and are
maximal: adjacent records have different values. The scalar result is `k`;
the output length is `12*k` bytes. Empty input range returns zero and writes no
bytes. Implementations require capacity for the worst case `12*n` bytes before
writing. Invalid input returns `-1`; null/short output storage returns `-2`
without writing. The maximum valid and parseable input lengths are 4 and 5
words. Maximum output workspace is 3072 bytes.

## Algorithm and distinctness

The primary recursively bisects an index interval. If its first and last
function values are equal, monotonicity proves every value inside is equal, so
the whole interval can be emitted at once. Otherwise it visits the two halves
in order, merging equal adjacent pieces at the output boundary. This skips
large constant regions and follows the notebook's endpoint-pruning structure;
the bounded profile takes `O(k log(1+n/k))` function evaluations and
`O(log n)` recursion space for `k` output intervals.

The independent arithmetic reference starts at the first unreported index
and solves the next change point directly: for current value `v`, the next
index is the least `i` with `step*i + offset >= (v+1)*divisor`. A direct
index-by-index grouping oracle is also included for small fixtures. These
methods do not use recursive endpoint pruning.

This differs from local [`compress`](../compress/README.md), which performs a
linear run scan over arbitrary supplied values. Here the input is a compact
description of a guaranteed monotone function, and the primary prunes an
entire index range after two endpoint queries. The dynamic
[`interval_container`](../../i/interval_container/README.md) and greedy
[`interval_cover`](../../i/interval_cover/README.md) packages solve different set
operations.

## Provenance

The discovery source is KACTL's [current Various chapter index](https://github.com/kth-competitive-programming/kactl/blob/b3548e973f8772010c1ef84e6d427c749733fd2c/content/various/chapter.tex),
which lists `ConstantIntervals.h`, and the [pinned algorithm entry](https://github.com/kth-competitive-programming/kactl/blob/b3548e973f8772010c1ef84e6d427c749733fd2c/content/various/ConstantIntervals.h).
That source labels the entry CC0 and describes monotone-function partitioning
by recursive subdivision. Only the algorithm idea is used; this contract,
workload, references, and ports are independently authored. See
[`RIGHTS.md`](RIGHTS.md).

[`workload.json`](workload.json) includes empty and constant functions,
plateaus, skipped quotient values, maximum input length, malformed headers,
and insufficient output capacity. The two algorithm references are
[`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py).
[`check_inventory.py`](check_inventory.py) statically records the ten source
ports and required package files; it has not been run.

## Language ports

| Language | Source |
|---|---|
| C | [`c/c/constant_intervals.c`](../../../c/c/constant_intervals.c) |
| C3 | [`c3/c/constant_intervals.c3`](../../../c3/c/constant_intervals.c3) |
| C++ | [`cpp/c/constant_intervals.cpp`](../../../cpp/c/constant_intervals.cpp) |
| Elisa | [`elisa/c/constant_intervals.elisa`](../../../elisa/c/constant_intervals.elisa) |
| Mojo | [`mojo/c/constant_intervals.mojo`](../../../mojo/c/constant_intervals.mojo) |
| Nim | [`nim/c/constant_intervals.nim`](../../../nim/c/constant_intervals.nim) |
| Odin | [`odin/c/constant_intervals.odin`](../../../odin/c/constant_intervals.odin) |
| Rust | [`rust/c/constant_intervals.rs`](../../../rust/c/constant_intervals.rs) |
| V | [`v/c/constant_intervals.v`](../../../v/c/constant_intervals.v) |
| Zig | [`zig/c/constant_intervals.zig`](../../../zig/c/constant_intervals.zig) |
