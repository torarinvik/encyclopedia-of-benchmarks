# Totients Linear Sieve

Compute and encode Euler totients `φ(1)` through `φ(n)` with the linear sieve. The benchmark uses the recurrence that assigns each composite number its least prime factor and stops extending a product as soon as that prime divides the current value.

## Contract

- Input is a signed 64-bit integer in `1..=80`; values outside the range return `-1`.
- Return `φ(1), φ(2), ..., φ(n)` as comma-separated ASCII decimal bytes, in order. The return value is the number of bytes written.
- Insufficient output capacity returns `-2`.

The pinned Python source returns the sequence using a linear sieve. Its initialization and boundary checks are imperfect for values at the start and end of the range; these ports use the conventional one-based recurrence and share explicit cases from the sequence contract.

## Workload

[`workload.json`](workload.json) uses the `i64_scalar_bytes_output_call` comparison model and includes invalid boundaries and sequence prefixes through `n = 80`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/t/totients_linear_sieve.c`](../../../c/t/totients_linear_sieve.c) |
| C3 | [`c3/t/totients_linear_sieve.c3`](../../../c3/t/totients_linear_sieve.c3) |
| C++ | [`cpp/t/totients_linear_sieve.cpp`](../../../cpp/t/totients_linear_sieve.cpp) |
| Elisa | [`elisa/t/totients_linear_sieve.elisa`](../../../elisa/t/totients_linear_sieve.elisa) |
| Nim | [`nim/t/totients_linear_sieve.nim`](../../../nim/t/totients_linear_sieve.nim) |
| Odin | [`odin/t/totients_linear_sieve.odin`](../../../odin/t/totients_linear_sieve.odin) |
| Rust | [`rust/t/totients_linear_sieve.rs`](../../../rust/t/totients_linear_sieve.rs) |
| V | [`v/t/totients_linear_sieve.v`](../../../v/t/totients_linear_sieve.v) |
| Zig | [`zig/t/totients_linear_sieve.zig`](../../../zig/t/totients_linear_sieve.zig) |

## Upstream source

[TheAlgorithms/Python `eulers_totient.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/eulers_totient.py)

Build with `python3 benchmarks/build_abi.py --family i64_scalar_bytes_output --algorithm totients_linear_sieve --language c` and record with `benchmarks/run_i64_scalar_bytes_output.py`.
