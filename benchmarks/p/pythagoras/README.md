# Pythagoras distance

The pinned Go routine computes the Euclidean distance between two 3D vectors by summing the squares of coordinate differences and taking the square root.

## Contract

Input is six signed integer coordinates in the order `[ax, ay, az, bx, by, bz]`, each in `[-1,000,000, 1,000,000]`. Output is the 3D distance as a float64. Invalid input returns `-1e300`. The bound keeps every squared difference sum exactly representable before the square root.

See [`workload.json`](workload.json) and the runtime [oracle](../../pythagoras_oracle.py). Pinned source: [TheAlgorithms/Go `pythagoras.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/pythagoras/pythagoras.go).

| Language | Port |
|---|---|
| C | [`c/p/pythagoras.c`](../../../c/p/pythagoras.c) |
| C3 | [`c3/p/pythagoras.c3`](../../../c3/p/pythagoras.c3) |
| C++ | [`cpp/p/pythagoras.cpp`](../../../cpp/p/pythagoras.cpp) |
| Elisa | [`elisa/p/pythagoras.elisa`](../../../elisa/p/pythagoras.elisa) |
| Nim | [`nim/p/pythagoras.nim`](../../../nim/p/pythagoras.nim) |
| Odin | [`odin/p/pythagoras.odin`](../../../odin/p/pythagoras.odin) |
| Rust | [`rust/p/pythagoras.rs`](../../../rust/p/pythagoras.rs) |
| V | [`v/p/pythagoras.v`](../../../v/p/pythagoras.v) |
| Zig | [`zig/p/pythagoras.zig`](../../../zig/p/pythagoras.zig) |
