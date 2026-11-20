# Posit8 rational encoder

This benchmark maps a bounded batch of exact rational values to the nearest
representable `posit8` codeword with `es=2`. It measures format encoding and
rounding only; it does not perform posit arithmetic or use floating-point
approximations.

## Contract

The exported `posit8_rational_encoder` function uses the
`i64_array_bytes_output` ABI. Its input is
`[count, numerator_0, denominator_0, ..., numerator_(count-1), denominator_(count-1)]`.
`count` is in 0..32; each signed numerator is in -2^31..2^31 and each positive
denominator is in 1..2^31. The frame must contain exactly `1+2*count` words.
Every input integer is also required to fit signed i64.

Each output byte is one raw posit8 encoding in input order, using the 2022
Posit Standard's fixed `es=2` format. Zero maps to `0x00`; finite nonzero
values are rounded to the nearest representable value. Values beyond the
finite range clamp to `maxPos` or `minPos` with the input sign. At an exact
midpoint, the lower-magnitude positive codeword wins when its least-significant
bit is zero; otherwise the upper codeword wins. The sign is applied after
rounding the magnitude, using the standard 8-bit two's-complement encoding.
The bounded input contains only finite rationals, so `NaR` is never emitted.

Malformed input returns `-1`. A null output pointer or capacity smaller than
the batch size returns `-2`. Validation happens before output-capacity checks,
and no error path writes any output bytes. A valid empty batch returns zero;
it still requires a non-null output pointer under this ABI profile.

The primary reference binary-searches the ordered positive posit codewords and
compares exact scaled rational values using quotient/remainder comparisons,
which avoid overflow at the maximum denominator. The independent reference parses each
codeword into a Python `Fraction`, scans the full positive code range, and
chooses the nearest exact value. Both use integer/rational comparisons only.
The native ports use a bounded 32-byte staging buffer; the declared workspace
ceiling is 128 bytes, excluding caller-owned input/output storage.

## Sources and scope

The normative source is the [Posit Standard (2022), §§3.2–3.3 and 4.1](https://posithub.org/docs/posit_standard-2.pdf), which defines the posit fields, represented values, and nearest-value rounding rule. Gustafson and Yonemoto's [2017 paper](https://doi.org/10.14529/jsfi170206) is a second algorithmic overview. The score-18 `Posit-numbers-encoding` title in the pinned [RosettaCodeData index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks) supplied discovery only. No Rosetta Code implementation, task wording, examples, or fixtures were copied.

This profile selects a portable posit8 representation and exact rational input
to avoid host floating-point differences. It is distinct from IEEE binary16,
binary32, and binary64 encodings: posit uses a variable-length regime, a
two-bit exponent field, tapered precision, and a two's-complement negative
encoding.

See [`workload.json`](workload.json), [`RIGHTS.md`](RIGHTS.md), and
[`INVENTORY.md`](INVENTORY.md). Package-local references and inventory helpers
are source artifacts and have not been run. The profile is registered in the
shared `i64_array_bytes_output` runner, verifier, and catalog; no benchmark or
validation run has been performed.

## Native ports

| Language | Source |
| --- | --- |
| C | [`c/p/posit8_rational_encoder.c`](../../../c/p/posit8_rational_encoder.c) |
| C3 | [`c3/p/posit8_rational_encoder.c3`](../../../c3/p/posit8_rational_encoder.c3) |
| C++ | [`cpp/p/posit8_rational_encoder.cpp`](../../../cpp/p/posit8_rational_encoder.cpp) |
| Elisa | [`elisa/p/posit8_rational_encoder.elisa`](../../../elisa/p/posit8_rational_encoder.elisa) |
| Mojo | [`mojo/p/posit8_rational_encoder.mojo`](../../../mojo/p/posit8_rational_encoder.mojo) |
| Nim | [`nim/p/posit8_rational_encoder.nim`](../../../nim/p/posit8_rational_encoder.nim) |
| Odin | [`odin/p/posit8_rational_encoder.odin`](../../../odin/p/posit8_rational_encoder.odin) |
| Rust | [`rust/p/posit8_rational_encoder.rs`](../../../rust/p/posit8_rational_encoder.rs) |
| V | [`v/p/posit8_rational_encoder.v`](../../../v/p/posit8_rational_encoder.v) |
| Zig | [`zig/p/posit8_rational_encoder.zig`](../../../zig/p/posit8_rational_encoder.zig) |
