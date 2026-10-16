# Decisions Convolutions

This benchmark ports the pinned C# `DecisionsConvolutions` decision-selection methods. It compares a set of decisions, each represented by criterion values, using either a weighted linear score or a weighted max-min score.

## Contract

- Input is `[method, decision_count, criterion_count, priorities..., row-major decision matrix...]`.
- `method=0` selects the linear convolution: maximize the sum of `criterion[i] * priority[i]` for each decision.
- `method=1` selects the max-min convolution: maximize the minimum `criterion[i] * priority[i]` across each decision's criteria.
- The result is the zero-based index of the selected decision. Ties select the first row, matching the source's `List.IndexOf` after `Max`.
- Decision count is 1–64, criterion count is 1–16, and priority and criterion values are decimal thousandths in `[-100.000, 100.000]`. The packed values store thousandths as signed integers in `[-100000,100000]`; score comparisons use exact integer products and sums.
- Malformed dimensions, methods, lengths, or out-of-range values return `-1`.

The contract uses an exact bounded decimal subset of the C# `decimal` inputs. Products are scaled by 10^6, which preserves ordering without floating-point rounding. Each output index identifies the row returned by the source method.

[`workload.json`](workload.json) covers both methods, competing criteria, negative values and priorities, ties, single-decision and single-criterion inputs, and malformed inputs. The independent oracle is [`benchmarks/decisions_convolutions_oracle.py`](../../decisions_convolutions_oracle.py).

## Pinned source

- C# [`DecisionsConvolutions.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Other/DecisionsConvolutions.cs) implements `Linear` as the maximum weighted sum and `MaxMin` as the maximum row minimum of weighted criteria. Both return the first maximum-scoring decision row.

## Build and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm decisions_convolutions --language rust
python3 benchmarks/run_i64_array_scalar.py --algorithm decisions_convolutions
```

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/d/decisions_convolutions.c`](../../../c/d/decisions_convolutions.c) |
| C3 | [`c3/d/decisions_convolutions.c3`](../../../c3/d/decisions_convolutions.c3) |
| C++ | [`cpp/d/decisions_convolutions.cpp`](../../../cpp/d/decisions_convolutions.cpp) |
| Elisa | [`elisa/d/decisions_convolutions.elisa`](../../../elisa/d/decisions_convolutions.elisa) |
| Nim | [`nim/d/decisions_convolutions.nim`](../../../nim/d/decisions_convolutions.nim) |
| Odin | [`odin/d/decisions_convolutions.odin`](../../../odin/d/decisions_convolutions.odin) |
| Rust | [`rust/d/decisions_convolutions.rs`](../../../rust/d/decisions_convolutions.rs) |
| V | [`v/d/decisions_convolutions.v`](../../../v/d/decisions_convolutions.v) |
| Zig | [`zig/d/decisions_convolutions.zig`](../../../zig/d/decisions_convolutions.zig) |
