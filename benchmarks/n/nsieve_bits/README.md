# Benchmark Game `nsieve-bits`

This package ports the classic packed-bit prime sieve, preserving the upstream three-pass workload while replacing its fixed large input with a bounded parameter.

## Contract

- The `i64_array_bytes_output` input is `[limit]`, with `limit` from 0 through 1,000,000.
- Run three independent sieve passes at inclusive limits `limit`, `limit >> 1`, and `limit >> 2`.
- Each pass starts with all candidate bits set, scans values from 2 upward, counts each still-set value, and flips its still-set multiples beginning at twice that value.
- Return the three counts in pass order as little-endian unsigned 64-bit integers (24 bytes total). Invalid input returns `-1`; a null output buffer or capacity below 24 returns `-2` without writing.
- The bounded input keeps memory and runtime practical while retaining the bit-packed algorithm and three passes from the source.

## Source

Pinned upstream: [Benchmark Game `nsieve-bits.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BenchmarkGame/nsieve-bits/nsieve-bits.c), contributed by Mike Pall. The referenced file has no explicit license notice; these are independently written algorithm ports.

[`workload.json`](workload.json) covers empty and small sieve limits, three-pass outputs, invalid bounds and framing, and output errors. `benchmarks/nsieve_bits_oracle.py` supplies the byte-output oracle. All nine ports use the existing `i64_array_bytes_output` ABI.

| Language | Source |
| --- | --- |
| C | [`c/n/nsieve_bits.c`](../../../c/n/nsieve_bits.c) |
| C3 | [`c3/n/nsieve_bits.c3`](../../../c3/n/nsieve_bits.c3) |
| C++ | [`cpp/n/nsieve_bits.cpp`](../../../cpp/n/nsieve_bits.cpp) |
| Elisa | [`elisa/n/nsieve_bits.elisa`](../../../elisa/n/nsieve_bits.elisa) |
| Nim | [`nim/n/nsieve_bits.nim`](../../../nim/n/nsieve_bits.nim) |
| Odin | [`odin/n/nsieve_bits.odin`](../../../odin/n/nsieve_bits.odin) |
| Rust | [`rust/n/nsieve_bits.rs`](../../../rust/n/nsieve_bits.rs) |
| V | [`v/n/nsieve_bits.v`](../../../v/n/nsieve_bits.v) |
| Zig | [`zig/n/nsieve_bits.zig`](../../../zig/n/nsieve_bits.zig) |

Build and run one implementation with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm benchmarkgame_nsieve_bits --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm benchmarkgame_nsieve_bits
```
