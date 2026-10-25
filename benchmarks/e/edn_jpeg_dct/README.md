# Embench EDN fixed-point JPEG DCT

This package isolates EDN's `jpegdct`: a separable, two-pass 8×8 fixed-point forward cosine transform. Each one-dimensional pass uses the source's butterfly sums/differences, its stage-specific right shifts, the 12 caller-supplied fixed-point factors, and the same intermediate signed-16-bit narrowing points. The first pass transforms rows (`k=1`, shifts 0/13); the second transforms columns (`k=8`, shifts 3/16).

Input is 64 row-major signed coefficients followed by 12 signed factors. Coefficients are bounded to `[-8,8]` and factors to `[-32,31]`, keeping all source short casts in range while exercising the complete factorized transform. Output is the transformed 8×8 signed block as 64 little-endian i64 words. Invalid input returns `-1`; insufficient/null capacity returns `-2` before writes.

This is a fixed-point fast 2D forward JPEG DCT kernel. It differs from the local picojpeg inverse DCT decoder stage and from MFCC's direct orthonormal DCT-II over one-dimensional filter-energy vectors. The package does not reproduce EDN's shared benchmark arrays, other DSP kernels, or harness.

Pinned source is `jpegdct` in [`src/edn/libedn.c`](https://github.com/embench/embench-iot/blob/09c2ed8c3b7008c95d08b038de4a3f6dc103ed70/src/edn/libedn.c), at commit `09c2ed8c3b7008c95d08b038de4a3f6dc103ed70`. The source is GPL-3.0-or-later and records WCET Benchmarks provenance and Björn Lisper's email permission to license under GPL. Full text and attribution are in [`LICENSE.txt`](LICENSE.txt) and [`NOTICE.txt`](NOTICE.txt).

Fixtures are in [`workload.json`](workload.json); an independent oracle is [`benchmarks/edn_jpeg_dct_oracle.py`](../../edn_jpeg_dct_oracle.py). These files specify the profile and do not claim runtime verification.
