# Kth factor

Returns the kth positive divisor of an integer, in ascending order, using a linear scan.

## Contract

- Uses the two-argument signed 64-bit scalar ABI with inputs `(n, k)`.
- Valid algorithm inputs have `1 <= n <= 10,000` and `1 <= k <= n`. The bound preserves the pinned Rust source's positive `i32` domain and keeps the linear scan bounded.
- The implementation scans each `i` from 1 through `n`, counts values where `n % i == 0`, and returns the divisor when that count reaches `k`.
- If `k` exceeds the number of factors, return `-1`, matching the source. Invalid ABI arguments also map to `-1`; this benchmark mapping avoids the source's unsigned-index underflow/panic for nonpositive `k` and excludes nonpositive `n`.

## Source semantics

This follows pinned [TheAlgorithms Rust `kth_factor.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a939ec5163648458a8c2b46fd4c/src/number_theory/kth_factor.rs). It scans `1..=n` in ascending order, pushes each divisor into a vector, and after each scan step returns the entry at zero-based index `k - 1` as soon as it exists. If the scan ends first, it returns `-1`. The ports return the current divisor when the number of divisors reaches `k`, which is equivalent to that indexed lookup for the same ascending scan.

## Workload and build

[`workload.json`](workload.json) covers unit values, prime and composite inputs, available and unavailable factor ranks, and invalid ABI inputs.

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm kth_factor --language rust
python3 benchmarks/run_binary_scalar.py --build-manifest build/binary_scalar/k/kth_factor/rust/build.json
```

The implementations are in `c/k/kth_factor.c`, `c3/k/kth_factor.c3`, `cpp/k/kth_factor.cpp`, `elisa/k/kth_factor.elisa`, `nim/k/kth_factor.nim`, `odin/k/kth_factor.odin`, `rust/k/kth_factor.rs`, `v/k/kth_factor.v`, and `zig/k/kth_factor.zig`.
