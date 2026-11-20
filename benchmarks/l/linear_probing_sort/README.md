# Linear probing sort

Linear probing sort distributes each value to a table slot estimated by linear interpolation between the input minimum and maximum. A collision advances to the next empty slot. A second pass scans the table and compacts occupied slots back into the input array.

## Bounded contract

The `sort_call` ABI sorts arrays of zero through 1,024 signed 64-bit values in ascending order. The benchmark domain is the byte-valued key range `0..255`; duplicates are allowed. Empty and singleton arrays are unchanged. The implementation also falls back to insertion sort for an input outside this profile so the ABI still returns a sorted array.

For an input of length `n`, the table has `m = 256 * (n + 1) + 1` main slots and `n` overflow slots at its end. For `minimum < maximum`, a key `x` has home slot `floor((x - minimum) * (m - 1) / (maximum - minimum))`; when all keys are equal, the home slot is zero. An occupied slot advances the key to the next empty slot. Empty slots contain zero, and a stored byte key is represented as `key + 1`.

Distinct byte keys have home-slot gaps of at least `n + 1`. A probe run for one key contains at most `n` equal keys, so it cannot reach the next distinct key's home. This makes the table scan ascending even when equal keys were inserted in arbitrary order. The `n` extra overflow slots are sufficient for a full run of duplicates at the final home slot, so the NIST definition's overflow failure condition cannot occur within this contract. Clearing and compaction take `O(m+n)` time; insertion can take `O(n^2)` in the worst case when many equal keys share one home slot. The per-call workspace is `8 * (m+n)` bytes, at most 2,107,400 bytes at `n=1,024`. Allocation and table clearing are part of the timed sort call.

This is distinct from [`bucket_sort`](../../b/bucket_sort/README.md), which groups values by fixed-width high bits and insertion-sorts each bucket, and [`flash_sort`](../../f/flash_sort/README.md), which classifies elements into classes before a cycle-permutation phase. The local [`linear_probing_hash_map`](../../l/linear_probing_hash_map/README.md) uses open addressing for map operations and does not interpolate key positions or compact a sorted output.

## Workload and references

[`workload.json`](workload.json) uses deterministic modular-affine byte keys at lengths 0, 16, 64, 256, and 1,024. Semantic fixtures include all-equal keys, reversed keys, sparse keys, and repeated-key probe runs. The custom verifier also checks 1,023 copies of the maximum key followed by the minimum key, forcing a maximum-home probe run into the overflow area. The primary reference simulates the interpolation table and linear probing; an independent built-in sort checks the same bounded inputs.

The algorithm contract is from the [NIST Dictionary of Algorithms and Data Structures entry](https://xlinux.nist.gov/dads/HTML/linearProbingSort.html), modified 12 February 2019 and accessed 2026-11-16. The local contract makes the input domain and extra-space sizing explicit so collisions cannot reorder different keys. The package uses the algorithm description only, without copying source code or prose.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/l/linear_probing_sort.c`](../../../c/l/linear_probing_sort.c) |
| C3 | [`c3/l/linear_probing_sort.c3`](../../../c3/l/linear_probing_sort.c3) |
| C++ | [`cpp/l/linear_probing_sort.cpp`](../../../cpp/l/linear_probing_sort.cpp) |
| Elisa | [`elisa/l/linear_probing_sort.elisa`](../../../elisa/l/linear_probing_sort.elisa) |
| Mojo | [`mojo/l/linear_probing_sort.mojo`](../../../mojo/l/linear_probing_sort.mojo) |
| Nim | [`nim/l/linear_probing_sort.nim`](../../../nim/l/linear_probing_sort.nim) |
| Odin | [`odin/l/linear_probing_sort.odin`](../../../odin/l/linear_probing_sort.odin) |
| Rust | [`rust/l/linear_probing_sort.rs`](../../../rust/l/linear_probing_sort.rs) |
| V | [`v/l/linear_probing_sort.v`](../../../v/l/linear_probing_sort.v) |
| Zig | [`zig/l/linear_probing_sort.zig`](../../../zig/l/linear_probing_sort.zig) |
