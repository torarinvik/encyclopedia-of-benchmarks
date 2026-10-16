# Lorentz transformation of a four-vector

The pinned Python source handles a boost in the x direction. Its numeric `transform` path multiplies the input time coordinate by the speed of light, then applies the matrix with diagonal entries γ and off-diagonal x/time entries −γβ. The y and z components pass through unchanged.

## Contract

Input is `[velocity_mps, component, time_microseconds, x_centimeters, y_centimeters, z_centimeters]`. Velocity is 1..200,000,000 m/s, component is 0..3, time is ±1,000,000 microseconds, and spatial coordinates are ±100,000,000 centimeters. The event is interpreted as seconds and meters after scaling, matching the source's `event[0] *= c` operation. The selected output component is returned as a binary64 number. Invalid inputs return `-1e300`; comparison uses 1e-6 absolute and 1e-12 relative tolerance.

See [workload](workload.json), [oracle](../../lorentz_transformation_four_vector_oracle.py), and the pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/lorentz_transformation_four_vector.py).

| Language | Port |
|---|---|
| C | c/l/lorentz_transformation_four_vector.c |
| C3 | c3/l/lorentz_transformation_four_vector.c3 |
| C++ | cpp/l/lorentz_transformation_four_vector.cpp |
| Elisa | elisa/l/lorentz_transformation_four_vector.elisa |
| Nim | nim/l/lorentz_transformation_four_vector.nim |
| Odin | odin/l/lorentz_transformation_four_vector.odin |
| Rust | rust/l/lorentz_transformation_four_vector.rs |
| V | v/l/lorentz_transformation_four_vector.v |
| Zig | zig/l/lorentz_transformation_four_vector.zig |
