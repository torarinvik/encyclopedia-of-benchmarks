# Create Maximum Number

This benchmark selects exactly `k` digits from two ordered sources and returns
the lexicographically greatest sequence that preserves the order within each
source. It measures a split enumeration, two monotone-stack subsequence
selections, and a suffix-aware greedy merge.

## Contract

The exported symbol is
`create_maximum_number(input, length, output, capacity) -> i64` in the
`i64_array_bytes_output` ABI. The input is the signed-i64 array
`[m,n,k,A[0..m),B[0..n)]`. Each source length is in `0..=6`, `k` is in
`0..=m+n`, every digit is in `0..=9`, and the frame must contain exactly
`3+m+n` values. The maximum valid input has 15 values. A null input, malformed
frame, unsupported size, or invalid digit returns `-1` before output checks.

The output contains exactly `k` raw bytes, one byte per selected digit. There
is no count header or terminator. The return value is the number of bytes
written. A valid `k=0` result is empty and returns zero. A null output pointer
or capacity smaller than `k` returns `-2` without writing, including for the
empty result. The maximum output is 12 bytes; the declared workspace is 512
bytes and includes fixed staging and sequence arrays.

## Algorithm and deterministic choices

For every feasible count taken from the first source, the primary algorithm
selects that source's best subsequence and the complementary subsequence from
the second source. Each selection scans left to right with a decreasing
stack: a smaller prior digit is removed only while the deletion budget remains.
It then merges the two selected sequences by comparing their full remaining
suffixes. When one suffix is a proper prefix of the other, the longer suffix
is greater; identical suffixes choose the first source. Split counts are
visited in ascending order and an equal final sequence retains its first
candidate.

With `S` feasible splits, `S<=k+1`, the bounded primary work is
`O(S*(m+n+k^2))`: each split scans both sources, and direct suffix comparison
can take `O(k)` at each of `k` merge steps. Fixed auxiliary storage is
`O(m+n+k)`.

The independent oracle uses memoized skip/take dynamic programming over both
source positions and the remaining output length. It constructs and compares
candidate tuples directly, without split enumeration, monotone stacks, or
suffix merging. Its bounded time and certificate storage are `O(m*n*k^2)`.

## Distinction and workload

The operation is distinct from
[`maximum_subarray`](../../m/maximum_subarray/README.md), which maximizes a
contiguous sum, and
[`longest_increasing_subsequence`](../../l/longest_increasing_subsequence/README.md),
which returns only a length under a numeric ordering. The catalog candidate
`maximum_subsequence` is already resolved as a Kadane alias of `maximum_subarray`.
The nearby
[`largest_of_very_large_numbers`](../../l/largest_of_very_large_numbers/README.md)
compares powers through their logarithms. None selects subsequences from two
digit sources and combines them by suffix-aware lexicographic merge.

The [workload](workload.json) covers empty output, an empty source, selection
from both sources, exact suffix ties, a proper-prefix suffix comparison,
maximum input/output, malformed input, null pointers, and insufficient
capacity. The [primary oracle](primary_oracle.py) follows the split/stack/merge
method. The [independent oracle](independent_oracle.py) directly optimizes
source-position choices. `check_inventory.py` statically checks package files,
port inventory, ABI metadata, workload bounds, and the Elisa safe-view style.

## Provenance

The public LeetCode title “Create Maximum Number” was used as an algorithm
discovery index only. The local description, contract, ports, oracle, and
fixtures are independently written; the package does not reproduce the
problem text, examples, tests, submissions, or site code. See
[`RIGHTS.md`](RIGHTS.md), the [title page](https://leetcode.com/problems/create-maximum-number/),
and [LeetCode terms](https://leetcode.com/terms/).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/create_maximum_number.c`](../../../c/c/create_maximum_number.c) |
| C3 | [`c3/c/create_maximum_number.c3`](../../../c3/c/create_maximum_number.c3) |
| C++ | [`cpp/c/create_maximum_number.cpp`](../../../cpp/c/create_maximum_number.cpp) |
| Elisa | [`elisa/c/create_maximum_number.elisa`](../../../elisa/c/create_maximum_number.elisa) |
| Mojo | [`mojo/c/create_maximum_number.mojo`](../../../mojo/c/create_maximum_number.mojo) |
| Nim | [`nim/c/create_maximum_number.nim`](../../../nim/c/create_maximum_number.nim) |
| Odin | [`odin/c/create_maximum_number.odin`](../../../odin/c/create_maximum_number.odin) |
| Rust | [`rust/c/create_maximum_number.rs`](../../../rust/c/create_maximum_number.rs) |
| V | [`v/c/create_maximum_number.v`](../../../v/c/create_maximum_number.v) |
| Zig | [`zig/c/create_maximum_number.zig`](../../../zig/c/create_maximum_number.zig) |
