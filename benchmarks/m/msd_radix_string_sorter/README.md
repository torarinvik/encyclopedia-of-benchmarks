# MSD radix string sorter

This benchmark covers the pinned C# `MsdRadixStringSorter.Sort` implementation.
It sorts variable-length strings stably in lexicographic order using most
significant digit recursion. The source indexes .NET UTF-16 `char` values into
256 buckets, so the benchmark restricts every code unit to 0..255.

## Contract

- Input is a signed-i64 array `[n, length_0, codeUnit_0..., ..., length_(n-1),
  codeUnit_0...]`. There are exactly `n` strings; each length is 0..32 and each
  UTF-16 code unit is 0..255. `n` is 0..256. Empty strings, duplicate strings,
  and an empty string collection are valid.
- Sort the strings stably by their UTF-16 code-unit sequences. On the selected
  domain, those code units are also single-byte values. Stable placement of
  equal strings follows the source's counting/distribution passes.
- Since the source method returns `void`, the adapter returns a deterministic
  checksum of the sorted result: FNV-1a-64 over `n` as two little-endian bytes,
  then for each sorted string one length byte followed by its code-unit bytes.
  Return the low 63 bits of the hash.
- Invalid framing, counts, lengths, or code units return `-1`. The maximum
  valid packed input is 8,449 words; 8,450 words are admitted for malformed
  trailing-value coverage.

The checksum is benchmark serialization around the source's sorted array; it
does not change the sort order or string contents.

## Workload and oracle

[`workload.json`](workload.json) covers empty collections and strings, prefix
ordering, duplicates, byte boundaries, maximum count and length, malformed
framing, and invalid code units. The independent oracle is
[`benchmarks/msd_radix_string_sorter_oracle.py`](../../msd_radix_string_sorter_oracle.py).

## Reviewed source

[TheAlgorithms/C-Sharp `Algorithms/Sorters/String/MsdRadixStringSorter.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sorters/String/MsdRadixStringSorter.cs)

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm msd_radix_string_sorter --language rust
python3 benchmarks/run_i64_array_scalar.py --algorithm msd_radix_string_sorter
python3 benchmarks/verify_i64_array_scalar.py --algorithm msd_radix_string_sorter
```

## Implementations

| Language | Source |
|---|---|
| C | [`c/m/msd_radix_string_sorter.c`](../../../c/m/msd_radix_string_sorter.c) |
| C3 | [`c3/m/msd_radix_string_sorter.c3`](../../../c3/m/msd_radix_string_sorter.c3) |
| C++ | [`cpp/m/msd_radix_string_sorter.cpp`](../../../cpp/m/msd_radix_string_sorter.cpp) |
| Elisa | [`elisa/m/msd_radix_string_sorter.elisa`](../../../elisa/m/msd_radix_string_sorter.elisa) |
| Nim | [`nim/m/msd_radix_string_sorter.nim`](../../../nim/m/msd_radix_string_sorter.nim) |
| Odin | [`odin/m/msd_radix_string_sorter.odin`](../../../odin/m/msd_radix_string_sorter.odin) |
| Rust | [`rust/m/msd_radix_string_sorter.rs`](../../../rust/m/msd_radix_string_sorter.rs) |
| V | [`v/m/msd_radix_string_sorter.v`](../../../v/m/msd_radix_string_sorter.v) |
| Zig | [`zig/m/msd_radix_string_sorter.zig`](../../../zig/m/msd_radix_string_sorter.zig) |
