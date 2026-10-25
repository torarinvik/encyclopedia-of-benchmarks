# WikiSort bounded block-merge profile

## Contract

Sort a mutable sequence of signed 64-bit integers into ascending order. The nine ports use stable insertion-sorted runs of 16 items, bottom-up merge levels, and a fixed 512-item caller-provided cache. Merges whose left run fits the cache use a buffered stable merge. Larger merges use a bounded block-rotation fallback: it advances ordered prefixes, locates lower-bound blocks, and rotates adjacent ranges, using the cache for small rotations and three reversals for larger rotations. Fully reversed adjacent runs are exchanged with the same rotation helper. Lengths above 2,048 are outside this profile and are left unchanged.

This is an independently written bounded profile that preserves WikiSort's small-run, fixed-cache, and block/rotation merge architecture. It does not reproduce the complete upstream implementation, its internal key-buffer tagging strategy, nine test-case generators, or benchmark harness. The `i64` sort runner checks sorted values; stability follows from the left-before-right comparisons but is not observable for equal scalar values.

The C ABI entry point is:

```c
void wikisort(int64_t *values, int64_t *scratch, size_t length);
```

`scratch` points to storage for at least `length` signed 64-bit values. The implementation uses at most 512 entries. The sort runner prepares scratch before timing and calls the same `mutable_i64_with_scratch` interface used by the local merge-sort benchmark.

## Workload

[`workload.json`](workload.json) covers lengths 0, 16, 32, 64, 400, 1,024, and 2,048 using the runner's deterministic modular-affine input. The 400-element case matches the upstream array length; the 2,048-element case exercises the block-rotation fallback beyond the fixed cache size. [`wikisort_oracle.py`](../../wikisort_oracle.py) provides the independent sorted-array reference.

Build a port with `python3 benchmarks/build_abi.py --family sort --algorithm wikisort --language LANGUAGE`. The workload's scratch ABI selects the three-argument sort runner and checker. Use [`benchmarks/run_sort.py`](../../run_sort.py) to record the workload.

## Source and rights

- Embench source pinned at [`src/wikisort/libwikisort.c`](https://github.com/embench/embench-iot/blob/de24bdf561f4eaad7f37685641fa301f2b8b4bc3/src/wikisort/libwikisort.c), commit `de24bdf561f4eaad7f37685641fa301f2b8b4bc3`.
- The Embench file declares `GPL-3.0-or-later` and attributes the original WikiSort to [BonzaiThePenguin/WikiSort](https://github.com/BonzaiThePenguin/WikiSort), noting that it was placed in the public domain.
- The implementations in this package were written independently from the algorithm contract; no upstream source code was copied or translated. [`LICENSE.txt`](LICENSE.txt) preserves the license text declared by the pinned Embench source for source attribution.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/w/wikisort.c`](../../../c/w/wikisort.c) |
| C3 | [`c3/w/wikisort.c3`](../../../c3/w/wikisort.c3) |
| C++ | [`cpp/w/wikisort.cpp`](../../../cpp/w/wikisort.cpp) |
| Elisa | [`elisa/w/wikisort.elisa`](../../../elisa/w/wikisort.elisa) |
| Nim | [`nim/w/wikisort.nim`](../../../nim/w/wikisort.nim) |
| Odin | [`odin/w/wikisort.odin`](../../../odin/w/wikisort.odin) |
| Rust | [`rust/w/wikisort.rs`](../../../rust/w/wikisort.rs) |
| V | [`v/w/wikisort.v`](../../../v/w/wikisort.v) |
| Zig | [`zig/w/wikisort.zig`](../../../zig/w/wikisort.zig) |
