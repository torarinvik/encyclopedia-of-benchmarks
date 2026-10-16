# Kelly criterion

Calculate the optimal bankroll fraction for one bet using the pinned Python `kelly_criterion` function. The package covers that primary function; its separate extended-amount and fractional-Kelly helpers remain outside this contract.

## Contract

- Input is `[win_probability_micro, win_loss_ratio_micro]` in a signed 64-bit array. Divide both inputs by 1,000,000 to obtain probability `p` and win/loss ratio `b`.
- Probability is bounded to `0.000001..0.999999`; win/loss ratio is bounded to `0.001..100`.
- The packed input must contain exactly two values. Invalid shape or values return `-1e300`.
- Preserve the source calculation order: `q = 1 - p`, then `(p * b - q) / b`. Negative Kelly fractions are returned without clamping.
- Return the binary64 fraction with absolute and relative tolerance `1e-12`. The bounded valid output lies within `[-1000, 1]`.

## Workload and oracle

[`workload.json`](workload.json) covers the source examples, positive and negative fractions, near break-even values, input bounds, and malformed inputs. The independent oracle is [`kelly_criterion_oracle.py`](../../kelly_criterion_oracle.py).

## Reviewed source

[TheAlgorithms/Python `financial/kelly_criterion.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/financial/kelly_criterion.py)

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm kelly_criterion --language rust
python3 benchmarks/run_i64_array_float64.py --algorithm kelly_criterion
python3 benchmarks/verify_i64_array_float64.py --algorithm kelly_criterion
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/k/kelly_criterion.c`](../../../c/k/kelly_criterion.c) |
| C3 | [`c3/k/kelly_criterion.c3`](../../../c3/k/kelly_criterion.c3) |
| C++ | [`cpp/k/kelly_criterion.cpp`](../../../cpp/k/kelly_criterion.cpp) |
| Elisa | [`elisa/k/kelly_criterion.elisa`](../../../elisa/k/kelly_criterion.elisa) |
| Nim | [`nim/k/kelly_criterion.nim`](../../../nim/k/kelly_criterion.nim) |
| Odin | [`odin/k/kelly_criterion.odin`](../../../odin/k/kelly_criterion.odin) |
| Rust | [`rust/k/kelly_criterion.rs`](../../../rust/k/kelly_criterion.rs) |
| V | [`v/k/kelly_criterion.v`](../../../v/k/kelly_criterion.v) |
| Zig | [`zig/k/kelly_criterion.zig`](../../../zig/k/kelly_criterion.zig) |
