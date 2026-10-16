# Non-empty Subsequences

This benchmark ports TheAlgorithms/Go's `Start` and `Combine` routine. For a non-empty rune sequence, it prints every non-empty subsequence formed by choosing increasing input positions. It emits each prefix before recursing, so the order is include-first depth-first; repeated rune values at different positions produce repeated rows.

## Contract

- The `i64_array_bytes_output` input is `[n, rune_0, ..., rune_(n-1)]`, where `n` is 1 through 8 and the sequence contains exactly `n` Unicode scalar values (`0..0x10FFFF`, excluding surrogates).
- The output contains `2^n - 1` rows in include-first depth-first order. Each row is an unsigned 32-bit little-endian rune count followed by that many signed 32-bit little-endian Unicode scalar values. Go's `fmt.Println` line endings are normalized away into these length-prefixed rows, preserving `[]rune` sequences without depending on UTF-8 byte length.
- Empty input is invalid because the Go helper unconditionally indexes the final rune and panics for an empty sequence. Invalid packed lengths, rune counts, or scalar values return -1. A valid input with an unavailable or undersized output buffer returns -2.
- At the maximum length of 8, the output has 255 rows and 1,024 rune values, for 5,116 bytes total. The ports recurse by increasing input position and preserve duplicate positions.

This operation is distinct from [`all_subsequences`](../../a/all_subsequences/README.md), whose output includes the empty row and uses skip-first traversal. It is also distinct from `unique_subsequences_count`, which deduplicates equal strings and returns only a count.

## Pinned source

- Go [`combination.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/strings/combination/combination.go)

## Workload and build

[`workload.json`](workload.json) covers one- through eight-rune strings, include-first order, duplicate positions, Unicode scalars, the empty-input panic boundary, malformed packed lengths, invalid scalars, and bounded output size. The independent oracle is [`non_empty_subsequences_oracle.py`](../../non_empty_subsequences_oracle.py).

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm non_empty_subsequences --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/n/non_empty_subsequences/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm non_empty_subsequences
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/non_empty_subsequences.c`](../../../c/n/non_empty_subsequences.c) |
| C3 | [`c3/non_empty_subsequences.c3`](../../../c3/n/non_empty_subsequences.c3) |
| C++ | [`cpp/non_empty_subsequences.cpp`](../../../cpp/n/non_empty_subsequences.cpp) |
| Elisa | [`elisa/non_empty_subsequences.elisa`](../../../elisa/n/non_empty_subsequences.elisa) |
| Nim | [`nim/non_empty_subsequences.nim`](../../../nim/n/non_empty_subsequences.nim) |
| Odin | [`odin/non_empty_subsequences.odin`](../../../odin/n/non_empty_subsequences.odin) |
| Rust | [`rust/non_empty_subsequences.rs`](../../../rust/n/non_empty_subsequences.rs) |
| V | [`v/non_empty_subsequences.v`](../../../v/n/non_empty_subsequences.v) |
| Zig | [`zig/non_empty_subsequences.zig`](../../../zig/n/non_empty_subsequences.zig) |
