# Nussinov RNA folding recurrence

This benchmark ports PolyBench/C's Nussinov dynamic program. It initializes each base as `(i + 1) % 4`, then fills the upper triangle in descending `i`, ascending `j`, and ascending split `k` order. Pair scores use the source rule `base_i + base_j == 3`, and adjacent bases cannot pair.

The input is `[n]`, with `1 <= n <= 128`. The upstream EXTRALARGE dataset uses `n=5500`; this suite caps `n` at 128 to keep the cubic recurrence bounded. The scalar result is the sum of all upper-triangle DP cells, matching the source's complete table live-out in a compact scalar form. Invalid input returns `-1`.

The Python source-order oracle is [`benchmarks/nussinov_oracle.py`](../../nussinov_oracle.py). The pinned source is [`PolyBench/medley/nussinov/nussinov.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/medley/nussinov/nussinov.c).

Build a language implementation with the `i64_array_scalar` ABI family, for example:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm nussinov --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/n/nussinov/rust/build.json
```
