# Dual-number automatic differentiation

Evaluate the value or an nth derivative of `f(x) = x^p` at a position using dual-number coefficients. The pinned Python source initializes a first-order dual number, repeatedly multiplies it to form the requested power, and extracts the coefficient for the requested derivative order before multiplying by the order factorial.

## Contract

- The `float64_triple` input is `[position, power, derivative_order]`.
- `position` is in `[-1, 1]`; `power` is an integer in `[0, 8]`; `derivative_order` is an integer in `[0, power]`.
- The result is the value of `x^power` when the order is zero, or its derivative of the requested order. Invalid inputs return `-1e300`.
- The implementations repeatedly multiply a truncated coefficient array representing `x + ε`. They return the requested coefficient multiplied by `derivative_order!`, matching the source's dual-number recurrence.

All nine ports use portable binary64 arithmetic. The bounded domain keeps intermediate values finite and makes input-scaled tolerance sufficient for the workload.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/d/dual_number_automatic_differentiation.c](../../../c/d/dual_number_automatic_differentiation.c) |
| C3 | [c3/d/dual_number_automatic_differentiation.c3](../../../c3/d/dual_number_automatic_differentiation.c3) |
| C++ | [cpp/d/dual_number_automatic_differentiation.cpp](../../../cpp/d/dual_number_automatic_differentiation.cpp) |
| Elisa | [elisa/d/dual_number_automatic_differentiation.elisa](../../../elisa/d/dual_number_automatic_differentiation.elisa) |
| Nim | [nim/d/dual_number_automatic_differentiation.nim](../../../nim/d/dual_number_automatic_differentiation.nim) |
| Odin | [odin/d/dual_number_automatic_differentiation.odin](../../../odin/d/dual_number_automatic_differentiation.odin) |
| Rust | [rust/d/dual_number_automatic_differentiation.rs](../../../rust/d/dual_number_automatic_differentiation.rs) |
| V | [v/d/dual_number_automatic_differentiation.v](../../../v/d/dual_number_automatic_differentiation.v) |
| Zig | [zig/d/dual_number_automatic_differentiation.zig](../../../zig/d/dual_number_automatic_differentiation.zig) |

## Pinned source

- [TheAlgorithms/Python dual-number automatic differentiation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/dual_number_automatic_differentiation.py)

The source accepts a Python callable. This benchmark supplies the bounded callable family `x ↦ x^p` so the dual arithmetic and nth-derivative extraction have a deterministic cross-language contract.

## Workload and verification

[`workload.json`](workload.json) covers derivative orders zero through eight, negative and zero positions, constant and identity functions, and invalid inputs.

```sh
python3 benchmarks/verify_float64_triple.py --algorithm dual_number_automatic_differentiation
```
