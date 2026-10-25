# cBench JPEG 2x2 fancy upsampling

This package isolates IJG's `h2v2_fancy_upsample` component-plane kernel from
the pinned cBench `consumer_jpeg_d` source. It performs 2x horizontal and
vertical triangle-filter interpolation on 8-bit samples and emits the entire
expanded plane.

## Contract

The `i64_array_bytes_output` input is `[width, height, samples...]`, followed
by exactly `width * height` row-major component samples. Width is 3–16, height
is 1–8, and every sample is 0–255. Each source input row produces two output
rows; each input sample column produces two output columns. The output is a
row-major byte plane of dimensions `2 * width` by `2 * height`, at most 512
bytes.

For each input row and each of its two output rows, the source first forms
`S[x] = 3 * near[x] + far[x]`, where `near` is the current input row and
`far` is the adjacent row above or below. The output uses the source's explicit
left/right boundary formulas and interior weights (overall 9/16, 3/16, 3/16,
1/16), including its distinct `+8` and `+7` rounding biases before a
four-bit arithmetic shift. At the top and bottom of the bounded plane, the
missing context row repeats the nearest image row. This supplies the
context-row behavior expected by the IJG upsampler without modeling its JPEG
buffer controller.

Malformed input returns `-1`. A null output pointer or insufficient capacity
returns `-2`; output is staged so errors do not modify caller memory.

This benchmark covers only the 2x2 fancy sample expansion. It excludes JPEG
parsing, component selection, context-buffer management, other sampling
ratios, color conversion, inverse DCT, and image/file handling. It is distinct
from [`mibench_jpeg_ycbcr_to_rgb`](../mibench_jpeg_ycbcr_to_rgb/README.md),
which converts already aligned YCbCr samples into RGB and performs no spatial
upsampling, and from [`picojpeg`](../../p/picojpeg/README.md), whose bounded profile
decodes grayscale JPEG blocks.

## Provenance and rights

Source: [`cBench/consumer_jpeg_d/src/jdsample.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/consumer_jpeg_d/src/jdsample.c),
symbol `h2v2_fancy_upsample`, pinned at commit
[`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38).
The launcher is `cBench/consumer_jpeg_d/src/info.sh`: it compiles the `*.c`
sources with `-lm` and supplies no run options. The pinned source identifies
Thomas G. Lane's IJG software and refers to the IJG README for terms. These
ports are independently written; they do not copy the implementation. This
README and [LICENSE.txt](LICENSE.txt) retain the IJG copyright/no-warranty
notice and permission conditions. The local adaptation and its edge-context
contract are documented above, as required by the source terms.

The full IJG notice is included in [LICENSE.txt](LICENSE.txt). In particular,
the software is provided without warranty or liability, source distributions
must retain the notice and document changes, and IJG names may not be used in
advertising.

## Workload and oracle

[`workload.json`](workload.json) covers source rounding at both horizontal
edges and interior columns, vertical neighbor context, replicated image-edge
rows, malformed dimensions/sample values, and output-capacity failures. The
independent oracle is
[`cbench_consumer_jpeg_h2v2_fancy_upsample_oracle.py`](../../cbench_consumer_jpeg_h2v2_fancy_upsample_oracle.py).

| Language | Port |
| --- | --- |
| C | [`c/cbench_consumer_jpeg_h2v2_fancy_upsample.c`](../../../c/c/cbench_consumer_jpeg_h2v2_fancy_upsample.c) |
| C3 | [`c3/cbench_consumer_jpeg_h2v2_fancy_upsample.c3`](../../../c3/c/cbench_consumer_jpeg_h2v2_fancy_upsample.c3) |
| C++ | [`cpp/cbench_consumer_jpeg_h2v2_fancy_upsample.cpp`](../../../cpp/c/cbench_consumer_jpeg_h2v2_fancy_upsample.cpp) |
| Elisa | [`elisa/cbench_consumer_jpeg_h2v2_fancy_upsample.elisa`](../../../elisa/c/cbench_consumer_jpeg_h2v2_fancy_upsample.elisa) |
| Nim | [`nim/cbench_consumer_jpeg_h2v2_fancy_upsample.nim`](../../../nim/c/cbench_consumer_jpeg_h2v2_fancy_upsample.nim) |
| Odin | [`odin/cbench_consumer_jpeg_h2v2_fancy_upsample.odin`](../../../odin/c/cbench_consumer_jpeg_h2v2_fancy_upsample.odin) |
| Rust | [`rust/cbench_consumer_jpeg_h2v2_fancy_upsample.rs`](../../../rust/c/cbench_consumer_jpeg_h2v2_fancy_upsample.rs) |
| V | [`v/cbench_consumer_jpeg_h2v2_fancy_upsample.v`](../../../v/c/cbench_consumer_jpeg_h2v2_fancy_upsample.v) |
| Zig | [`zig/cbench_consumer_jpeg_h2v2_fancy_upsample.zig`](../../../zig/c/cbench_consumer_jpeg_h2v2_fancy_upsample.zig) |

## Upstream notice

The complete upstream IJG copyright and distribution notice is reproduced
below and in [LICENSE.txt](LICENSE.txt). It is a permission notice with
conditions, not a claim that the source is MIT- or BSD-licensed.

```text
This software is based in part on the work of the Independent JPEG Group.

LEGAL ISSUES

The authors make NO WARRANTY or representation, either express or implied,
with respect to this software, its quality, accuracy, merchantability, or
fitness for a particular purpose. This software is provided "AS IS", and you,
its user, assume the entire risk as to its quality and accuracy.

This software is copyright (C) 1991-1998, Thomas G. Lane. All Rights Reserved
except as specified below.

Permission is hereby granted to use, copy, modify, and distribute this
software (or portions thereof) for any purpose, without fee, subject to these
conditions:
(1) If any part of the source code for this software is distributed, then
    this README file must be included, with this copyright and no-warranty
    notice unaltered; and any additions, deletions, or changes to the original
    files must be clearly indicated in accompanying documentation.
(2) If only executable code is distributed, then the accompanying
    documentation must state that "this software is based in part on the work
    of the Independent JPEG Group".
(3) Permission for use of this software is granted only if the user accepts
    full responsibility for any undesirable consequences; the authors accept
    NO LIABILITY for damages of any kind.

These conditions apply to any software derived from or based on the IJG code,
not just to the unmodified library. If you use our work, you ought to
acknowledge us.

Permission is NOT granted for the use of any IJG author's name or company name
in advertising or publicity relating to this software or products derived from
it. This software may be referred to only as "the Independent JPEG Group's
software".

We specifically permit and encourage the use of this software as the basis of
commercial products, provided that all warranty or liability claims are
assumed by the product vendor.
```
