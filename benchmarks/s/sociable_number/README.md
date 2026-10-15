# Sociable number cycle

This benchmark checks whether repeated sums of proper divisors return to the
starting number at an exact requested cycle length.

## Contract

- Inputs use the `binary_scalar` ABI: a nonnegative number and a cycle length.
- The number must be in `1..=100,000`; the cycle length must be 2 or 3.
- The function returns `1` if the proper-divisor-sum chain returns to the
  starting number on the requested final step, and `0` otherwise.
- Inputs outside those bounds return `-1`. The pinned Java method returns
  `false` for nonpositive numbers and lengths at most one; the benchmark uses
  `-1` for all inputs outside its bounded domain.

The implementation follows the Java loop exactly: after each divisor sum it
checks whether the current value has returned to the start. It then succeeds
only if that return occurred at step `cycleLength - 1`; an earlier return
immediately yields false. This exact-endpoint rule distinguishes a cycle length
from merely reaching the starting number within the limit.

The pinned source uses signed 32-bit `int` values. The bound keeps its
intermediates safe: for positive `n`, the proper-divisor sum is at most
`n * H_n`, where `H_n` is the nth harmonic number. Starting at 100,000, this
loose bound remains below 1.3 million after one step, below 19 million after
two, and below 360 million after three. Every source sum and loop input thus
fits a signed 32-bit integer.

Length two includes the amicable-number case; length three also covers longer
sociable cycles such as `12496 → 14288 → 15472 → 12496`. The benchmark’s
length parameter makes the general cycle check distinct from a fixed amicable
pair predicate.

## Pinned source

- [Java `SociableNumber.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/SociableNumber.java)

## Workload and build

[`workload.json`](workload.json) covers invalid inputs, early returns, a
two-number amicable cycle, and a three-number sociable cycle. Build and record
with:

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm sociable_number --language rust
python3 benchmarks/run_binary_scalar.py --build-manifest build/binary_scalar/s/sociable_number/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/s/sociable_number.c`](../../../c/s/sociable_number.c) |
| C3 | [`c3/s/sociable_number.c3`](../../../c3/s/sociable_number.c3) |
| C++ | [`cpp/s/sociable_number.cpp`](../../../cpp/s/sociable_number.cpp) |
| Elisa | [`elisa/s/sociable_number.elisa`](../../../elisa/s/sociable_number.elisa) |
| Nim | [`nim/s/sociable_number.nim`](../../../nim/s/sociable_number.nim) |
| Odin | [`odin/s/sociable_number.odin`](../../../odin/s/sociable_number.odin) |
| Rust | [`rust/s/sociable_number.rs`](../../../rust/s/sociable_number.rs) |
| V | [`v/s/sociable_number.v`](../../../v/s/sociable_number.v) |
| Zig | [`zig/s/sociable_number.zig`](../../../zig/s/sociable_number.zig) |
