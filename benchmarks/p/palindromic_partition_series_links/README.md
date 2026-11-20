# Minimum palindrome partition with series links

This package computes a minimum partition of a short symbol sequence into
palindromes. Its primary method builds an eertree online and groups suffix
palindromes into equal-difference series. Series links let the prefix dynamic
program aggregate one arithmetic progression of suffix lengths at a time.

The existing [`palindromic_partitioning`](../palindromic_partitioning/README.md)
uses a quadratic palindrome table and prefix DP, and returns the minimum cut
count. The existing [`eertree`](../../e/eertree/README.md) reports distinct
palindrome counts for each prefix. This package measures the different
series-link recurrence and returns the full minimum-piece partition.

## Contract

- Input is `[n, symbols...]`, with `0<=n<=64` and each symbol in `0..3`.
- Output is `[piece_count, piece_lengths...]`, encoded as little-endian signed
  64-bit words. Piece lengths are listed left to right and sum to `n`.
- For each prefix, ties between minimum-piece partitions choose the smallest
  preceding prefix index, hence the longest possible final palindrome. The
  final partition is reconstructed by following those prefix choices backward.
- The empty sequence has zero pieces and emits `[0]`. Maximum output is 520
  bytes. Invalid input returns `-1`; null or insufficient output returns `-2`
  without writing.

The primary reference uses the eertree `diff` and series-link recurrence. The
independent reference checks all substrings in a palindrome table and performs
quadratic prefix dynamic programming with the same tie rule.

## Source and rights

The algorithm is described in the OI Wiki contributors' [Palindromic Tree
article](https://www.timothywang.ca/OI-wiki/string/pam/), in its “Minimum
Palindromic Partition” optimization section. The page states CC BY-SA 4.0 and
SATA terms. The ports use the algorithm description only; no article code,
prose, figures, examples, or tests are reproduced. See [RIGHTS.md](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/palindromic_partition_series_links.c`](../../../c/palindromic_partition_series_links.c) |
| C3 | [`c3/palindromic_partition_series_links.c3`](../../../c3/palindromic_partition_series_links.c3) |
| C++ | [`cpp/palindromic_partition_series_links.cpp`](../../../cpp/palindromic_partition_series_links.cpp) |
| Elisa | [`elisa/palindromic_partition_series_links.elisa`](../../../elisa/palindromic_partition_series_links.elisa) |
| Mojo | [`mojo/palindromic_partition_series_links.mojo`](../../../mojo/palindromic_partition_series_links.mojo) |
| Nim | [`nim/palindromic_partition_series_links.nim`](../../../nim/palindromic_partition_series_links.nim) |
| Odin | [`odin/palindromic_partition_series_links.odin`](../../../odin/palindromic_partition_series_links.odin) |
| Rust | [`rust/palindromic_partition_series_links.rs`](../../../rust/palindromic_partition_series_links.rs) |
| V | [`v/palindromic_partition_series_links.v`](../../../v/palindromic_partition_series_links.v) |
| Zig | [`zig/palindromic_partition_series_links.zig`](../../../zig/palindromic_partition_series_links.zig) |

See the [workload](workload.json), [series-link reference](primary_oracle.py),
[independent reference](independent_oracle.py), and static inventory
[`verify_workload.py`](verify_workload.py).
