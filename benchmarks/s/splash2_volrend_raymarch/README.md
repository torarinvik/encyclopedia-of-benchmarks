# SPLASH-2-inspired bounded volume ray marching

This package defines a deterministic, bounded volume ray-casting kernel
inspired by SPLASH-2 Volrend. It is a clean-room algorithmic profile, not a
reimplementation of the protected SPLASH-2 program or its parallel renderer.
It differs from local surface ray tracing by sampling and compositing a voxel
field along supplied rays.

## Contract

- ABI: `i64_array_bytes_output`; exported symbol: `splash2_volrend_raymarch`.
- Input is `[S,R,T, (alpha,gray)*S^3, (x0,y0,z0,dx,dy,dz)*R]`.
- `S` is 2, 4, or 8; `R` is 1..16; `T` is 1..32. Voxels are ordered
  x-fast, then y, then z. Opacity and grayscale are integers in 0..255.
- Ray positions and per-sample steps use signed Q8.8 coordinates, where one
  voxel unit is 256. Origins and every sampled position must lie in
  `[0,(S-1)*256]^3`; each step component lies in `[-(S-1)*256,(S-1)*256]`.
  A ray with `T>1` must have at least one nonzero step component. A one-sample
  ray may have a zero step. Rays are supplied instead of generating a camera
  projection, so no floating-point camera arithmetic is involved.
- The opacity-support pyramid is built per call. A base bit is set if any of
  the sample cell's eight trilinear corner voxels has nonzero opacity, with
  upper neighbors clamped at the volume edge. Each higher level is the OR of
  eight children. For every sample, the implementation queries its pyramid
  path from the root to the base. A zero bit skips interpolation and
  compositing for that sample.
- Trilinear opacity and premultiplied grayscale color use integer weights
  formed from Q8 fractions, divided by `2^24`. Opacity is quantized to Q16 by
  round-half-up after division by `255*2^24`; premultiplied grayscale is
  quantized to Q16 after division by `255^2*2^24`. Front-to-back accumulation
  updates each channel with the remaining Q16 transmittance, using round-half-up
  after division by `2^16`. A ray stops after the sample that makes
  accumulated opacity exactly `65536`.
- Samples are consumed in the input order `k=0..T-1`, even when adjacent
  positions fall in the same interpolation cell. Rays are returned in input
  order. Integer coordinates have zero fractional weight; at the upper volume
  face the upper interpolation neighbor clamps to that face. The output is
  premultiplied grayscale RGBA plus a diagnostic sample count per ray:
  `[gray,gray,gray,alpha,used]`, five bytes per ray. `used` includes the sample
  that triggered early termination. The output frame is exactly `5*R` bytes.
- Invalid input returns `-1`; a null output buffer returns `-2`; a short output
  buffer returns `-3`. Input validation takes precedence over output-buffer
  errors. No output bytes are written on any error.
- Valid input has at most 1123 signed 64-bit words; the parser accepts at most
  one extra trailing word so it can reject malformed frames safely. The caller
  output workspace is at most 80 bytes. Separately, the ports' primary fixed
  work arrays occupy 3456 bytes:
  two 512-byte voxel channels, a 2048-byte four-level support-pyramid array,
  and 384 bytes of int32 ray snapshots. Results are written only after all input
  and output-buffer checks have passed.

Pyramid construction costs `O(S^3)`. Rendering costs at most
`O(R*T*log S)` hierarchy probes, plus constant-size eight-corner interpolation
and compositing for supported samples. The 3456-byte scratch figure counts the
fixed voxel, ray, and support-pyramid arrays, excluding small scalar and
three-coordinate interpolation temporaries as well as caller-owned input and
output buffers. The `workspace` metadata records only the maximum caller output
frame, as required by the suite runner.

## Scope compared with SPLASH-2

SPLASH-2 Volrend casts rays through a voxel volume, uses an opacity hierarchy,
interpolates volume samples, composites front-to-back, and can terminate rays
early. The original code prepares volume opacity and shading data, constructs
an opacity bit pyramid, derives camera rays, partitions image work among
threads, and optionally supports adaptive image sampling. This bounded profile
accepts precomputed opacity/grayscale voxels and explicit rays, builds its
support pyramid inside each call, and fixes the sample count. It omits source
data loading, normal/light/shadow preprocessing, camera transforms, image
partitioning, adaptive sampling, and file output. The SPLASH-2 characterization
reports that adaptive sampling was not used in its study. These omissions and
the fixed-point rules are profile choices, not claims about the exact original
renderer.

## Provenance and rights

The algorithmic context comes from Nieh and Levoy's [1992 volume-rendering
paper](https://graphics.stanford.edu/papers/vv92/) and Woo et al.'s
[SPLASH-2 characterization](https://pages.cs.wisc.edu/~markhill/restricted/isca95_splash2.pdf).
See [`RIGHTS.md`](RIGHTS.md) for the clean-room statement and the restrictive
license notice on the cited source.

## Workload and ports

[`workload.json`](workload.json) records deterministic cases and expected byte
frames. [`verify_workload.py`](verify_workload.py) is a static package and
fixture verifier; it also compares the opacity-pyramid oracle with a separate
direct trilinear oracle that does not use a pyramid.

| Language | Source |
|---|---|
| C | [`c/s/splash2_volrend_raymarch.c`](../../../c/s/splash2_volrend_raymarch.c) |
| C3 | [`c3/s/splash2_volrend_raymarch.c3`](../../../c3/s/splash2_volrend_raymarch.c3) |
| C++ | [`cpp/s/splash2_volrend_raymarch.cpp`](../../../cpp/s/splash2_volrend_raymarch.cpp) |
| Elisa | [`elisa/s/splash2_volrend_raymarch.elisa`](../../../elisa/s/splash2_volrend_raymarch.elisa) |
| Mojo | [`mojo/s/splash2_volrend_raymarch.mojo`](../../../mojo/s/splash2_volrend_raymarch.mojo) |
| Nim | [`nim/s/splash2_volrend_raymarch.nim`](../../../nim/s/splash2_volrend_raymarch.nim) |
| Odin | [`odin/s/splash2_volrend_raymarch.odin`](../../../odin/s/splash2_volrend_raymarch.odin) |
| Rust | [`rust/s/splash2_volrend_raymarch.rs`](../../../rust/s/splash2_volrend_raymarch.rs) |
| V | [`v/s/splash2_volrend_raymarch.v`](../../../v/s/splash2_volrend_raymarch.v) |
| Zig | [`zig/s/splash2_volrend_raymarch.zig`](../../../zig/s/splash2_volrend_raymarch.zig) |

The primary reference is [`primary_oracle.py`](primary_oracle.py). The
independent direct sampler is [`independent_oracle.py`](independent_oracle.py).
