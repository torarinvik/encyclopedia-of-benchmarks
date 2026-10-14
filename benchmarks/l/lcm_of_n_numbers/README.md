# LCM of N numbers

This benchmark folds a sequence of nonnegative signed 64-bit integers into their least common multiple using Euclid's algorithm. It is stored under `benchmarks/l/lcm_of_n_numbers/` by the algorithm name.

## Contract

- The input is a read-only array containing values from `0` through `INT64_MAX`.
- The empty array returns `1`, the identity for the LCM fold.
- Any array containing zero returns `0`, including arrays whose nonzero prefix would overflow.
- Otherwise the function returns the exact LCM if it is at most `INT64_MAX`; it returns `-1` when the mathematical result exceeds that limit.
- The function does not modify the input array.

The ports first scan for zero, then fold each value into the accumulated result. Each pair is reduced by its GCD before multiplication, and the product is checked against the signed 64-bit limit.

TheAlgorithms/Rust lists “LCM of N Numbers” in its math directory. Its local candidate record identifies `src/math/lcm_of_n_numbers.rs` at the pinned source snapshot. The shared implementations use the explicit empty, zero, and overflow rules above so all nine languages have the same portable contract.

## Workload

`workload.json` contains 22 published cases, including empty and singleton arrays, mixed sequence lengths, zeros at different positions, large common factors, and overflow. The correctness corpus additionally includes exhaustive arrays of lengths zero through four over small integers, 512 deterministic random arrays, and signed 64-bit boundary values.

## Run

Build with the `i64_array_scalar` ABI family and record with `benchmarks/run_i64_array_scalar.py`. `benchmarks/verify_i64_array_scalar.py` compares every implementation against Python's arbitrary-precision `math.lcm` and checks all published result records.
