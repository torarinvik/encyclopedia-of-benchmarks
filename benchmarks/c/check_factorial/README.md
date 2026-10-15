# Check whether a number is a factorial

This benchmark checks whether an input is exactly `k!` for some nonnegative integer `k`. It returns a boolean as signed integer `1` or `0`.

## Contract

- Input is any signed 64-bit integer.
- Return `1` exactly for the factorial values `1!, 2!, ..., 20!`; `1` is also `0!`.
- Return `0` for zero, negative values, and all other nonnegative values.
- The largest signed-64-bit factorial value is `20!`; `21!` exceeds the signed 64-bit input range.
- The implementation tests factorial membership by dividing out the consecutive factors `2, 3, 4, ...` and checking whether the remainder is `1`.

The pinned C++ source accepts an unsigned 64-bit integer. This shared ABI uses signed 64-bit input so every target language has the same portable scalar interface; within that range it preserves the source predicate, and negative inputs return false. The source comment calls a factorial number a “sum of k!”; the actual code and examples implement exact factorial-value membership.

## Workload and verification

[`workload.json`](workload.json) covers `0!` and `1!`, other factorial values through `20!`, non-factorials, negatives, and the signed 64-bit boundaries. It uses the shared `scalar_call` ABI and the independent oracle in [`verify_scalar.py`](../../verify_scalar.py).

Build and run through the existing scalar workflow:

```sh
python3 benchmarks/build_scalar.py --algorithm check_factorial --language rust
python3 benchmarks/verify_scalar.py --algorithms check_factorial --languages rust
```

## Reviewed sources

- [TheAlgorithms/C-Plus-Plus `check_factorial.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/check_factorial.cpp) divides by consecutive integers and checks whether the remaining value is `1`.
- [TheAlgorithms/C-Plus-Plus-1 `check_factorial.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/check_factorial.cpp) contains the second pinned copy of the candidate.

## Implementations

The nine ports are in the language folders under `c/check_factorial` and use the shared scalar ABI.
