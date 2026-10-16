# Liouville distinct-factor parity

This benchmark ports the pinned Go `LiouvilleLambda` function, which counts
distinct prime factors. For positive `n`, it returns `(-1)^ω(n)`, where `ω(n)`
is the number of distinct prime divisors.

## Contract

- Input is a signed 64-bit integer from 1 through 2,147,483,647.
- Return `+1` when the number has an even count of distinct prime divisors and
  `-1` when that count is odd. The empty factorization of 1 therefore returns
  `+1`.
- Return `-2` outside the supported range. The Go source returns an error for
  nonpositive values; this benchmark uses a separate adapter sentinel because
  both `+1` and `-1` are valid results.
- The bounded contract is shared with the related `liouville_lambda` benchmark,
  but the functions differ on repeated factors: `liouville(4) = -1` because
  there is one distinct prime divisor, while `liouville_lambda(4) = +1`
  because there are two prime factors counted with multiplicity.

The ports factor by trial division and toggle the result once for each prime
that divides the input, regardless of its exponent.

## Workload

[`workload.json`](workload.json) covers 1, primes, powers, composites with
repeated factors, the shared upper bound, and invalid inputs. The independent
oracle is [`liouville_oracle.py`](../../liouville_oracle.py).

## Pinned source

- [TheAlgorithms/Go `liouville.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/liouville.go)
- [TheAlgorithms/Go `primefactorization.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/prime/primefactorization.go)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/l/liouville.c`](../../../c/l/liouville.c) |
| C3 | [`c3/l/liouville.c3`](../../../c3/l/liouville.c3) |
| C++ | [`cpp/l/liouville.cpp`](../../../cpp/l/liouville.cpp) |
| Elisa | [`elisa/l/liouville.elisa`](../../../elisa/l/liouville.elisa) |
| Nim | [`nim/l/liouville.nim`](../../../nim/l/liouville.nim) |
| Odin | [`odin/l/liouville.odin`](../../../odin/l/liouville.odin) |
| Rust | [`rust/l/liouville.rs`](../../../rust/l/liouville.rs) |
| V | [`v/l/liouville.v`](../../../v/l/liouville.v) |
| Zig | [`zig/l/liouville.zig`](../../../zig/l/liouville.zig) |

## Build and verify

```sh
python3 benchmarks/build_scalar.py --algorithm liouville --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/l/liouville/rust/build.json
python3 benchmarks/verify_scalar.py --algorithms liouville
```
