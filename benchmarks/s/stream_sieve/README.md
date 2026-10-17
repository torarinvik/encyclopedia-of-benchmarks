# Stream Sieve

Return the first `n` primes from a shared, lazily extended prime prefix.

## Contract

- ABI: `i64_scalar_bytes_output`.
- Input is a signed 64-bit count in `[INT32_MIN, 100]`; values outside that interval return `-1`.
- For `n <= 0`, return `0` and write no bytes. This remains valid with a null output pointer or zero capacity.
- For `1 <= n <= 100`, return the first `n` primes in ascending order as little-endian signed-i32 values. Success returns `4*n` bytes; the largest prefix is 400 bytes and ends at 541.
- For positive `n`, a null output pointer or a capacity shorter than `4*n` returns `-2` without writing.
- Preserve one process-wide prime prefix across calls. Extend it only when a call requests more primes, testing new candidates with cached primes through the candidate's square root. Each call emits the requested prefix from the cache.

The pinned Scala object defines one memoized `LazyList[Int]`, beginning with 2 and filtering later candidates by trial division using the prior primes through the square root. `getPrimeNumbers(n)` takes the first `n` items from that list; nonpositive `n` therefore produces an empty sequence. The process-wide cache and incremental extension distinguish this package from [`first_n_primes`](../../f/first_n_primes/README.md), which restarts trial division for each call and emits decimal text.

## Workload

[`workload.json`](workload.json) covers nonpositive counts, representative prefixes, the 100-prime limit, insufficient capacity, and signed-i32/count boundaries. The independent [`oracle`](../../stream_sieve_oracle.py) uses a bounded sieve of Eratosthenes and encodes each prime as a little-endian signed i32.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/stream_sieve.c`](../../../c/s/stream_sieve.c) |
| C3 | [`c3/s/stream_sieve.c3`](../../../c3/s/stream_sieve.c3) |
| C++ | [`cpp/s/stream_sieve.cpp`](../../../cpp/s/stream_sieve.cpp) |
| Elisa | [`elisa/s/stream_sieve.elisa`](../../../elisa/s/stream_sieve.elisa) |
| Nim | [`nim/s/stream_sieve.nim`](../../../nim/s/stream_sieve.nim) |
| Odin | [`odin/s/stream_sieve.odin`](../../../odin/s/stream_sieve.odin) |
| Rust | [`rust/s/stream_sieve.rs`](../../../rust/s/stream_sieve.rs) |
| V | [`v/s/stream_sieve.v`](../../../v/s/stream_sieve.v) |
| Zig | [`zig/s/stream_sieve.zig`](../../../zig/s/stream_sieve.zig) |

## Pinned source

- [Scala `StreamSieve.scala` at `de555349d5effb87962d3116eb08c9f374065112`](https://github.com/TheAlgorithms/Scala/blob/de555349d5effb87962d3116eb08c9f374065112/src/main/scala/Mathematics/StreamSieve.scala)

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_scalar_bytes_output --algorithm stream_sieve --language rust
python3 benchmarks/run_i64_scalar_bytes_output.py --algorithm stream_sieve
```
