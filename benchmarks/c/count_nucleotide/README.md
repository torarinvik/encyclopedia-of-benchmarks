# Count nucleotide

This package ports the pinned Julia `count_nucleotides` routine, which counts uppercase `A`, `C`, `G`, and `T` characters and returns all four counts in order as a space-separated string.

## Contract

- Input is `[codepoint_count, ASCII_codepoints...]`. The sequence has 0 through 1,000 codepoints, each encoded as an integer from 0 through 127. Restricting the Julia Unicode string to ASCII keeps the packed input portable.
- Only uppercase `A`, `C`, `G`, and `T` are counted; every other ASCII character, including lowercase bases and `N`, is ignored as in the source.
- Output is the ASCII string `A_count C_count G_count T_count` with no trailing newline. Since the four counts sum to at most 1,000, the longest formatting is `250 250 250 250` at 15 bytes. Malformed shapes or out-of-range codepoints return `-1`; insufficient or null output capacity returns `-2` without writing.

## Workload and verification

[`workload.json`](workload.json) covers balanced, single-base, empty, mixed-case, unknown-only, and maximum-length sequences, malformed input, and insufficient output capacity.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm count_nucleotide --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/c/count_nucleotide/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm count_nucleotide
```

## Pinned source

- Julia [`count_nucleotide.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/project_rosalind/count_nucleotide.jl)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/count_nucleotide.c`](../../../c/c/count_nucleotide.c) |
| C3 | [`c3/c/count_nucleotide.c3`](../../../c3/c/count_nucleotide.c3) |
| C++ | [`cpp/c/count_nucleotide.cpp`](../../../cpp/c/count_nucleotide.cpp) |
| Elisa | [`elisa/c/count_nucleotide.elisa`](../../../elisa/c/count_nucleotide.elisa) |
| Nim | [`nim/c/count_nucleotide.nim`](../../../nim/c/count_nucleotide.nim) |
| Odin | [`odin/c/count_nucleotide.odin`](../../../odin/c/count_nucleotide.odin) |
| Rust | [`rust/c/count_nucleotide.rs`](../../../rust/c/count_nucleotide.rs) |
| V | [`v/c/count_nucleotide.v`](../../../v/c/count_nucleotide.v) |
| Zig | [`zig/c/count_nucleotide.zig`](../../../zig/c/count_nucleotide.zig) |
