# Baby-step giant-step discrete logarithm

This benchmark solves `a^x ≡ b (mod n)` with the baby-step giant-step method from the pinned Rust source. It stores the source's baby-step residues, then scans giant steps in increasing order.

## Contract

- Input is a three-element signed 64-bit array `[a, b, n]`.
- Require `1 <= n <= 1,000,000,007` and `0 <= a,b < n`. Invalid length or values return `-1`.
- The source requires `gcd(a,n) == 1`; when this is false, return `-1`, matching its `None` result. Return `-1` when the search finds no solution.
- Otherwise return the smallest positive `x` found in the source search, in `1..=n`. For modulus one, the only supported pair is `[0, 0, 1]`, and the result is `1`.

The bound keeps each modular product below signed 64-bit range. It also bounds `ceil(sqrt(n))` to 31,623, so a 65,536-slot open-address table holds every baby step below half load. The pinned Rust source uses a `HashMap`; these ports store residue-to-exponent entries in that table. Inserting an existing residue replaces its exponent, matching `HashMap::insert` and preserving the source's choice of the largest baby-step index for a duplicate residue. Giant steps are checked in the same increasing order, so the first matching result preserves the source's smallest-exponent search behavior.

The source computes `m = ceil(sqrt(n))`, inserts `(a^j * b) mod n` for each `j` with `0 <= j < m`, then checks `a^(m*k) mod n` for successive multiples `m*k <= n`. The shared contract restricts `a` and `b` to canonical residues; the source accepts wider `usize` values and reduces them modulo `n` during the first multiplication.

## Workload

[`workload.json`](workload.json) includes the pinned examples, large source examples within the safe multiplication bound, modulus one, non-coprime bases, no-solution inputs, and malformed or out-of-range values. It uses the existing `i64_array_scalar` ABI with packed input `[a, b, n]`.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm baby_step_giant_step --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/b/baby_step_giant_step/rust/build.json
```

## Pinned source

- [TheAlgorithms/Rust `baby_step_giant_step.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/baby_step_giant_step.rs)

## Implementations

The nine ports are in the language folders under `b/baby_step_giant_step` and use the shared array-scalar ABI.
