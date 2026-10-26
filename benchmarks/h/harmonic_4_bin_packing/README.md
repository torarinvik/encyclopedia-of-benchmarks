# Harmonic-4 online bin packing

This bounded profile instantiates `HARM_4`: each arriving size is assigned to
one of four harmonic size classes, and each class independently uses Next Fit.
The current open bin of a class is reused when the next item fits; otherwise a
new global bin is opened. Input order is preserved and bin IDs follow their
first-open time.

Input is `[item_count, sizes...]`, with `1 <= item_count <= 32` and integer
sizes from 1 through 10,000 (bin capacity 10,000). The classes are
`(1/2,1]`, `(1/3,1/2]`, `(1/4,1/3]`, and `(0,1/4]`. Output is
`[bin_count, bin_id_for_each_item...]` as little-endian signed i64 values.
Invalid input returns `-1`; null output or insufficient capacity returns
`-2` without writing.

The source is “Harmonic Algorithm for Online Bin Packing,” DOI
[`10.1007/978-1-4939-2864-4_490`](https://doi.org/10.1007/978-1-4939-2864-4_490).
This is a clean-room fixed-parameter profile; no book prose or upstream code
is copied. The class-specific Next-Fit recurrence differs from First Fit.

| Language | Port |
|---|---|
| C | `c/h/harmonic_4_bin_packing.c` |
| C3 | `c3/h/harmonic_4_bin_packing.c3` |
| C++ | `cpp/h/harmonic_4_bin_packing.cpp` |
| Elisa | `elisa/h/harmonic_4_bin_packing.elisa` |
| Nim | `nim/h/harmonic_4_bin_packing.nim` |
| Odin | `odin/h/harmonic_4_bin_packing.odin` |
| Rust | `rust/h/harmonic_4_bin_packing.rs` |
| V | `v/h/harmonic_4_bin_packing.v` |
| Zig | `zig/h/harmonic_4_bin_packing.zig` |
