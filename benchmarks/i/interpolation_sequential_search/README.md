# Interpolation-sequential search

Search a strictly increasing signed integer array by interpolating one initial
position from the first and last values, then scanning linearly from that
position. If the estimated value is below the target, scan forward; if it is
above the target, scan backward. Stop at a match or the first value that
crosses the target.

This is distinct from local [`interpolation_search`](../interpolation_search/README.md),
which repeatedly interpolates and narrows the active interval. This profile
performs one interpolation estimate followed by a linear scan.

## Contract

The `i64_array_scalar` input is `[n, target, values...]`, with exactly `n+2`
words and `0 <= n <= 64`. Values and target must be in
`[-1,000,000, 1,000,000]`; values must be strictly increasing. Empty arrays are
valid and return `-1`. Return the unique zero-based target index, or `-1` if
the target is absent or the input is invalid. The interpolation numerator is
bounded by `2,000,000 * 63`, so signed 64-bit arithmetic is sufficient.

The largest valid input has 66 words; one additional parseable word is
reserved to check a trailing-value frame. The algorithm reads the packed
input directly and uses no auxiliary workspace.

## Workload and references

[`workload.json`](workload.json) covers empty and singleton arrays, uniform
hits, forward and backward scans from a skewed interpolation estimate, misses
outside the array range, the maximum input, invalid order and duplicate
values, range violations, and malformed frames. The primary reference mirrors
the one-estimate scan; the independent reference scans from the beginning.
Both references reject malformed or out-of-domain inputs.

The method is identified by the NIST Dictionary of Algorithms and Data
Structures entry for
[interpolation-sequential search](https://xlinux.nist.gov/dads/HTML/interpsequen.html).
The implementations and fixtures are independently written; no source code
or prose is copied. See [`RIGHTS.md`](RIGHTS.md) and
[`INVENTORY.md`](INVENTORY.md).

## Implementations

| Language | Port |
| --- | --- |
| C | [`c/i/interpolation_sequential_search.c`](../../../c/i/interpolation_sequential_search.c) |
| C3 | [`c3/i/interpolation_sequential_search.c3`](../../../c3/i/interpolation_sequential_search.c3) |
| C++ | [`cpp/i/interpolation_sequential_search.cpp`](../../../cpp/i/interpolation_sequential_search.cpp) |
| Elisa | [`elisa/i/interpolation_sequential_search.elisa`](../../../elisa/i/interpolation_sequential_search.elisa) |
| Mojo | [`mojo/i/interpolation_sequential_search.mojo`](../../../mojo/i/interpolation_sequential_search.mojo) |
| Nim | [`nim/i/interpolation_sequential_search.nim`](../../../nim/i/interpolation_sequential_search.nim) |
| Odin | [`odin/i/interpolation_sequential_search.odin`](../../../odin/i/interpolation_sequential_search.odin) |
| Rust | [`rust/i/interpolation_sequential_search.rs`](../../../rust/i/interpolation_sequential_search.rs) |
| V | [`v/i/interpolation_sequential_search.v`](../../../v/i/interpolation_sequential_search.v) |
| Zig | [`zig/i/interpolation_sequential_search.zig`](../../../zig/i/interpolation_sequential_search.zig) |
