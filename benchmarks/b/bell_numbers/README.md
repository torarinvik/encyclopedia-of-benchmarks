# Bell numbers

## Contract

Return the Bell number `B_n`, the number of ways to partition a set of `n` elements into nonempty subsets. The scalar input is a signed 64-bit integer. Inputs from `0` through `25` return the exact value; all other inputs return `-1`. `B_0 = 1`, and `B_25 = 4,638,590,332,229,999,353` is the largest Bell number that fits in a signed 64-bit result.

The exported C ABI entry point is `int64_t bell_numbers(int64_t n)`. Ports use a rolling Bell triangle. Starting from row `[1]`, each next row begins with the previous row's last value and each following value is the sum of the new row's preceding value and the previous row's value at the preceding column. The first value of row `n` is `B_n`.

## Source review and aliases

The pinned Java source computes one Bell number with Bell's triangle and rejects `n > 25`; the Rust source computes one value with memoized binomial recurrence and arbitrary-precision output; the Python source returns all values from `B_0` through `B_n` using the same binomial recurrence. This benchmark selects the shared scalar result over the common exact domain `0..25`. Bell numbers count unrestricted set partitions, so they remain distinct from Catalan numbers and the other existing sequence benchmarks.

## Workload and verification

[`workload.json`](workload.json) covers initial values, the upper exact boundary, out-of-range indices, and both signed 64-bit boundaries. [`verify_scalar.py`](../../verify_scalar.py) checks a dense range around the supported interval against an independent Stirling-number recurrence and records every workload case for all nine language ports.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/bell_numbers.c`](../../../c/b/bell_numbers.c) |
| C3 | [`c3/b/bell_numbers.c3`](../../../c3/b/bell_numbers.c3) |
| C++ | [`cpp/b/bell_numbers.cpp`](../../../cpp/b/bell_numbers.cpp) |
| Elisa | [`elisa/b/bell_numbers.elisa`](../../../elisa/b/bell_numbers.elisa) |
| Nim | [`nim/b/bell_numbers.nim`](../../../nim/b/bell_numbers.nim) |
| Odin | [`odin/b/bell_numbers.odin`](../../../odin/b/bell_numbers.odin) |
| Rust | [`rust/b/bell_numbers.rs`](../../../rust/b/bell_numbers.rs) |
| V | [`v/b/bell_numbers.v`](../../../v/b/bell_numbers.v) |
| Zig | [`zig/b/bell_numbers.zig`](../../../zig/b/bell_numbers.zig) |

## TheAlgorithms references

- Java [`BellNumbers.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/BellNumbers.java)
- Python [`bell_numbers.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/special_numbers/bell_numbers.py)
- Rust [`bell_numbers.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/bell_numbers.rs)
