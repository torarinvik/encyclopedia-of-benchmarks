# Integer exponentiation

This benchmark covers the pinned Solidity `Exponentiation` contract, which stores two `uint16` values and returns their unmodded power.

## Contract

- The `binary_scalar` input is `[base, exponent]`.
- The benchmark bounds `base` to `0..=255` and `exponent` to `0..=7`, so the result fits signed 64-bit output and the source's checked `uint256` exponentiation cannot overflow.
- Return `base^exponent`, including `0^0 = 1`. Inputs outside the bounds return `-1`.
- The contract’s state setters and ABI are adapted to a direct two-argument call; the exponentiation operation is the same.

The same-named Go candidate computes modular exponentiation and is separately mapped to [`modular_exponentiation`](../modular_exponentiation/README.md), because its operation differs.

The workload is in [`workload.json`](workload.json), and the independent integer-power oracle is [`exponentiation_oracle.py`](../../exponentiation_oracle.py).

## Pinned source

- [TheAlgorithms/Solidity `src/Maths/exponentiation.sol`](https://github.com/TheAlgorithms/Solidity/blob/08cba51fb38e276062b0c9791d7e0ee494ffa903/src/Maths/exponentiation.sol)

## Build and record

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm exponentiation --language rust
python3 benchmarks/run_binary_scalar.py --algorithm exponentiation
python3 benchmarks/verify_binary_scalar.py --algorithms exponentiation
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/e/exponentiation.c`](../../../c/e/exponentiation.c) |
| C3 | [`c3/e/exponentiation.c3`](../../../c3/e/exponentiation.c3) |
| C++ | [`cpp/e/exponentiation.cpp`](../../../cpp/e/exponentiation.cpp) |
| Elisa | [`elisa/e/exponentiation.elisa`](../../../elisa/e/exponentiation.elisa) |
| Nim | [`nim/e/exponentiation.nim`](../../../nim/e/exponentiation.nim) |
| Odin | [`odin/e/exponentiation.odin`](../../../odin/e/exponentiation.odin) |
| Rust | [`rust/e/exponentiation.rs`](../../../rust/e/exponentiation.rs) |
| V | [`v/e/exponentiation.v`](../../../v/e/exponentiation.v) |
| Zig | [`zig/e/exponentiation.zig`](../../../zig/e/exponentiation.zig) |
