# Modular exponentiation

This benchmark ports TheAlgorithms/Lua's modpow loop, which applies modulo after each multiplication and halves the exponent when it is even.

## Contract

- The i64_array_scalar input is [base, exponent, modulus], with exactly three values.
- Base is in 0..=89,000,000, exponent is in 0..=64, and modulus is in 1..=89,000,000.
- The source asserts that base is nonzero when exponent is zero; that input returns INT64_MIN as the benchmark invalid-input sentinel. With positive exponent, base zero returns zero.
- The component bound keeps every multiplication below 2^53, so the source Lua 5.1 number representation computes each intermediate integer exactly.
- Invalid input returns INT64_MIN, which cannot be a valid residue. The maximum parseable length is 4 to admit an extra-value fixture; valid inputs contain 3 values.

## Pinned source

- Lua [modpow.lua](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/math/modpow.lua)

[workload.json](workload.json) covers the upstream examples, zero and unit cases, large bounded intermediates, maximum exponent, malformed lengths, and invalid domains. The independent oracle is [modpow_oracle.py](../../modpow_oracle.py).

Build and run commands:
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm modpow --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/m/modpow/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms modpow

## Ports

| Language | Source |
| --- | --- |
| C | [c/modpow.c](../../../c/m/modpow.c) |
| C3 | [c3/modpow.c3](../../../c3/m/modpow.c3) |
| C++ | [cpp/modpow.cpp](../../../cpp/m/modpow.cpp) |
| Elisa | [elisa/modpow.elisa](../../../elisa/m/modpow.elisa) |
| Nim | [nim/modpow.nim](../../../nim/m/modpow.nim) |
| Odin | [odin/modpow.odin](../../../odin/m/modpow.odin) |
| Rust | [rust/modpow.rs](../../../rust/m/modpow.rs) |
| V | [v/modpow.v](../../../v/m/modpow.v) |
| Zig | [zig/modpow.zig](../../../zig/m/modpow.zig) |
