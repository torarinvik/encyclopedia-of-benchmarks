# Julia Sets

This benchmark ports the pure quadratic iteration path from the pinned Python source. It does not build a grid or render an image.

## Contract

- Input is [iterations, c_re_sixteenths, c_im_sixteenths, count, (z_re_sixteenths, z_im_sixteenths)*count].
- iterations is 0 through 8, count is 0 through 32, and every component is an integer in -128 through 128 interpreted as a multiple of 1/16.
- Each start point and the parameter are converted to complex64. Apply exactly the requested number of updates z = z*z + c in input order; no early escape, sanitizing, or plotting is performed.
- If any computed complex64 intermediate has a nonfinite real or imaginary component, the bounded wrapper returns -1 without writing output. This makes raw binary32 output deterministic for valid finite trajectories.
- Output is each final point as real then imaginary IEEE binary32 little-endian, with no header. The maximum output is 256 bytes.
- A successful call returns the number of output bytes written.
- Invalid input returns -1; a null or short output buffer returns -2 without writing.

The independent oracle is [julia_sets_oracle.py](../../julia_sets_oracle.py). The workload includes zero iterations, escape and bounded trajectories, complex updates, boundary values, malformed input, and short capacity.

## Pinned source

[TheAlgorithms/Python fractals/julia_sets.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/fractals/julia_sets.py), commit e1a2a8b016001309a73d5fec4818c35cca139795, pure iterate_function(eval_quadratic_polynomial, ...) path.

## Implementations

| Language | Source |
| --- | --- |
| C | [julia_sets.c](../../../c/j/julia_sets.c) |
| C3 | [julia_sets.c3](../../../c3/j/julia_sets.c3) |
| C++ | [julia_sets.cpp](../../../cpp/j/julia_sets.cpp) |
| Elisa | [julia_sets.elisa](../../../elisa/j/julia_sets.elisa) |
| Nim | [julia_sets.nim](../../../nim/j/julia_sets.nim) |
| Odin | [julia_sets.odin](../../../odin/j/julia_sets.odin) |
| Rust | [julia_sets.rs](../../../rust/j/julia_sets.rs) |
| V | [julia_sets.v](../../../v/j/julia_sets.v) |
| Zig | [julia_sets.zig](../../../zig/j/julia_sets.zig) |
