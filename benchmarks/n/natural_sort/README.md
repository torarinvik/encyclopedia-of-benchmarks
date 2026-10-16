# Natural sort

Sort ASCII identifiers using the pinned Python natural-sort key: case-insensitive text chunks and numeric interpretation of digit runs. This bounded contract accepts empty strings or a letter prefix followed by an optional digit suffix, which preserves the numeric-suffix behavior without Python mixed-type key comparisons. Equal normalized keys retain input order. Output strings are separated by newline bytes.

## Contract

- The `i64_array_bytes_output` input is `[count, len0, chars0..., len1, chars1..., ...]`. Count is 0 through 64; each string is 0 through 64 ASCII characters.
- A nonempty string has an ASCII letter prefix and may have one digit suffix. Empty strings are allowed.
- Sort by the lowercase prefix, then by the integer value of the suffix. A missing suffix sorts before a present suffix with the same prefix. Numeric suffixes with equal values, including leading-zero variants, remain stable.
- The result is the sorted strings joined with newline. Invalid input returns -1; insufficient capacity returns -2.

[`workload.json`](workload.json) covers the upstream example, numeric ordering, case folding, leading zeros, stable equal keys, empty strings, and limits.

## Implementations

- C: [`c/n/natural_sort.c`](../../../c/n/natural_sort.c)
- C3: [`c3/n/natural_sort.c3`](../../../c3/n/natural_sort.c3)
- C++: [`cpp/n/natural_sort.cpp`](../../../cpp/n/natural_sort.cpp)
- Elisa: [`elisa/n/natural_sort.elisa`](../../../elisa/n/natural_sort.elisa)
- Nim: [`nim/n/natural_sort.nim`](../../../nim/n/natural_sort.nim)
- Odin: [`odin/n/natural_sort.odin`](../../../odin/n/natural_sort.odin)
- Rust: [`rust/n/natural_sort.rs`](../../../rust/n/natural_sort.rs)
- V: [`v/n/natural_sort.v`](../../../v/n/natural_sort.v)
- Zig: [`zig/n/natural_sort.zig`](../../../zig/n/natural_sort.zig)

The implementation follows the pinned [TheAlgorithms/Python natural_sort](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/natural_sort.py), which splits digit runs and compares them numerically.
