# Fixed-cardinality combinations in Gray order

Generate all `K`-element subsets of an `N`-element set in reflected Gray-code
order. Consecutive output masks differ by exactly two bits: one selected
element leaves and one enters. The order also wraps between the last and first
mask for nontrivial profiles.

## Contract

The ABI is `i64_array_bytes_output`, symbol `gray_code_k_combinations`. Input
is exactly `[N,K]`, with `0 <= N <= 12` and `0 <= K <= N`. The output is a
little-endian u16 combination count followed by that many little-endian u16
position masks. Bit `i` selects element `i`. The scalar return is the number
of combinations, `C(N,K)`. For `[0,0]`, the single empty combination is mask
zero. Malformed, null, or out-of-profile input returns `-1`; a null output or
capacity below `2 + 2*C(N,K)` returns `-2` without writing.

The maximum sequence has `C(12,6)=924` masks and occupies 1,850 bytes,
including the count header. The primary scans the `2^N` reflected Gray masks
and retains those with exactly `K` set bits. This bounded profile takes
`O(N*2^N)` time and `O(1)` auxiliary space beyond the output buffer. The
independent reference directly generates the fixed-weight reflected Gray
sequence from the recursive recurrence, rather than filtering all subsets.

## Distinction

[`subset_combinations`](../../s/subset_combinations/README.md) emits fixed-size
subsets in lexicographic index order. [`gray_code`](../gray_code/README.md)
emits every subset, regardless of cardinality. This benchmark emits only
fixed-cardinality subsets, in the minimal-change cyclic Gray order; it thus
uses a different traversal and has a distinct observable sequence.

## Source and rights

The sequence and traversal come from CP-Algorithms' [Generating all
K-combinations](https://cp-algorithms.com/combinatorics/generating_combinations.html)
article. The primary follows its reflected-Gray-code filtering method; the
recursive fixed-weight recurrence supplies the independent reference. The
article is CC BY-SA 4.0. This package uses algorithm descriptions only and
contains clean-room code, fixtures, and documentation. See
[`RIGHTS.md`](RIGHTS.md).

[`workload.json`](workload.json) includes hand-derived masks for small and
boundary cases, a maximum-`N` case, malformed frames, and output-capacity
failures. [`primary_oracle.py`](primary_oracle.py) mirrors the Gray-mask
filter. [`independent_oracle.py`](independent_oracle.py) uses the direct
recursive recurrence. [`inventory.json`](inventory.json) records the ten
ports and source identity; [`check_inventory.py`](check_inventory.py) is a
static source/workload verifier and has not been run.

| Language | Source |
|---|---|
| C | [`c/g/gray_code_k_combinations.c`](../../../c/g/gray_code_k_combinations.c) |
| C3 | [`c3/g/gray_code_k_combinations.c3`](../../../c3/g/gray_code_k_combinations.c3) |
| C++ | [`cpp/g/gray_code_k_combinations.cpp`](../../../cpp/g/gray_code_k_combinations.cpp) |
| Elisa | [`elisa/g/gray_code_k_combinations.elisa`](../../../elisa/g/gray_code_k_combinations.elisa) |
| Mojo | [`mojo/g/gray_code_k_combinations.mojo`](../../../mojo/g/gray_code_k_combinations.mojo) |
| Nim | [`nim/g/gray_code_k_combinations.nim`](../../../nim/g/gray_code_k_combinations.nim) |
| Odin | [`odin/g/gray_code_k_combinations.odin`](../../../odin/g/gray_code_k_combinations.odin) |
| Rust | [`rust/g/gray_code_k_combinations.rs`](../../../rust/g/gray_code_k_combinations.rs) |
| V | [`v/g/gray_code_k_combinations.v`](../../../v/g/gray_code_k_combinations.v) |
| Zig | [`zig/g/gray_code_k_combinations.zig`](../../../zig/g/gray_code_k_combinations.zig) |
