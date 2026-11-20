# Integer domain coloring

This package renders a bounded complex-plane sample grid for `f(z)=z^2` as
row-major RGB24 pixels. Each complex output's phase selects hue; its magnitude
fraction sets a repeating contour shade. The finite integer rules below retain
the domain-coloring structure while making every output byte reproducible
across the ten implementation languages.

## Contract

- ABI: `i64_array_bytes_output`; exported symbol: `domain_coloring`.
- Input is exactly `[width, height, x0_q, y0_q, dx_q, dy_q]`. The sample at
  column `x`, row `y` is `z=(x_q+i*y_q)/4`, where
  `x_q=x0_q+x*dx_q` and `y_q=y0_q+y*dy_q`.
- Width and height are 1–16. `x0_q` and `y0_q` are in `[-32,32]`; `dx_q` and
  `dy_q` are in `[-8,8]`. Both the first and last coordinate on each axis must
  remain in `[-32,32]`. Samples are emitted in increasing row index and then
  increasing column index, so the output order is row-major even for negative
  coordinate steps.
- Compute `f(z)=z²=u+i*v` using integer numerators
  `u=x_q²-y_q²` and `v=2*x_q*y_q`. `m16=x_q²+y_q²` is exactly
  `16*|f(z)|`; no floating-point operations are used.
- Map phase to the integer hue circle `[0,1535]`, with 256 values per 60-degree
  sector. Let `A=|u|`, `B=|v|`, `lo=min(A,B)`, and `hi=max(A,B)`. If `hi=0`,
  hue is zero. Otherwise `t=floor(192*lo/hi)`. The value 192 represents one
  45-degree octant on this hue scale. Select the octant by signs and whether
  `A>=B`: for `v>=0,u>=0`, use `t` when `A>=B`, else `384-t`; for `v>=0,u<0`,
  use `384+t` when `A<B`, else `768-t`; for `v<0,u<0`, use `768+t` when
  `A>=B`, else `1152-t`; for `v<0,u>=0`, use `1152+t` when `A<B`, else
  `1536-t`. Reduce 1536 to zero. This explicitly defined piecewise-linear
  phase approximation avoids platform-dependent `atan2` rounding.
- Set HSV saturation to 255 and value to `128+8*(m16 mod 16)`. This is a
  half-to-near-full fractional-magnitude contour shade quantized in steps of
  eight. Convert
  HSV to RGB with `sector=hue/256`, `fraction=hue mod 256`,
  `p=0`, `q=floor(value*(255-fraction)/255)`, and
  `t=floor(value*fraction/255)`. The six sectors emit `(value,t,p)`,
  `(q,value,p)`, `(p,value,t)`, `(p,q,value)`, `(t,p,value)`, and
  `(value,p,q)` respectively.
- The output is three bytes `(R,G,B)` per sample. Success returns
  `3*width*height`; malformed or out-of-domain input returns `-1`; null or
  short output storage returns `-2`. Input validation precedes output checks,
  and errors leave output untouched.

The render takes O(width*height) time and O(width*height) bounded temporary
storage. The maximum output and local staging buffer are 768 bytes. The input
grid and function are fixed to keep this profile distinct from standalone
HSV/RGB conversions and iterative fractal renderers such as Mandelbrot/Julia.

## Sources and clean-room status

The algorithmic provenance is the [Algorithm Archive chapter on Domain
Coloring](https://www.algorithm-archive.org/contents/domain_coloring/domain_coloring.html),
which describes evaluating a complex function over an input grid, encoding
phase as hue, and using magnitude-dependent contours. This package chooses
`f(z)=z²` and pins its own integer phase quantization, contour shade, and RGB
conversion rules. Those deterministic rules are a bounded benchmark contract,
not an attempt to reproduce the chapter's plotting library output. The
implementations, references, fixtures, and explanatory text here were authored
independently; no chapter code, prose, or images are included. Rights and
provenance details are in [`RIGHTS.md`](RIGHTS.md).

## Workload and references

- Workload: [`workload.json`](workload.json)
- Primary reference: [`domain_coloring_oracle.py`](../../domain_coloring_oracle.py)
- Independent reference: [`independent_oracle.py`](independent_oracle.py)
- Static source inventory: [`INVENTORY.md`](INVENTORY.md)

The cases include the zero, positive and negative phase axes, a quarter-unit
magnitude change, a 2 by 2 row-major grid, invalid dimensions/endpoints,
malformed framing, and insufficient output capacity.

## Language ports

| Language | Source |
|---|---|
| C | [domain_coloring.c](../../../c/d/domain_coloring.c) |
| C3 | [domain_coloring.c3](../../../c3/d/domain_coloring.c3) |
| C++ | [domain_coloring.cpp](../../../cpp/d/domain_coloring.cpp) |
| Elisa | [domain_coloring.elisa](../../../elisa/d/domain_coloring.elisa) |
| Mojo | [domain_coloring.mojo](../../../mojo/d/domain_coloring.mojo) |
| Nim | [domain_coloring.nim](../../../nim/d/domain_coloring.nim) |
| Odin | [domain_coloring.odin](../../../odin/d/domain_coloring.odin) |
| Rust | [domain_coloring.rs](../../../rust/d/domain_coloring.rs) |
| V | [domain_coloring.v](../../../v/d/domain_coloring.v) |
| Zig | [domain_coloring.zig](../../../zig/d/domain_coloring.zig) |
