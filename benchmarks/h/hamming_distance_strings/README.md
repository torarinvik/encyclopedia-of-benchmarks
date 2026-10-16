# Hamming Distance Between Strings

This benchmark ports `Distance` from the pinned Go `hamming` package. The source compares string bytes at matching positions, counts unequal positions, and returns `-1` with an error when the string lengths differ. This is separate from [`hamming_distance`](../hamming_distance/README.md), which counts differing bits in two integer values.

## Contract

- The `i64_array_scalar` input is `[left_length, right_length, left_bytes..., right_bytes...]`. Each length is 0 through 128 and each byte is an integer from 0 through 255.
- The result is the number of unequal byte positions when the lengths are equal. Two empty strings have distance 0. Unequal lengths return `-1`, matching the source's error result.
- Negative or over-bound lengths, missing or extra packed bytes, and values outside the byte range return `-1`. The input parser accepts up to 260 values so the workload can exercise one-over-bound lengths.
- The source operates on Go string bytes, not Unicode code points; the packed byte representation preserves that behavior, including embedded NUL and bytes above ASCII.

## Pinned source

- Go [`hammingdistance.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/strings/hamming/hammingdistance.go), commit `5ba447ec5ff3d1213de65b92e726ee74c5d5cc19`.

## Workload and build

[`workload.json`](workload.json) covers empty and identical strings, multiple mismatches, embedded NUL, high bytes, unequal lengths, malformed layouts, the maximum valid length, and admitted packed inputs with one or both lengths one above the bound. The independent oracle is [`hamming_distance_strings_oracle.py`](../../hamming_distance_strings_oracle.py).

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm hamming_distance_strings --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/h/hamming_distance_strings/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms hamming_distance_strings
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/hamming_distance_strings.c`](../../../c/h/hamming_distance_strings.c) |
| C3 | [`c3/hamming_distance_strings.c3`](../../../c3/h/hamming_distance_strings.c3) |
| C++ | [`cpp/hamming_distance_strings.cpp`](../../../cpp/h/hamming_distance_strings.cpp) |
| Elisa | [`elisa/hamming_distance_strings.elisa`](../../../elisa/h/hamming_distance_strings.elisa) |
| Nim | [`nim/hamming_distance_strings.nim`](../../../nim/h/hamming_distance_strings.nim) |
| Odin | [`odin/hamming_distance_strings.odin`](../../../odin/h/hamming_distance_strings.odin) |
| Rust | [`rust/hamming_distance_strings.rs`](../../../rust/h/hamming_distance_strings.rs) |
| V | [`v/hamming_distance_strings.v`](../../../v/h/hamming_distance_strings.v) |
| Zig | [`zig/hamming_distance_strings.zig`](../../../zig/h/hamming_distance_strings.zig) |
