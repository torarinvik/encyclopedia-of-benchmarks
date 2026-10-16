# Modular inverse

## Contract

This benchmark brings together the pinned Go, Lua, and Nim modular-inverse
sources. It uses the binary_scalar ABI with inputs [a, modulus], where
0 <= a <= 1,000,000 and 2 <= modulus <= 1,000,000. A coprime pair returns
the least positive inverse x in [1, modulus-1] satisfying
(a*x) mod modulus = 1. A pair with no inverse returns -1.

The shared domain excludes modulus 1 because the Go implementation returns
zero there while Lua and Nim represent the inverse as absent. It also excludes
negative a: Lua and Nim normalize negative inputs, but the Go source's signed
recursive gcd can report gcd -1 and reject that case. The bounded nonnegative
domain is common to all three sources and keeps extended-Euclid coefficient
arithmetic inside signed 64-bit.

The source APIs report absence differently: Go returns an error with value
zero, Lua returns nil, and Nim returns none. The benchmark adapter maps each
absent result and every out-of-domain input to -1. This is the adapter
sentinel, not a return value from those APIs.

## Sources

- [Go inverse.go](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/modular/inverse.go) at commit 5ba447ec5ff3d1213de65b92e726ee74c5d5cc19; the Go inverse catalog candidate is covered only on this common domain.
- [Lua modular_inverse.lua](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/math/modular_inverse.lua) at commit cedc141018ad48884318fe08a6db278664b17128.
- [Nim modular_inverse.nim](https://github.com/TheAlgorithms/Nim/blob/63eec16614b46c91078653e8d3c049fe99ad36b3/maths/modular_inverse.nim) at commit 63eec16614b46c91078653e8d3c049fe99ad36b3.

## Workload and implementations

The workload includes coprime and non-coprime pairs, unit and near-bound
values, and invalid moduli and operands. It uses the shared binary_scalar ABI.
The nine ports are in c/m/modular_inverse.c, c3/m/modular_inverse.c3,
cpp/m/modular_inverse.cpp, elisa/m/modular_inverse.elisa,
nim/m/modular_inverse.nim, odin/m/modular_inverse.odin,
rust/m/modular_inverse.rs, v/m/modular_inverse.v, and
zig/m/modular_inverse.zig.
