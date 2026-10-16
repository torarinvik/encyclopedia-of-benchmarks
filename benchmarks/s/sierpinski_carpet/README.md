# Sierpinski carpet

This package ports the pinned Python source's integer base-3 cell predicate and row raster. A cell is a hole if, at any base-3 digit position, both its row and column digits are 1. The carpet side is 3^depth.

## Contract

The i64_array_bytes_output ABI receives [depth, filled_byte, hole_byte]. Depth is 0 through 4; the two byte values must be distinct printable ASCII bytes in 32..126. Output is the side length as an 8-byte signed i64 little-endian prefix, followed by the ASCII rows with newline bytes between rows and no trailing newline. Maximum output is 6,649 bytes. Invalid input returns -1; a null output pointer or insufficient capacity returns -2 without writing output.

The pinned source is TheAlgorithms/Python, commit e1a2a8b016001309a73d5fec4818c35cca139795, path fractals/sierpinski_carpet.py. See the [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/fractals/sierpinski_carpet.py), [workload](workload.json), and [oracle](../../sierpinski_carpet_oracle.py).

| Language | Port |
|---|---|
| C | ../../../c/s/sierpinski_carpet.c |
| C3 | ../../../c3/s/sierpinski_carpet.c3 |
| C++ | ../../../cpp/s/sierpinski_carpet.cpp |
| Elisa | ../../../elisa/s/sierpinski_carpet.elisa |
| Nim | ../../../nim/s/sierpinski_carpet.nim |
| Odin | ../../../odin/s/sierpinski_carpet.odin |
| Rust | ../../../rust/s/sierpinski_carpet.rs |
| V | ../../../v/s/sierpinski_carpet.v |
| Zig | ../../../zig/s/sierpinski_carpet.zig |

Build and record with the shared i64_array_bytes_output ABI after serialized integration is complete:

python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm sierpinski_carpet --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm sierpinski_carpet
