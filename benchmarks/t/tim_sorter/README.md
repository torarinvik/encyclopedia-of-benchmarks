# Stable TimSorter trace

This benchmark follows the pinned C# `TimSorter<T>` on records with an integer
sort key and a unique item ID. It returns an order-sensitive checksum of the
sorted records, so equal-key stability is observable.

## Contract

The `i64_array_scalar` input is
`[item_count, (key, item_id) * item_count]`. There are 0 through 512 items.
Keys are integers from -1,000 through 1,000 inclusive. Every item ID must be
unique and in `0..item_count-1`.

Sort by key in ascending order only. Items with equal keys retain their
relative input order; item IDs are not a secondary sort key. The benchmark
constructs the source sorter with `TimSorterSettings(minMerge: 32,
minGallop: 7)` and an ascending key comparer. It passes a descending comparer
to `Sort`, but the pinned method ignores that argument and uses the comparer
stored by the constructor. The effective order is therefore ascending by key.

The constructor snapshots `initMinGallop` before assigning the settings value
to `minGallop`. Since the field's default is zero, `initMinGallop` remains zero
while the initial `minGallop` value is seven. The source uses `minGallop` to
enter gallop mode and `initMinGallop` as the continuation threshold, so this
quirk affects merge strategy rather than the stable sorted order or checksum.
Portable language ports may omit galloping as a performance optimization; they
must preserve the stable key ordering and checksum, but need not reproduce the
source's internal galloping path or its `initMinGallop` behavior.

For each sorted `(key, item_id)`, compute
`token = (key + 1,000) * 513 + item_id + 1`, then update
`checksum = (checksum * 1,000,003 + token) mod 1,000,000,007`, starting from
zero. The empty input returns zero. Malformed framing, a count outside the
limit, a key outside its range, or a repeated/out-of-range item ID returns
`-1`. Valid checksums lie in `[0, 1,000,000,006]` and cannot collide with the
invalid result. The maximum valid frame contains 1,025 integers; the maximum
parseable frame contains 1,026.

The source uses binary insertion sort below its `minMerge` threshold and
natural-run detection plus stable merges at or above that threshold. The
workload includes lengths 31, 32, and 33, duplicate-key runs, descending runs,
and an order-sensitive 512-item case.

## Pinned sources

- TheAlgorithms/C-Sharp [`TimSorter.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sorters/Comparison/TimSorter.cs), commit `96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c`
- The fixed settings type, [`TimSorterSettings.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sorters/Comparison/TimSorterSettings.cs), same commit

## Workload

The workload is [`workload.json`](workload.json); the independent stable-sort
oracle is [`benchmarks/tim_sorter_oracle.py`](../../tim_sorter_oracle.py).
