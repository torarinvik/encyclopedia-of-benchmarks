# Seam carving

Find and remove one minimum-energy vertical seam from a bounded grayscale
image. The profile follows the energy map, dynamic-programming recurrence, and
row-wise seam removal described in Trekhleb's seam-carving implementation.

## Contract

- ABI: `i64_array_bytes_output`, symbol `seam_carving`.
- Input is `[width, height, pixel_0, ..., pixel_(width*height-1)]`, with pixels
  in row-major order. Width is 2 through 6, height is 1 through 6, and each
  grayscale intensity is 0 through 255. Input length must be exactly
  `2 + width * height`; at most 38 valid words are accepted.
- A grayscale intensity represents RGB `(v, v, v)`. Pixel energy uses the
  source's horizontal-neighbor RGB squared differences and square root, with
  missing left/right neighbors contributing zero. Dynamic programming sums
  those energies from top to bottom. Exactly one vertical seam is removed.
- For equal predecessor energies, the first candidate in ascending x order
  wins. For equal bottom-row totals, the leftmost endpoint wins. Both use the
  source's strict-less-than comparisons.
- Success returns `height * (width - 1)` bytes containing the resized
  row-major grayscale pixels. Invalid input returns `-1`. Null output or
  insufficient capacity returns `-2`, and errors leave the output untouched.
- The maximum output and workspace are 30 bytes. The independent oracle is
  [`seam_carving_oracle.py`](../../seam_carving_oracle.py).

The workload includes deterministic seam selection and tie cases, a maximum
image, malformed inputs, null input/output, and short/exact output capacities.

## Pinned source and license

The energy, dynamic-programming, and seam-removal procedure is adapted from
Oleksii Trekhleb's illustrative TypeScript implementation in the
[seam-carving explanation](https://github.com/trekhleb/javascript-algorithms/blob/85293e3e2b88f4d2ce330d956b139cf628aa1e82/src/algorithms/image-processing/seam-carving/README.md)
at commit `85293e3e2b88f4d2ce330d956b139cf628aa1e82`. The upstream repository
is distributed under the MIT License; its complete notice is included in
[`LICENSE.txt`](LICENSE.txt).

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm seam_carving --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm seam_carving
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm seam_carving
```

## Language ports

| Language | Source |
| --- | --- |
| C | [c/s/seam_carving.c](../../../c/s/seam_carving.c) |
| C3 | [c3/s/seam_carving.c3](../../../c3/s/seam_carving.c3) |
| C++ | [cpp/s/seam_carving.cpp](../../../cpp/s/seam_carving.cpp) |
| Elisa | [elisa/s/seam_carving.elisa](../../../elisa/s/seam_carving.elisa) |
| Nim | [nim/s/seam_carving.nim](../../../nim/s/seam_carving.nim) |
| Odin | [odin/s/seam_carving.odin](../../../odin/s/seam_carving.odin) |
| Rust | [rust/s/seam_carving.rs](../../../rust/s/seam_carving.rs) |
| V | [v/s/seam_carving.v](../../../v/s/seam_carving.v) |
| Zig | [zig/s/seam_carving.zig](../../../zig/s/seam_carving.zig) |
