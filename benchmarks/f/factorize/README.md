# Factorize

Factorize an integer into prime powers. The pinned Lua function returns a table mapping each factor to its multiplicity. The benchmark serializes that mapping as ascending `(factor, exponent)` pairs, each value encoded as a little-endian unsigned 32-bit integer.

## Contract

- Input is a signed 64-bit integer from 0 through 1,000,005.
- For inputs greater than 1, return the distinct prime factors in ascending order with their positive exponents.
- Preserve the Lua source's edge results: `0` returns the pair `(0, 1)` and `1` returns `(1, 1)`.
- Return `-1` outside the supported input range.
- Return `-2` when the output buffer is too small; do not write to it in that case.
- Return the encoded output length on success. The supported range produces at most seven pairs (56 bytes).

The nine ports use integer trial division with an exact `divisor <= remaining / divisor` bound. They need only standard integer operations and do not rely on CPU-specific instructions or floating-point square roots.

## Workload and verification

[`workload.json`](workload.json) includes the source's `0` and `1` results, primes, prime powers, a mixed composite, the upper bound, invalid signed values, and an insufficient-capacity case. The independent verifier checks all values from 0 through 4,096, deterministic valid values through the upper bound, signed boundaries, the workload, and short output buffers:

```sh
python3 benchmarks/verify_factorize.py
```

## Upstream source

- [TheAlgorithms/Lua `factorize.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/math/factorize.lua)

The pinned Lua implementation computes trial factors through `n ^ 0.5`. For the bounded integer domain, the integer-division loop in these ports preserves its positive-input factor pairs exactly while making the behavior portable and explicit.
