# Mo's algorithm

This package benchmarks the pinned Java implementation's offline range-sum
and fixed-target range-frequency methods. Both use Mo ordering with a block
size of `floor(sqrt(n))`; queries are ordered by left block and alternate the
right endpoint direction between even and odd blocks. Results are returned in
the caller's query-index order.

## Contract

The `i64_array_scalar` input is
`[op, n, q, target, values[n], (left, right, index)*q]` with exact length
`4 + n + 3*q`. The array is nonempty (`n` 1..256), query count is 0..256,
and array values and the fixed target are signed integers in -1,000,000..1,000,000.
Ranges are inclusive and must satisfy `0 <= left <= right < n`. Query indices
must be a permutation of `0..q-1` so each result has one destination slot.

- `op=0` runs `solveRangeSumQueries`; each query result is the inclusive range
  sum.
- `op=1` runs `solveRangeFrequencyQueries`; each query result is the number of
  values equal to `target` in its inclusive range.

The scalar result is the low 63 bits of FNV-1a-64 over the byte stream
`op:u8`, `q:u16` little-endian, then each signed-i32 result in original query
order as four little-endian two's-complement bytes. The FNV offset basis is
`14695981039346656037` and the prime is `1099511628211`. The input bounds keep
all range sums within signed 32-bit. Malformed input returns `-1`.

The [independent oracle](../../mos_algorithm_oracle.py) uses direct range scans
to calculate each result. The [workload](workload.json) includes both query
modes, empty query sets, arbitrary result indices, ranges spanning Mo blocks,
repeated ranges, signed value boundaries, and malformed inputs.

## Upstream source

- [TheAlgorithms/Java `MosAlgorithm.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/MosAlgorithm.java)

| Language | Port |
|---|---|
| C | [`c/m/mos_algorithm.c`](../../../c/mos_algorithm.c) |
| C3 | [`c3/m/mos_algorithm.c3`](../../../c3/m/mos_algorithm.c3) |
| C++ | [`cpp/m/mos_algorithm.cpp`](../../../cpp/m/mos_algorithm.cpp) |
| Elisa | [`elisa/m/mos_algorithm.elisa`](../../../elisa/m/mos_algorithm.elisa) |
| Nim | [`nim/m/mos_algorithm.nim`](../../../nim/m/mos_algorithm.nim) |
| Odin | [`odin/m/mos_algorithm.odin`](../../../odin/m/mos_algorithm.odin) |
| Rust | [`rust/m/mos_algorithm.rs`](../../../rust/m/mos_algorithm.rs) |
| V | [`v/m/mos_algorithm.v`](../../../v/m/mos_algorithm.v) |
| Zig | [`zig/m/mos_algorithm.zig`](../../../zig/m/mos_algorithm.zig) |
