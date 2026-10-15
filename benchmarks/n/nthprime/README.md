# Nth prime

This benchmark returns the prime at a one-based index using the pinned Rust
source's expanding sieve.

## Contract

- The unary scalar input `n` is in `1..=100`.
- Return the `n`th prime, so `n=1` returns 2.
- Inputs outside this bound return `-1`. In particular, `n=0` reaches the
  pinned source's `None.unwrap()` and panics; the benchmark maps it to `-1`.
- The 100-term bound is a workload limit. All results fit the signed 64-bit
  scalar ABI, and the source's sieve stays below 1,600 entries for this range.

The source starts with a sieve length of `2*n`, then increases that length by
`n` each pass until the sieve contains at least `n` primes. Each sieve begins
with all flags set, clears composite multiples beginning at each prime's
square, sums the flags from index 2 onward, then scans those flags and returns
the index where the count reaches `n`. This preserves both the expanding-sieve
strategy and the source's one-based prime indexing. It differs from
[`next_prime_number`](../next_prime_number/README.md), which searches forward
from a numeric starting value.

## Pinned source

- [Rust `nthprime.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/nthprime.rs)

## Workload and build

[`workload.json`](workload.json) uses the unary `scalar` ABI and covers the
first terms, a small prime index, the largest supported index, and invalid
indices. Build and record with:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm nthprime --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/n/nthprime/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/n/nthprime.c`](../../../c/n/nthprime.c) |
| C3 | [`c3/n/nthprime.c3`](../../../c3/n/nthprime.c3) |
| C++ | [`cpp/n/nthprime.cpp`](../../../cpp/n/nthprime.cpp) |
| Elisa | [`elisa/n/nthprime.elisa`](../../../elisa/n/nthprime.elisa) |
| Nim | [`nim/n/nthprime.nim`](../../../nim/n/nthprime.nim) |
| Odin | [`odin/n/nthprime.odin`](../../../odin/n/nthprime.odin) |
| Rust | [`rust/n/nthprime.rs`](../../../rust/n/nthprime.rs) |
| V | [`v/n/nthprime.v`](../../../v/n/nthprime.v) |
| Zig | [`zig/n/nthprime.zig`](../../../zig/n/nthprime.zig) |
