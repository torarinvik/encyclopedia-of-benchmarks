# Oscillating Merge Sort

This benchmark models the NIST DADS oscillating external merge method with a
fixed four-tape profile. It first sorts consecutive runs of 16 values. It then
recursively distributes runs across two merge-input tapes, creates child runs
in the opposite direction, reads those runs backward, and merges them in the
current direction. The top-level result is ascending. Tape contents and
backward reads are simulated with bounded memory; no physical disk I/O is
included.

## Contract

The benchmark uses the in-place `sort_call` ABI:

```c
void oscillating_merge_sort(int64_t *values, size_t length);
```

It sorts 0–1,024 signed 64-bit values in ascending order. The profile fixes
four total tapes, two merge-input lanes (`tape_count - 2`), and an initial run
size of 16. Values above the bound are outside the workload contract and are
left unchanged. The bounded workspace budget is 106,496 bytes of value slots:
six levels of two 1,024-value run buffers plus a 1,024-value result buffer.
Those buffers are part of the timed call. Mojo uses bounded dynamic run lists;
the budget excludes allocator metadata.

The primary oracle simulates the alternating-direction recursive run tree and
backward-read merge. The independent oracle uses the host language's built-in
integer ordering. The custom verifier checks bounded cases with the shared sort
checker and records the standard generated lengths with the shared sort
runner; it has not been run.

## Algorithm and distinction

NIST DADS describes distributing runs across `n-2` tapes and merging them
while reading those tapes backward. The alternating direction lets backward
reads supply runs in the next merge's direction. This timed algorithm differs
from the local [External Merge Sorter](../../e/external_merge_sorter/README.md),
which doubles run width in sequential passes over two buffers. Local k-way
merge routines accept already-sorted collections; this profile creates an
alternating multi-level run hierarchy and models backward tape reads.

Sources: [NIST DADS entry](https://xlinux.nist.gov/dads/HTML/oscillatingMergeSort.html)
and Sheldon Sobel, “Oscillating Sort—A New Sort Merging Technique,” *Journal of
the ACM* 9(3), 372–374 (1962), [DOI 10.1145/321127.321133](https://doi.org/10.1145/321127.321133).
The code is a clean-room implementation of the algorithm description; no
source implementation, tests, or examples were copied.

See [`workload.json`](workload.json), [`RIGHTS.md`](RIGHTS.md), and
[`INVENTORY.md`](INVENTORY.md). The custom verifier is
[`benchmarks/verify_oscillating_merge_sort.py`](../../verify_oscillating_merge_sort.py).

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/o/oscillating_merge_sort.c`](../../../c/o/oscillating_merge_sort.c) |
| C3 | [`c3/o/oscillating_merge_sort.c3`](../../../c3/o/oscillating_merge_sort.c3) |
| C++ | [`cpp/o/oscillating_merge_sort.cpp`](../../../cpp/o/oscillating_merge_sort.cpp) |
| Elisa | [`elisa/o/oscillating_merge_sort.elisa`](../../../elisa/o/oscillating_merge_sort.elisa) |
| Mojo | [`mojo/o/oscillating_merge_sort.mojo`](../../../mojo/o/oscillating_merge_sort.mojo) |
| Nim | [`nim/o/oscillating_merge_sort.nim`](../../../nim/o/oscillating_merge_sort.nim) |
| Odin | [`odin/o/oscillating_merge_sort.odin`](../../../odin/o/oscillating_merge_sort.odin) |
| Rust | [`rust/o/oscillating_merge_sort.rs`](../../../rust/o/oscillating_merge_sort.rs) |
| V | [`v/o/oscillating_merge_sort.v`](../../../v/o/oscillating_merge_sort.v) |
| Zig | [`zig/o/oscillating_merge_sort.zig`](../../../zig/o/oscillating_merge_sort.zig) |
