# Single number by XOR

Return the value that occurs once when every other value occurs twice. The selected method XORs the signed 32-bit values after mapping them to nonnegative 32-bit bit patterns.

## Contract

- Input is a signed 64-bit array containing 1 through 257 values.
- Each value must fit a signed 32-bit integer.
- For the named problem, exactly one value occurs once and every other value occurs twice. For any bounded input array, the operation is defined as its XOR reduction.
- The result is interpreted as a signed 32-bit value and returned as a signed 64-bit scalar.
- Empty, oversized, or out-of-range inputs return `-2147483649`, which is outside the valid value range.

The implementation uses portable integer XOR operations and no machine-specific instructions.

## Workload and verification

[`workload.json`](workload.json) covers the standard examples, repeated positive and negative values, zero, signed 32-bit boundaries, maximum array length, and invalid inputs. [`verify_single_number.py`](../../verify_single_number.py) checks the nine ports against an independent 32-bit bit-vector oracle, exhausts short arrays over a small signed alphabet, and adds deterministic random and boundary arrays.

```sh
python3 benchmarks/verify_single_number.py --elisa-compiler /absolute/path/to/elisac
```

Build and record with the `i64_array_scalar` ABI family. Sources are under `s/` in `c/`, `c3/`, `cpp/`, `elisa/`, `nim/`, `odin/`, `rust/`, `v/`, and `zig/`.

## Reviewed TheAlgorithms sources

- [C LeetCode `136.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/136.c) uses XOR to cancel paired values.
- [Ruby `single_number.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/arrays/single_number.rb) includes a frequency-map solution and an O(n²) counting solution. This benchmark selects the XOR method from the C source and ports it to all nine target languages.
