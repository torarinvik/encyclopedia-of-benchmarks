# Pell number

Computes the indexed Pell number using the iterative recurrence.

## Contract

- Uses the unary scalar ABI: `int64_t pell_number(int64_t index)`.
- Indices in `[0, 50]` are accepted. Values outside that range return `-1`.
- Returns `P(index)` for `P(0)=0`, `P(1)=1`, and `P(n)=2*P(n-1)+P(n-2)`.
- The signed 64-bit result supports all values through `P(50) = 4,866,752,642,924,153,522`; `P(51) = 11,749,380,235,262,596,085` is the first Pell number above `INT64_MAX`.

## Source semantics

The benchmark follows pinned [TheAlgorithms Python `pell_number.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/pell_number.py), specifically `pell_number_iterative`. It returns the index-th Pell number, accepts zero, and rejects negative indices. The same source also offers a recursive implementation with exponential growth; this benchmark uses the iterative version because it supports a useful bounded workload while preserving the recurrence. The shared ABI accepts signed 64-bit integers, so negative and above-bound inputs map to `-1` instead of raising Python `ValueError` or overflowing the result type.

## Workload and build

[`workload.json`](workload.json) covers base cases, representative indices, the largest valid index, and invalid signed values. Build and record with the scalar ABI:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm pell_number --language c
python3 benchmarks/run_scalar.py --build-manifest build/scalar/p/pell_number/c/build.json
```

The nine implementations are in `c/p/pell_number.c`, `c3/p/pell_number.c3`, `cpp/p/pell_number.cpp`, `elisa/p/pell_number.elisa`, `nim/p/pell_number.nim`, `odin/p/pell_number.odin`, `rust/p/pell_number.rs`, `v/p/pell_number.v`, and `zig/p/pell_number.zig`.

Verify the nine ports against the independent indexed-recurrence oracle with `python3 benchmarks/verify_scalar.py --algorithms pell_number`.
