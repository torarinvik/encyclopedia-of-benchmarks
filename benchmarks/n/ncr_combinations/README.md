# Generalized n-choose-r combinations

## Contract

Compute the generalized combination for a real-valued total and integer-valued choose:

`total * (total - 1) * ... * (total - choose + 1) / choose!`.

The ABI is `float64_pair(total, choose)`. Both inputs must be finite; `total` is in `[0, 20]`, and `choose` must be an exact integer-valued binary64 number in `[0, 12]`. For `choose = 0`, return `1.0`. Invalid inputs return `-1e300`.

Fractional totals and values where `choose` exceeds `total` are valid within these bounds. The result can be negative for some such inputs, which is why the invalid sentinel is far outside the result range. The calculation follows the pinned source order: multiply each falling factor into a binary64 numerator, compute `choose!`, then divide once. Runtime is O(choose) and additional space is O(1).

This package is distinct from [`combinations`](../c/combinations/README.md), which counts integer subsets and returns an integer for `0 <= k <= n`.

## Workload

[`workload.json`](workload.json) includes integer and fractional totals, zero choose, fractional totals with choose greater than total, and invalid domains. Build and run with the shared `float64_pair` ABI:

```sh
python3 benchmarks/build_abi.py --family float64_pair --algorithm ncr_combinations --language rust
python3 benchmarks/run_float64_pair.py --build-manifest build/float64_pair/n/ncr_combinations/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/n/ncr_combinations.c`](../../../c/n/ncr_combinations.c) |
| C3 | [`c3/n/ncr_combinations.c3`](../../../c3/n/ncr_combinations.c3) |
| C++ | [`cpp/n/ncr_combinations.cpp`](../../../cpp/n/ncr_combinations.cpp) |
| Elisa | [`elisa/n/ncr_combinations.elisa`](../../../elisa/n/ncr_combinations.elisa) |
| Nim | [`nim/n/ncr_combinations.nim`](../../../nim/n/ncr_combinations.nim) |
| Odin | [`odin/n/ncr_combinations.odin`](../../../odin/n/ncr_combinations.odin) |
| Rust | [`rust/n/ncr_combinations.rs`](../../../rust/n/ncr_combinations.rs) |
| V | [`v/n/ncr_combinations.v`](../../../v/n/ncr_combinations.v) |
| Zig | [`zig/n/ncr_combinations.zig`](../../../zig/n/ncr_combinations.zig) |

## TheAlgorithms reference

- [Python `ncr_combinations.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/ncr_combinations.py)
