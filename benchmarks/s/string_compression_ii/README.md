# String Compression II

Find the shortest run-length encoded length obtainable by deleting at most a
bounded number of symbols from one lowercase string. The output is only the
length; no compressed text or deletion witness is produced.

## Contract

The `i64_array_scalar` input is `[n,k,symbol_0,...,symbol_(n-1)]`. The bounded
profile accepts `0<=n<=12`, `0<=k<=n`, and symbol values in `0..25` (lowercase
letters represented by `a=0` through `z=25`). The exact length is `n+2`, the
maximum valid frame is 14 signed 64-bit words, and one extra parseable word
makes the maximum parseable frame 15. The empty string is accepted as a useful
extension of the source problem; its encoding length is zero. Null, malformed,
or out-of-domain input returns `-1`.

The encoding groups equal adjacent retained symbols. A run of length one costs
one output character. A run of length `r>=2` costs one character plus the
number of decimal digits in `r`; the count `1` is never emitted. The answer is
the minimum total run cost among subsequences formed by deleting no more than
`k` input symbols. Return values are in `0..12` for valid input.

The primary uses prefix dynamic programming over input position and the exact
number of deletions already used. From a state at position `i`, it either
deletes the next symbol or starts a run with that symbol and scans a later
endpoint `j`. For that span it considers every positive number of retained
copies of the starting symbol; all other span symbols are deleted. The
transition adds the run's encoded length and advances to `j+1`. Taking the
minimum over final deletion counts `0..k` enforces the at-most budget. This
takes `O(n^3 k)` time and `O(nk)` space under the fixed bound.

The independent reference enumerates every deletion mask of size at most `k`,
builds the retained symbol sequence, and counts each maximal run directly. It
takes `O(n 2^n)` time and `O(n)` space. The package workload pins the count-size
changes at 9 and 10, merging separated runs after deleting a symbol, empty
output, maximum input, and malformed frames.

## Sources, provenance, and overlap

The operation is specified by LeetCode's public [1531. String Compression II
page](https://leetcode.com/problems/string-compression-ii/), which defines the
deletion budget and the minimum encoded-length objective. The conventional
singleton and repeated-run length rule is also documented on LeetCode's
[String Compression page](https://leetcode.com/problems/string-compression/).
These pages are method references only; this package does not reuse their code
or examples. See [`RIGHTS.md`](RIGHTS.md).

This differs from local [`string_compression`](../string_compression/README.md),
which encodes the original sequence without deletions, and
[`run_length_encoding`](../../r/run_length_encoding/README.md), which emits a
count-prefixed representation. [`rle_lcs_block_dp`](../../r/rle_lcs_block_dp/README.md)
and [`rle_levenshtein_block_dp`](../../r/rle_levenshtein_block_dp/README.md)
compare already-compressed strings. None optimizes ordinary-string RLE size
over a deletion choice.

See [`workload.json`](workload.json), [`INVENTORY.md`](INVENTORY.md), and the
static [`check_inventory.py`](check_inventory.py). The inventory helper has
not been run.

## Language ports

| Language | Source |
|---|---|
| C | [`c/s/string_compression_ii.c`](../../../c/s/string_compression_ii.c) |
| C3 | [`c3/s/string_compression_ii.c3`](../../../c3/s/string_compression_ii.c3) |
| C++ | [`cpp/s/string_compression_ii.cpp`](../../../cpp/s/string_compression_ii.cpp) |
| Elisa | [`elisa/s/string_compression_ii.elisa`](../../../elisa/s/string_compression_ii.elisa) |
| Mojo | [`mojo/s/string_compression_ii.mojo`](../../../mojo/s/string_compression_ii.mojo) |
| Nim | [`nim/s/string_compression_ii.nim`](../../../nim/s/string_compression_ii.nim) |
| Odin | [`odin/s/string_compression_ii.odin`](../../../odin/s/string_compression_ii.odin) |
| Rust | [`rust/s/string_compression_ii.rs`](../../../rust/s/string_compression_ii.rs) |
| V | [`v/s/string_compression_ii.v`](../../../v/s/string_compression_ii.v) |
| Zig | [`zig/s/string_compression_ii.zig`](../../../zig/s/string_compression_ii.zig) |
