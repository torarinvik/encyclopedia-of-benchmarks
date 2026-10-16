# Sum of divisors

Return the sum of every positive divisor of `n`, including `n` itself. For example, `sum_of_divisors(100)` is `217`.

## Contract

- Input is one signed 64-bit integer in `1..=1,000,000`.
- Return the exact sum of the positive divisors. Values outside the range return `-1`.
- The ports factor the input and multiply the geometric sum for each prime power, including the final prime factor when one remains. This uses only portable integer arithmetic.

The pinned Python routine uses trial division and geometric sums, but omits any prime factor left after the loop. For example, it returns `1` for `13` instead of `14`, and misses the factor `3` in `12`. The shared benchmark implements the conventional divisor-sum algorithm and records this source defect rather than propagating it.

## Workload and verification

[`workload.json`](workload.json) includes primes and composites with residual factors, prime powers, perfect squares, and the input bounds. Run `python3 benchmarks/verify_scalar.py --algorithms sum_of_divisors --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` to compare all nine ports against an independent divisor-pair oracle.

## Pinned source

- TheAlgorithms/Python [`basic_maths.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/basic_maths.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/sum_of_divisors.c`](../../../c/s/sum_of_divisors.c) |
| C3 | [`c3/s/sum_of_divisors.c3`](../../../c3/s/sum_of_divisors.c3) |
| C++ | [`cpp/s/sum_of_divisors.cpp`](../../../cpp/s/sum_of_divisors.cpp) |
| Elisa | [`elisa/s/sum_of_divisors.elisa`](../../../elisa/s/sum_of_divisors.elisa) |
| Nim | [`nim/s/sum_of_divisors.nim`](../../../nim/s/sum_of_divisors.nim) |
| Odin | [`odin/s/sum_of_divisors.odin`](../../../odin/s/sum_of_divisors.odin) |
| Rust | [`rust/s/sum_of_divisors.rs`](../../../rust/s/sum_of_divisors.rs) |
| V | [`v/s/sum_of_divisors.v`](../../../v/s/sum_of_divisors.v) |
| Zig | [`zig/s/sum_of_divisors.zig`](../../../zig/s/sum_of_divisors.zig) |
