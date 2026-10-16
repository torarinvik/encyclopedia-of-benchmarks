# Modular inverse with Fermat's little theorem

Compute a modular inverse with the pinned C++ source's prime check and binary modular exponentiation. This remains separate from [`modular_inverse`](../modular_inverse/README.md), which uses the extended Euclidean algorithm and accepts composite moduli when the operands are coprime.

## Contract

- The `binary_scalar` input is `[a, m]`.
- The modulus `m` must be prime and in `[2, 1,000,000]`.
- The base `a` is in `[-1,000,000, 1,000,000]`, is nonzero, and must satisfy `-m < a < m`. Negative bases are normalized by adding `m` once, matching the pinned source's normalization loop on this bounded domain.
- A valid input returns `a^(m-2) mod m`, in `[1, m-1]`. Composite moduli, zero, bases outside the bound, and non-coprime pairs return `-1`.
- Positive multiples of `m` are outside the mathematical coprime domain. The source's function checks only `a == 0` before exponentiation and would return `0` for such a multiple; the benchmark adapter rejects them as invalid and returns `-1`.
- With `m <= 1,000,000`, the primality loop is bounded by 1,000 divisor checks and each modular product stays below `10^12`, within signed 64-bit arithmetic.

## Workload and oracle

[`workload.json`](workload.json) includes prime and composite moduli, positive and negative bases, the smallest and largest supported prime moduli, and invalid inputs. The independent oracle is [`modular_inverse_fermat_little_theorem_oracle.py`](../../modular_inverse_fermat_little_theorem_oracle.py).

## Pinned sources

- [TheAlgorithms/C-Plus-Plus `modular_inverse_fermat_little_theorem.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/modular_inverse_fermat_little_theorem.cpp)
- [TheAlgorithms/C-Plus-Plus-1 duplicate](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/modular_inverse_fermat_little_theorem.cpp)

## Build and record

    python3 benchmarks/build_abi.py --family binary_scalar --algorithm modular_inverse_fermat_little_theorem --language rust
    python3 benchmarks/run_binary_scalar.py --algorithm modular_inverse_fermat_little_theorem
    python3 benchmarks/verify_binary_scalar.py --algorithms modular_inverse_fermat_little_theorem

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/modular_inverse_fermat_little_theorem.c`](../../../c/m/modular_inverse_fermat_little_theorem.c) |
| C3 | [`c3/m/modular_inverse_fermat_little_theorem.c3`](../../../c3/m/modular_inverse_fermat_little_theorem.c3) |
| C++ | [`cpp/m/modular_inverse_fermat_little_theorem.cpp`](../../../cpp/m/modular_inverse_fermat_little_theorem.cpp) |
| Elisa | [`elisa/m/modular_inverse_fermat_little_theorem.elisa`](../../../elisa/m/modular_inverse_fermat_little_theorem.elisa) |
| Nim | [`nim/m/modular_inverse_fermat_little_theorem.nim`](../../../nim/m/modular_inverse_fermat_little_theorem.nim) |
| Odin | [`odin/m/modular_inverse_fermat_little_theorem.odin`](../../../odin/m/modular_inverse_fermat_little_theorem.odin) |
| Rust | [`rust/m/modular_inverse_fermat_little_theorem.rs`](../../../rust/m/modular_inverse_fermat_little_theorem.rs) |
| V | [`v/m/modular_inverse_fermat_little_theorem.v`](../../../v/m/modular_inverse_fermat_little_theorem.v) |
| Zig | [`zig/m/modular_inverse_fermat_little_theorem.zig`](../../../zig/m/modular_inverse_fermat_little_theorem.zig) |
