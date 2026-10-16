# Fresnel diffraction four-sample slice

The pinned Python source handles 1D and 2D complex arrays with SciPy FFTs. It centers the input, transforms it, multiplies by the Fresnel transfer function `exp(-i*pi*wavelength*distance*frequency²)`, inverse-transforms, and uncenters the result. No existing benchmark in this repository measures Fresnel integrals or Fresnel diffraction; the area and surface-area packages cover different scalar geometry formulas.

This bounded contract uses a 1D complex field of exactly four samples. Input is `[sample_count, pixel_size, wavelength, propagation_distance, real0..real3, imag0..imag3]`; the first four entries must be `[4, 1, 1, 16]`, and all real and imaginary sample components must be finite and within `[-100, 100]`. At these fixed physical values the four frequencies are `[-1/2, -1/4, 0, 1/4]`, giving transfer factors `[1, -1, 1, -1]`. The implementation uses the equivalent direct four-point DFT, with exact twiddle factors `1`, `-1`, `i`, and `-i`. It returns eight float64 values, first the four real parts and then the four imaginary parts, both in original sample order.

Invalid shapes, parameters, or sample values return `-1`; a null or undersized output returns `-2`. See [`workload.json`](workload.json), the [independent oracle](../../fresnel_diffract_oracle.py), and the [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/fresnel_diffract.py).

| Language | Port |
|---|---|
| C | [`c/f/fresnel_diffract.c`](../../../c/f/fresnel_diffract.c) |
| C3 | [`c3/f/fresnel_diffract.c3`](../../../c3/f/fresnel_diffract.c3) |
| C++ | [`cpp/f/fresnel_diffract.cpp`](../../../cpp/f/fresnel_diffract.cpp) |
| Elisa | [`elisa/f/fresnel_diffract.elisa`](../../../elisa/f/fresnel_diffract.elisa) |
| Nim | [`nim/f/fresnel_diffract.nim`](../../../nim/f/fresnel_diffract.nim) |
| Odin | [`odin/f/fresnel_diffract.odin`](../../../odin/f/fresnel_diffract.odin) |
| Rust | [`rust/f/fresnel_diffract.rs`](../../../rust/f/fresnel_diffract.rs) |
| V | [`v/f/fresnel_diffract.v`](../../../v/f/fresnel_diffract.v) |
| Zig | [`zig/f/fresnel_diffract.zig`](../../../zig/f/fresnel_diffract.zig) |

Run focused verification with `python3 benchmarks/verify_float64_slice_io.py --algorithm fresnel_diffract`.
