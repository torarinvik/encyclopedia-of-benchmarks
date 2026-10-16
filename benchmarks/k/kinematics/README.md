# Kinematics

The pinned Java class implements four constant-acceleration SUVAT formulas: final velocity, displacement, final-velocity squared, and displacement from initial/final velocities. The bounded interface selects one formula by operation code and returns twice the Java double result, keeping every result exact in an integer scalar.

## Contract

Input is [operation,x,y,z], with operation 0..3 and operands in [-1000,1000]. Operations compute, in order, 2*(u+a*t), 2*u*t+a*t*t, 2*u*u+4*a*s, and (u+v)*t. Invalid input returns -1.

See [workload](workload.json), [independent oracle](../../kinematics_oracle.py), and pinned [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/physics/Kinematics.java).

| Language | Port |
|---|---|
| C | [c/k/kinematics.c](../../../c/k/kinematics.c) |
| C3 | [c3/k/kinematics.c3](../../../c3/k/kinematics.c3) |
| C++ | [c++/k/kinematics.cpp](../../../c++/k/kinematics.cpp) |
| Elisa | [elisa/k/kinematics.elisa](../../../elisa/k/kinematics.elisa) |
| Nim | [nim/k/kinematics.nim](../../../nim/k/kinematics.nim) |
| Odin | [odin/k/kinematics.odin](../../../odin/k/kinematics.odin) |
| Rust | [rust/k/kinematics.rs](../../../rust/k/kinematics.rs) |
| V | [v/k/kinematics.v](../../../v/k/kinematics.v) |
| Zig | [zig/k/kinematics.zig](../../../zig/k/kinematics.zig) |
