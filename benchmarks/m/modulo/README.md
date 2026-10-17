# Modulo

This benchmark follows the pinned Solidity `Modulo` contract. Each invocation sets `firstNo` to `a`, sets `secondNo` to `b`, and returns `firstNo % secondNo`.

## Contract

- The packed `i64_array_scalar` input is exactly `[a, b]`.
- `a` is in `[0, 4,294,967,295]` and `b` is in `[1, 4,294,967,295]`. The bounded unsigned 32-bit domain fits the shared signed-64-bit ABI and keeps every valid remainder representable.
- A valid call returns `a % b`, in `[0, 4,294,967,294]`.
- A null input, wrong packed length, negative operand, operand above the bound, or zero divisor returns `-1`. The benchmark maps a zero divisor to `-1`; the pinned Solidity `%` operation itself reverts when the divisor is zero.
- The source contract stores operands in state, so an adapter must set both values on every invocation before calling `GetModulo`.

Source: [Solidity `Modulo`](https://github.com/TheAlgorithms/Solidity/blob/08cba51fb38e276062b0c9791d7e0ee494ffa903/src/Maths/modulo.sol).

Build and record with the `i64_array_scalar` ABI family and `benchmarks/run_i64_array_scalar.py`.
