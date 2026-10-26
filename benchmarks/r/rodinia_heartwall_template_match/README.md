# Rodinia Heartwall normalized template match

This bounded package extracts the later-frame normalized template-matching
score and maximum-absolute-score selection from Rodinia Heartwall. The source
rotates the template into its convolution buffer, computes the correlation
field, derives local image sums and sums of squares with vertical and
horizontal prefix accumulation, normalizes the covariance, applies a one-hot tracking
mask, and retains the first maximum absolute score. This package exposes that
operation over a small explicit image/template pair and an explicit candidate
mask.

## Contract

- Symbol: `rodinia_heartwall_template_match`; ABI: `i64_array_bytes_output`.
- Input is `[image_rows, image_cols, template_rows, template_cols,
  candidate_mask, template_column_major..., image_column_major...]`.
- Image dimensions are 2–8, template dimensions 2–4 and no larger than the
  image. Pixel values are unsigned grayscale values 0–255. The candidate mask
  uses one bit per valid top-left template placement in column-major order.
- For each enabled candidate, compute the binary32 correlation numerator
  `sum(T*P) - sum(P)*sum(T)/N`. The source rotates T before convolution,
  producing the ordinary same-orientation T/P dot product. Normalize using
  `denomT = sqrt(N-1) * sqrt(sum(T^2)/N-(sum(T)/N)^2)`, then
  `score = (sum(T*P)-sum(P)*sum(T)/N) /
  (sqrt(max(0,sum(P^2)-sum(P)^2/N))*denomT)`. The package uses explicit
  column-major direct accumulation for each bounded patch; the pinned CUDA
  launcher obtains patch sums through 2D prefix buffers, so intermediate
  binary32 rounding can differ even though the score equations and selection
  rule match. Zero-variance templates and enabled patches are rejected as
  invalid to keep the score finite.
- Return the enabled candidate's column-major linear position with greatest
  absolute score. Strict `>` retains the first position on ties. A zero mask
  returns position 0, matching the source's zero-initialized maximum/index.
  Success writes one little-endian signed-i64 index (8 bytes); malformed input
  returns `-1`; null output or capacity below 8 returns `-2` without writes.
- The profile uses binary32 operations in the direct-accumulation order
  defined above. It does not reproduce the source's integral-prefix reduction
  order, so intermediate rounding can differ. CUDA thread scheduling,
  image/video loading, initial
  template creation, frame-to-frame coordinate updates, template adaptation,
  and application tracking state are excluded.

This operation is distinct from `rodinia_leukocyte_gicov`, which computes a
GICOV ellipse score from projected gradients. It also differs from local
one-dimensional signal cross-correlation and unnormalized image convolution.

## Source and rights

Pinned source: `utcs-scea/rodinia`, commit
[`f30e63663cfb114939a15c7ffc4ae112055ae6a8`](https://github.com/utcs-scea/rodinia/tree/f30e63663cfb114939a15c7ffc4ae112055ae6a8).
The normalized convolution and score stages are in
[`cuda/heartwall/kernel.cu`](https://github.com/utcs-scea/rodinia/blob/f30e63663cfb114939a15c7ffc4ae112055ae6a8/cuda/heartwall/kernel.cu#L164-L259)
and lines 812–1168. The package retains the complete University of Virginia
license and citation list in [`LICENSE.txt`](LICENSE.txt).

Primary and independent verifier models are
[`rodinia_heartwall_template_match_oracle.py`](../../rodinia_heartwall_template_match_oracle.py)
and [`rodinia_heartwall_template_match_verifier_oracle.py`](../../rodinia_heartwall_template_match_verifier_oracle.py).

## Ports

| Language | Port |
|---|---|
| C | [`c/r/rodinia_heartwall_template_match.c`](../../../c/r/rodinia_heartwall_template_match.c) |
| C3 | [`c3/r/rodinia_heartwall_template_match.c3`](../../../c3/r/rodinia_heartwall_template_match.c3) |
| C++ | [`cpp/r/rodinia_heartwall_template_match.cpp`](../../../cpp/r/rodinia_heartwall_template_match.cpp) |
| Elisa | [`elisa/r/rodinia_heartwall_template_match.elisa`](../../../elisa/r/rodinia_heartwall_template_match.elisa) |
| Nim | [`nim/r/rodinia_heartwall_template_match.nim`](../../../nim/r/rodinia_heartwall_template_match.nim) |
| Odin | [`odin/r/rodinia_heartwall_template_match.odin`](../../../odin/r/rodinia_heartwall_template_match.odin) |
| Rust | [`rust/r/rodinia_heartwall_template_match.rs`](../../../rust/r/rodinia_heartwall_template_match.rs) |
| V | [`v/r/rodinia_heartwall_template_match.v`](../../../v/r/rodinia_heartwall_template_match.v) |
| Zig | [`zig/r/rodinia_heartwall_template_match.zig`](../../../zig/r/rodinia_heartwall_template_match.zig) |
