# Modular inverse with Fermat's little theorem

Compute a modular inverse with the pinned C++ source's prime check and binary modular exponentiation. This remains separate from [`modular_inverse`](../modular_inverse/README.md), which uses the extended Euclidean algorithm and accepts composite moduli when the operands are coprime.

## Contract

- The `binary_scalar` input is `[a, m]`.
- The modulus `m` must be prime and in `[2, 1,000,000]`.
- The base `a` is in `[1, 1,000,000]` and must not be divisible by `m`. Restricting the contract to positive bases preserves the same result across both pinned C++ copies, whose negative-remainder handling differs.
- A valid input returns `a^(m-2) mod m`, in `[1, m-1]`. Composite moduli, zero, negative bases, bases outside the bound, and non-coprime pairs return `-1`.
- Positive multiples of `m` are outside the mathematical coprime domain. Since `binExpo()` reduces `a` modulo `m`, a nonzero multiple returns `0`; the wrappers do not consistently reject this case. The benchmark adapter rejects multiples and returns `-1`.
- With `m <= 1,000,000`, the primality loop is bounded by 1,000 divisor checks and each modular product stays below `10^12`, within signed 64-bit arithmetic.

## Workload and oracle

[`workload.json`](workload.json) includes prime and composite moduli, bases below and above the modulus, the smallest and largest supported prime moduli, and invalid inputs. The independent oracle is [`modular_inverse_fermat_little_theorem_oracle.py`](../../modular_inverse_fermat_little_theorem_oracle.py). All nine ports passed 408 oracle pairs each and recorded all 15 workload cases.

## Pinned sources

- [TheAlgorithms/C-Plus-Plus `modular_inverse_fermat_little_theorem.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/modular_inverse_fermat_little_theorem.cpp)
- [TheAlgorithms/C-Plus-Plus-1 duplicate](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/modular_inverse_fermat_little_theorem.cpp)

The C-Plus-Plus source exposes `modular_inverse()` and normalizes negative bases before exponentiation. The C-Plus-Plus-1 copy is a standalone driver that calls `binExpo()` directly, without that normalization or the same zero/coprime guard. On the positive, prime-modulus, coprime domain above, both copies produce the same inverse; negative bases and multiples of the modulus are excluded from the shared contract.

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
