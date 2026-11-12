# Discrete logarithm modulo an integer

This package implements the generalized discrete logarithm by extended baby-step giant-step (EBSGS). Repeated gcd reduction handles moduli that are not coprime to the base; a baby-step giant-step search solves the remaining coprime problem.

## Contract

- Input is a three-element signed 64-bit array `[x, y, m]`.
- Require `1 <= m <= 1,000,000,000` and `0 <= x,y < m`. Invalid length or values return `-1`.
- Return the minimum integer `k >= 0` such that `x^k ≡ y (mod m)`, or `-1` if no such `k` exists. The convention is `0^0 = 1`.
- For `m = 1`, the answer is `0`, since the empty power already satisfies the congruence modulo one.

The official Library Checker problem permits `1 <= M <= 10^9`, canonical residues `0 <= X,Y < M`, and asks for the minimum nonnegative exponent, with `0^0 = 1`. Its input groups up to 100 triples; this benchmark adapts each triple to the existing scalar array ABI. The local bound is the official bound.

The local `baby_step_giant_step` benchmark is related but narrower: it only accepts coprime base/modulus pairs and returns a least positive exponent. This package is the generalized EBSGS method: it repeatedly strips `gcd(x,m)` factors (returning early when divisibility fails or a reduced target is reached), then runs a minimum-exponent coprime BSGS. That reduction phase is necessary for solutions such as `2^3 ≡ 0 (mod 8)`, which ordinary coprime BSGS rejects.

The coprime search stores the smallest exponent for each baby residue, then visits giant blocks in increasing order. A 65,536-slot open-address table holds the at-most 31,623 baby steps required by the modulus bound. Modular products are at most `10^18`, within signed 64-bit range.

## Workload

[`workload.json`](workload.json) covers the `0^0` convention, exponent zero, zero bases, coprime and non-coprime solutions, early gcd rejection, no-solution cases, and a large modulus with a small known answer. The independent oracle enumerates powers directly; workload exponents are kept small enough for that reference method.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm discrete_logarithm_mod --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/d/discrete_logarithm_mod/rust/build.json
```

## Source

- [Library Checker task statement](https://github.com/yosupo06/library-checker-problems/blob/master/number_theory/discrete_logarithm_mod/task.md)

## Implementations

The nine standard language ports and the optional Mojo port are under the corresponding language folders at `d/discrete_logarithm_mod`, using the shared array-scalar ABI.
