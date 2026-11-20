# Burstsort

Burstsort sorts variable-length strings using a trie whose leaves hold small
string buckets. When an insertion grows a leaf bucket past its threshold, the
bucket bursts into a trie node and its strings are redistributed by the next
byte. Lexicographic traversal visits end-of-string entries before byte
children, then insertion-sorts any residual bucket of at most three strings. This benchmark fixes the
threshold at three, so the fourth non-ended string causes a burst.

## Contract

The scalar ABI receives `[n, (length, byte_0, ..., byte_(length-1))*n]`.
There are 0..16 strings; each is 0..8 bytes long with byte values 0..3. Length
words make empty strings and embedded zero bytes unambiguous. Input framing must
be exact; malformed inputs and null pointers return `-1`.

After sorting, the result is a weighted checksum. A string is encoded as eight
base-5 digits: byte `b` at index `j` contributes `(b+1)*5^(7-j)` and all
remaining positions are zero end markers. This encoding preserves
lexicographic order, including the rule that a proper prefix sorts first. The
result sums `rank * key(string)` with one-based ranks. The empty list and lists
of only empty strings return zero.

The primary oracle constructs a burst trie with fixed bucket threshold three.
The independent oracle uses the host language's byte-string sort. Both use
the same contract and checksum encoding but different sorting procedures.

The algorithm is distinct from local
[`multikey_quick_sort`](../../m/multikey_quick_sort/README.md),
[`msd_radix_string_sorter`](../../m/msd_radix_string_sorter/README.md), and
[`american_flag_string_sorter`](../../a/american_flag_string_sorter/README.md):
those partition by character or distribute through radix buckets, while this
profile converts bounded leaf buckets into trie nodes when their capacity is
exceeded.

## References

Ranjan Sinha and Justin Zobel, “Cache-Conscious Sorting of Large Sets of
Strings with Dynamic Tries,” *ACM Journal of Experimental Algorithmics* 9
(2004), [DOI 10.1145/1005813.1041517](https://doi.org/10.1145/1005813.1041517).
Only the published algorithm description is used; no source code is copied.

## Implementations

| Language | Source |
|---|---|
| C | [c/b/burstsort.c](../../../c/b/burstsort.c) |
| C3 | [c3/b/burstsort.c3](../../../c3/b/burstsort.c3) |
| C++ | [cpp/b/burstsort.cpp](../../../cpp/b/burstsort.cpp) |
| Elisa | [elisa/b/burstsort.elisa](../../../elisa/b/burstsort.elisa) |
| Mojo | [mojo/b/burstsort.mojo](../../../mojo/b/burstsort.mojo) |
| Nim | [nim/b/burstsort.nim](../../../nim/b/burstsort.nim) |
| Odin | [odin/b/burstsort.odin](../../../odin/b/burstsort.odin) |
| Rust | [rust/b/burstsort.rs](../../../rust/b/burstsort.rs) |
| V | [v/b/burstsort.v](../../../v/b/burstsort.v) |
| Zig | [zig/b/burstsort.zig](../../../zig/b/burstsort.zig) |

Workload and expected scalar values are in [`workload.json`](workload.json).
