# Two non-repeating elements

## Contract

Given an even-length array of signed 32-bit values, find the two values that occur once when every other value occurs exactly twice. This package uses arrays of length `2..64` and values in `[0, 1,073,741,823]`. The input must satisfy the stated frequency pattern and contain two distinct singleton values, as required by the source. Odd, empty, oversized, or out-of-range inputs return `-1`.

The pinned Java implementation XORs all values, isolates the lowest set bit with `xorResult & (-xorResult)`, then XORs values into two groups in input order. It returns `[num1, num2]`, where `num1` is the XOR of values with that bit set and `num2` is the XOR of the other group. The ABI returns this pair packed into one nonnegative signed 64-bit value:

`(num1 << 32) | num2`

The value cap ensures both 32-bit results remain nonnegative and the packed value fits signed 64-bit. The exported ABI is `int64_t non_repeating_element(const int64_t *values, size_t length)` using `i64_array_scalar`.

## Source review and distinction

The pinned `findNonRepeatingElements` method throws for an odd-length input and otherwise returns a two-element array in low-set-bit partition order. The benchmark’s packed scalar representation preserves both values and their order. It is distinct from the existing [`single_number`](../../s/single_number/README.md) benchmark, which returns one singleton value; the cataloged `find_non_repeating_number` candidate is mapped to that same single-value benchmark.

## Workload and recording

[`workload.json`](workload.json) covers the two-element base case, zero, different low-set-bit partitions, repeated pairs, odd-length rejection, and a value outside the bounded domain. The verifier checks an independent frequency-map oracle that reconstructs the source's ordered pair from the two singletons.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm non_repeating_element --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/n/non_repeating_element/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms non_repeating_element --languages rust
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/n/non_repeating_element.c`](../../../c/n/non_repeating_element.c) |
| C3 | [`c3/n/non_repeating_element.c3`](../../../c3/n/non_repeating_element.c3) |
| C++ | [`cpp/n/non_repeating_element.cpp`](../../../cpp/n/non_repeating_element.cpp) |
| Elisa | [`elisa/n/non_repeating_element.elisa`](../../../elisa/n/non_repeating_element.elisa) |
| Nim | [`nim/n/non_repeating_element.nim`](../../../nim/n/non_repeating_element.nim) |
| Odin | [`odin/n/non_repeating_element.odin`](../../../odin/n/non_repeating_element.odin) |
| Rust | [`rust/n/non_repeating_element.rs`](../../../rust/n/non_repeating_element.rs) |
| V | [`v/n/non_repeating_element.v`](../../../v/n/non_repeating_element.v) |
| Zig | [`zig/n/non_repeating_element.zig`](../../../zig/n/non_repeating_element.zig) |

## TheAlgorithms reference

- Java [`NonRepeatingElement.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/NonRepeatingElement.java)
