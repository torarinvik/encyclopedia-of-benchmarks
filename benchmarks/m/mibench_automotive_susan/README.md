# MiBench automotive-susan

This package implements only the `-s` smoothing mode selected by the pinned
MiBench launcher. It uses the source defaults: brightness threshold 20,
distance threshold 4.0, and a 15-by-15 Gaussian spatial mask. The PGM file handling,
edge detector, corner detector, and command-line interface are outside this
bounded profile.

## Bounded contract

The `mibench_automotive_susan` ABI accepts `[side, row-major grayscale
pixels...]`. The side must be 15 or 16, which fits the source mask and caps the
image at 256 pixels. Pixels are in `0..255`. Success returns the number of
output bytes and writes one filtered grayscale byte per input pixel. Invalid
framing or pixels return `-1`; null output or insufficient capacity returns
`-2` without writes.

The SUSAN smoother forms a brightness lookup from
`100*exp(-((difference/20)^2))`, multiplies it by the distance mask
`100*exp(-((dx^2+dy^2)/16))`, removes the center pixel's fixed 10000 weight,
and returns the integer weighted mean of the remaining USAN. When no other
pixel contributes, it falls back to the median of the eight adjacent pixels.
The image border follows `enlarge` in the source, reflecting with edge
repetition (`-1` maps to `0`; `side` maps to `side-1`).

## Source rights and required notice

The pinned source provides no separate license file. Its in-file notice says
the code is for research purposes only, remains Crown property, must not be
sold, and must not be passed on without the header information kept intact.
This package preserves the complete notice in every port. The same restriction
applies to these ports and their redistribution; this package is for research
use and is not for sale.

```text
/**********************************************************************\
  SUSAN Version 2l by Stephen Smith
  Oxford Centre for Functional Magnetic Resonance Imaging of the Brain,
  Department of Clinical Neurology, Oxford University, Oxford, UK
  (Previously in Computer Vision and Image Processing Group - now
  Computer Vision and Electro Optics Group - DERA Chertsey, UK)
  Email:    steve@fmrib.ox.ac.uk
  WWW:      http://www.fmrib.ox.ac.uk/~steve
  (C) Crown Copyright (1995-1999), Defence Evaluation and Research Agency,
  Farnborough, Hampshire, GU14 6TD, UK
  DERA WWW site:
  http://www.dera.gov.uk/
  DERA Computer Vision and Electro Optics Group WWW site:
  http://www.dera.gov.uk/imageprocessing/dera/group_home.html
  DERA Computer Vision and Electro Optics Group point of contact:
  Dr. John Savage, jtsavage@dera.gov.uk, +44 1344 633203
  A UK patent has been granted: "Method for digitally processing
  images to determine the position of edges and/or corners therein for
  guidance of unmanned vehicle", UK Patent 2272285. Proprietor:
  Secretary of State for Defence, UK. 15 January 1997

  This code is issued for research purposes only and remains the
  property of the UK Secretary of State for Defence. This code must
  not be passed on without this header information being kept
  intact. This code must not be sold.
\**********************************************************************/
```

## Provenance

- Launcher: [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/automotive-susan/info.sh)
- Core: [`susan.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/automotive-susan/susan.c), SUSAN v2l by Stephen Smith, pinned to `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`
- Workload: [`workload.json`](workload.json)
- Independent oracle: [`mibench_automotive_susan_oracle.py`](../../mibench_automotive_susan_oracle.py)
- Algorithm reference: Smith and Brady, “SUSAN - A New Approach to Low Level Image Processing,” *International Journal of Computer Vision* 23(1), 1997.

## Ports

| Language | Port |
|---|---|
| C | [`c/m/mibench_automotive_susan.c`](../../../c/m/mibench_automotive_susan.c) |
| C3 | [`c3/m/mibench_automotive_susan.c3`](../../../c3/m/mibench_automotive_susan.c3) |
| C++ | [`cpp/m/mibench_automotive_susan.cpp`](../../../cpp/m/mibench_automotive_susan.cpp) |
| Elisa | [`elisa/m/mibench_automotive_susan.elisa`](../../../elisa/m/mibench_automotive_susan.elisa) |
| Nim | [`nim/m/mibench_automotive_susan.nim`](../../../nim/m/mibench_automotive_susan.nim) |
| Odin | [`odin/m/mibench_automotive_susan.odin`](../../../odin/m/mibench_automotive_susan.odin) |
| Rust | [`rust/m/mibench_automotive_susan.rs`](../../../rust/m/mibench_automotive_susan.rs) |
| V | [`v/m/mibench_automotive_susan.v`](../../../v/m/mibench_automotive_susan.v) |
| Zig | [`zig/m/mibench_automotive_susan.zig`](../../../zig/m/mibench_automotive_susan.zig) |
