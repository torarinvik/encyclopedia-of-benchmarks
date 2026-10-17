# Shorten a vector by its suffix values

This benchmark ports the pinned R `shorten.vector(vector, by)` function. It takes the values in the final `by` positions as removal keys, then removes every matching value from the whole vector while preserving the order of the survivors. The source's zero-length indexing behavior is part of the contract: `by = 0` returns an empty vector.

## Contract

- The `i64_array_bytes_output` input is `[n, by, values...]`, with exactly `2 + n` values. `n` is 0 through 64, `by` is 0 through `n`, and each vector value is between -1,000,000 and 1,000,000. Valid inputs contain at most 66 packed values; the parser admits 67 to reject one over-bound element count.
- For `by = 0`, the source builds a zero-length negative subscript and returns an empty vector. For `1 <= by <= n`, it removes every occurrence of each value in the final `by` elements from the whole vector. Repeated suffix values do not change the removal set. Survivors keep their original order. When `by = n`, every element value is a key and the result is empty.
- The scalar return value is the number of output bytes written. The output buffer contains the surviving signed 64-bit values in little-endian order, with no count prefix. A successful empty result returns 0 and writes no bytes.
- Invalid input returns `-1`. A null output pointer or insufficient capacity returns `-2` before writing any bytes, including for a valid empty result.

The small integer range is exact in R's numeric representation. Every nonempty suffix removes at least one vector value, so the maximum output is 63 signed 64-bit values, or 504 bytes. The bounded implementation performs at most 4,096 comparisons when matching values from the suffix.

## Pinned source and workload

The source is [TheAlgorithms/R `shorten.vector.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/data_manipulation/shorten.vector.r) at commit `f65344fabeea0ae33c1ca321af709447c1a8a4c2`. In R, `c()` with no arguments is `NULL`; indexing with that zero-length subscript yields an empty vector, which explains the `by = 0` case. The official [R Language Definition, indexing vectors](https://cran.r-project.org/doc/manuals/r-release/R-lang.html#Indexing-vectors) documents that `NULL` is treated as `integer(0)` and that a zero index yields an empty vector.

[`workload.json`](workload.json) covers zero and maximum lengths, `by = 0`, `by = n`, repeated suffix keys, values repeated earlier in the vector, stable survivor order, malformed packing, and out-of-range values. The independent oracle is [`shorten_vector_oracle.py`](../../shorten_vector_oracle.py).

## Ports

| Language | Source |
| --- | --- |
| C | [`c/s/shorten_vector.c`](../../../c/s/shorten_vector.c) |
| C3 | [`c3/s/shorten_vector.c3`](../../../c3/s/shorten_vector.c3) |
| C++ | [`cpp/s/shorten_vector.cpp`](../../../cpp/s/shorten_vector.cpp) |
| Elisa | [`elisa/s/shorten_vector.elisa`](../../../elisa/s/shorten_vector.elisa) |
| Nim | [`nim/s/shorten_vector.nim`](../../../nim/s/shorten_vector.nim) |
| Odin | [`odin/s/shorten_vector.odin`](../../../odin/s/shorten_vector.odin) |
| Rust | [`rust/s/shorten_vector.rs`](../../../rust/s/shorten_vector.rs) |
| V | [`v/s/shorten_vector.v`](../../../v/s/shorten_vector.v) |
| Zig | [`zig/s/shorten_vector.zig`](../../../zig/s/shorten_vector.zig) |
