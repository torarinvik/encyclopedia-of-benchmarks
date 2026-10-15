# Geometric series terms

Return the finite geometric series as an ordered sequence of terms. The pinned Python and Rust functions return a vector/list, rather than the scalar sum measured by [`sum_of_geometric_progression`](../../s/sum_of_geometric_progression/README.md).

## Contract

- The `i64_array_bytes_output` ABI input is exactly `[term_count, first_term, common_ratio]`.
- `term_count` is an integer from 0 through 16, `first_term` from 1 through 8, and `common_ratio` from 1 through 4.
- The output terms are `a, a*r, a*r^2, ...`, in that order, for exactly `term_count` values. Zero terms produce an empty byte string.
- Each term is encoded as an 8-byte little-endian IEEE-754 binary64 value. The largest possible term is `8 * 4^15 = 2^33`, so every output value is exactly representable in binary64.
- Invalid shape or values return `-1`; insufficient output capacity returns `-2`.

The Python source returns an empty list if any argument is zero, while the Rust source computes the sequence even when the first term or ratio is zero. The common contract therefore restricts those two values to positive integers. An integral term count also avoids the Python source's float-to-int truncation and Rust's float-to-i32 cast differences. On the supported domain, Python's recomputed powers and Rust's repeated multiplication yield the same exact integer-valued binary64 terms.

## Sources and workload

The package follows the pinned Python and Rust sequence implementations. The similarly named `sum_of_geometric_progression` package returns one scalar sum; this benchmark returns every term.

- [TheAlgorithms/Python pinned `geometric_series.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/series/geometric_series.py)
- [TheAlgorithms/Rust pinned `geometric_series.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/geometric_series.rs)

[`workload.json`](workload.json) covers zero and one term, the published example, ratio one, increasing ratios, the maximum term count, and invalid domain/shape values. All nine ports use the shared `i64_array_bytes_output` ABI.

The shared byte-output runner has a source oracle for this contract: it validates the exact three-value input, derives each term by repeated multiplication, and serializes the terms as little-endian binary64. The generic runner returns `-2` when the declared output capacity is too small.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm geometric_series --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm geometric_series
```
