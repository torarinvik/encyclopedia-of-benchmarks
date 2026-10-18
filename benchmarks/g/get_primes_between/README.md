# Primes between prime endpoints

Return the prime numbers strictly between two prime endpoints, following the
pinned Python `primelib` implementation.

## Contract

- Input is exactly two signed 64-bit integers `[p1, p2]`.
- Both endpoints must be prime and in `2..=997`, with `p1 < p2`.
- At least one prime must lie strictly between the endpoints. The source's
  final assertion indexes the first and last returned values, so adjacent
  prime endpoints raise `IndexError`; the bounded ABI maps that source error to
  `-1`.
- Return the interior primes in ascending order as comma-separated ASCII
  decimal bytes, with no spaces or trailing comma. The return value is the
  number of bytes written.
- Invalid input returns `-1` before output-buffer checks. A null output pointer
  or insufficient capacity returns `-2` without writing output.
- Endpoints above 997 are outside the workload bound. Output is capped at
  1,024 bytes, more than enough for all accepted endpoint pairs.

The source verifies the endpoints with `is_prime`, scans candidates upward from
`p1 + 1`, and appends primes until `p2`. The endpoint bound keeps that scan
small and makes the largest valid result deterministic and bounded.
The ports preserve that scan order and use trial division for each candidate.

## Workload and oracle

[`workload.json`](workload.json) covers a single interior prime, the source's
`(3, 67)` example, endpoints near the upper bound, invalid and adjacent
endpoints, malformed array lengths, null output, and insufficient capacity.
The independent [`get_primes_between_oracle.py`](../../get_primes_between_oracle.py)
uses a separate bounded primality scan and encodes the returned list.

The ABI uses the `i64_array_bytes_output` family. Its function signature is:

```c
int64_t get_primes_between(const int64_t *input, size_t input_length,
                           uint8_t *output, size_t output_capacity);
```

## Build and record

Build a selected port with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm get_primes_between --language c
```

Record the published workload with:

```sh
python3 benchmarks/run_i64_array_bytes_output.py --algorithm get_primes_between
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/get_primes_between.c`](../../../c/g/get_primes_between.c) |
| C3 | [`c3/g/get_primes_between.c3`](../../../c3/g/get_primes_between.c3) |
| C++ | [`cpp/g/get_primes_between.cpp`](../../../cpp/g/get_primes_between.cpp) |
| Elisa | [`elisa/g/get_primes_between.elisa`](../../../elisa/g/get_primes_between.elisa) |
| Nim | [`nim/g/get_primes_between.nim`](../../../nim/g/get_primes_between.nim) |
| Odin | [`odin/g/get_primes_between.odin`](../../../odin/g/get_primes_between.odin) |
| Rust | [`rust/g/get_primes_between.rs`](../../../rust/g/get_primes_between.rs) |
| V | [`v/g/get_primes_between.v`](../../../v/g/get_primes_between.v) |
| Zig | [`zig/g/get_primes_between.zig`](../../../zig/g/get_primes_between.zig) |

## Pinned source

- [Python `primelib.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/primelib.py), especially `get_primes_between` and `is_prime`.
