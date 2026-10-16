# Numeric string sort

Sort nonnegative decimal strings by their numeric value without parsing them into fixed-width integers. This follows the pinned C++ `NumericSort` comparator: strip leading zeroes, compare the remaining digit counts, then compare equal-length digit strings lexicographically.

## Contract

- Input is a packed signed-i64 array `[count, length_1, ASCII digits..., ...]`. There are 0 through 64 tokens, and each token contains 1 through 32 ASCII decimal digits.
- Original token spelling is preserved in the output. The tokens are joined with one ASCII space, without a trailing space or NUL byte.
- Leading zeroes are supported. Different spellings that normalize to the same digit sequence are rejected because the source comparator treats them as equivalent and `std::sort` does not define their relative order. Repeated identical tokens are allowed.
- Malformed counts, lengths, bytes, or trailing values return `-1`. Insufficient output capacity or a null output pointer for nonempty output returns `-2`. Empty input data (`count = 0`) succeeds with zero output bytes.
- The maximum valid packed input is 2,113 values. One extra value is admitted by the parser to check the first rejected size. The output workspace holds at most 2,111 bytes.

The benchmark isolates the numeric comparator and sorted collection result from the pinned command-line prompts and explanatory output. C++ and C++-1 pinned source files are identical.

## Workload and oracle

[`workload.json`](workload.json) covers the source example, leading zeroes, duplicates, large decimal tokens, the maximum packed input/output, malformed layouts and bytes, ambiguous ties, and capacity boundaries. The independent oracle compares normalized digit strings without integer conversion: [`numeric_string_sort_oracle.py`](../../numeric_string_sort_oracle.py).

Pinned sources: [TheAlgorithms/C-Plus-Plus `numeric_string_sort.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/sorting/numeric_string_sort.cpp), [TheAlgorithms/C-Plus-Plus-1 copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/sorting/numeric_string_sort.cpp).

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm numeric_string_sort --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm numeric_string_sort
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm numeric_string_sort
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/n/numeric_string_sort.c`](../../../c/n/numeric_string_sort.c) |
| C3 | [`c3/n/numeric_string_sort.c3`](../../../c3/n/numeric_string_sort.c3) |
| C++ | [`cpp/n/numeric_string_sort.cpp`](../../../cpp/n/numeric_string_sort.cpp) |
| Elisa | [`elisa/n/numeric_string_sort.elisa`](../../../elisa/n/numeric_string_sort.elisa) |
| Nim | [`nim/n/numeric_string_sort.nim`](../../../nim/n/numeric_string_sort.nim) |
| Odin | [`odin/n/numeric_string_sort.odin`](../../../odin/n/numeric_string_sort.odin) |
| Rust | [`rust/n/numeric_string_sort.rs`](../../../rust/n/numeric_string_sort.rs) |
| V | [`v/n/numeric_string_sort.v`](../../../v/n/numeric_string_sort.v) |
| Zig | [`zig/n/numeric_string_sort.zig`](../../../zig/n/numeric_string_sort.zig) |
