# Least square approximation

The pinned Rust routine builds a polynomial least-squares system and returns coefficients in descending order rounded to five decimals. This bounded contract specializes it to degree one, integer points, and the exact two-coefficient line fit; coefficients are scaled and packed for the scalar ABI.

## Contract

Input is [point_count,x0,y0,...], with 2..6 points and coordinates in [-20,20]. At least two distinct x values are required. Output packs slope then intercept after rounding each to five decimals and multiplying by 100000. Invalid or rank-deficient inputs return -1.

See [workload](workload.json), [oracle](../../least_square_approx_oracle.py), and pinned [Rust source](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/least_square_approx.rs).

| Language | Port |
|---|---|
| C | c/l/least_square_approx.c |
| C3 | c3/l/least_square_approx.c3 |
| C++ | cpp/l/least_square_approx.cpp |
| Elisa | elisa/l/least_square_approx.elisa |
| Nim | nim/l/least_square_approx.nim |
| Odin | odin/l/least_square_approx.odin |
| Rust | rust/l/least_square_approx.rs |
| V | v/l/least_square_approx.v |
| Zig | zig/l/least_square_approx.zig |
