# uint53 Bitwise AND

Compute the bitwise AND of two unsigned 53-bit integers using the arithmetic loop from the pinned Lua implementation.

## Contract

- Each input is passed as a signed 64-bit integer and must be in `0..=2^53-1` (`0..=9007199254740991`), the exact nonnegative integer range of an IEEE-754 binary64 value.
- Return the bitwise AND of the two inputs. Return `-1` if either input is outside that range.
- The ports extract each least-significant bit with remainder, add the shared bit position to the result, then divide both inputs by two. They stop when either input becomes zero, as the Lua source does.

## Source

The pinned [TheAlgorithms/Lua `uint53/and.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/bit/uint53/and.lua) returns a closure that performs this arithmetic bit scan on two `uint53` values. The bounded contract rejects values that are not valid `uint53` inputs before applying the source algorithm.

## Workload and ABI

[`workload.json`](workload.json) covers zero, identical and disjoint inputs, overlapping bits, the highest representable bit, the maximum value, and invalid bounds. The exported function is `uint53_bitwise_and`; it uses the shared `binary_scalar` ABI.

Build and record with:

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm uint53_bitwise_and --language rust
python3 benchmarks/run_binary_scalar.py --build-manifest build/binary_scalar/u/uint53_bitwise_and/rust/build.json
```
