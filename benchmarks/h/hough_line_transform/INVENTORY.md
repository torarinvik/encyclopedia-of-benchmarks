# Static inventory

The package consists of the following contract and reference files:

- `README.md` — bounded accumulator contract and quantization policy.
- `RIGHTS.md` — source provenance and clean-room note.
- `workload.json` — valid, boundary, null-output, capacity, and malformed cases.
- `primary_oracle.py` — foreground-pixel vote accumulation.
- `independent_oracle.py` — angle/rho-bin scanning reference.
- `check_inventory.py` — static port inventory and fixture/reference checker.

The exported symbol is `hough_line_transform`, with one implementation in
each supported language: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, and Zig.
The package uses the `i64_array_bytes_output` ABI and emits exactly 116 bytes
for each valid image.
