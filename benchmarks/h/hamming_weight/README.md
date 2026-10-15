# Hamming Weight

## Contract

Count the set bits in an unsigned 32-bit integer. The C ABI accepts the value as a signed 64-bit integer: inputs from `0` through `4294967295` return a count from 0 through 32, and other inputs return `-1`.

The exported C ABI entry point is:

```c
int64_t hamming_weight(int64_t value);
```

The local implementations scan all 32 bit positions. This matches the C LeetCode 191 contract and the shared unsigned 32-bit domain of the C++ and JavaScript references. Java's `CountSetBits` instead totals set bits over every integer from 1 through N, so it is a different algorithm.

## Workload and measurement

[`workload.json`](workload.json) covers zero, single bits, alternating bit patterns, the high bit, the maximum value, and out-of-range values. The C11 scalar runner checks expected results before timing, runs two warmup batches, then records seven samples of 10,000 calls each. Input parsing, correctness checks, and JSON writing happen outside the timed interval.

[`benchmarks/build_scalar.py`](../../build_scalar.py) provides the standalone build recipe for all nine languages. [`benchmarks/verify_scalar.py`](../../verify_scalar.py) checks the workload plus an exhaustive range, deterministic random unsigned values, each bit position and its neighbors, and signed-width boundaries. The verification report records the host and source hashes; it does not claim that every platform has been tested.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/h/hamming_weight.c`](../../../c/h/hamming_weight.c) | Local port; C LeetCode reference below |
| C3 | [`c3/h/hamming_weight.c3`](../../../c3/h/hamming_weight.c3) | Local port |
| C++ | [`cpp/h/hamming_weight.cpp`](../../../cpp/h/hamming_weight.cpp) | Local port; C++ reference below |
| Elisa | [`elisa/h/hamming_weight.elisa`](../../../elisa/h/hamming_weight.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/h/hamming_weight.nim`](../../../nim/h/hamming_weight.nim) | Local port |
| Odin | [`odin/h/hamming_weight.odin`](../../../odin/h/hamming_weight.odin) | Local port |
| Rust | [`rust/h/hamming_weight.rs`](../../../rust/h/hamming_weight.rs) | Local port |
| V | [`v/h/hamming_weight.v`](../../../v/h/hamming_weight.v) | Local port |
| Zig | [`zig/h/hamming_weight.zig`](../../../zig/h/hamming_weight.zig) | Local port |

## TheAlgorithms references

- [C LeetCode 191 `hammingWeight`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/191.c)
- [C++ `count_of_set_bits`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2849e8d1a8d926e171cc5b39f97759/bit_manipulation/count_of_set_bits.cpp)
- [JavaScript `BinaryCountSetBits`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Bit-Manipulation/BinaryCountSetBits.js)
