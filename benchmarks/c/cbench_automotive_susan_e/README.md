# cBench automotive_susan_e (edges)

This package ports the pinned cBench SUSAN edges mode selected by its `-e` dataset commands. It is distinct from SUSAN smoothing: `-c` calls `susan_corners`, and `-e` calls `susan_edges` followed by thinning. The cBench `automotive_susan_s` mode is represented by the existing MiBench smoothing package.

## Bounded contract

The ABI accepts `[side, row-major grayscale pixels...]`, with square side 11–16 and byte-valued pixels. It returns `side*side` and writes the source output image's grayscale pixel plane as raw bytes; the source's P5 header is intentionally left outside the ABI. Invalid input returns -1; null output or insufficient output capacity returns -2 without writes.

For each 37-site mask point, the source builds a sixth-power brightness response using threshold 20 and keeps SUSAN areas at most 2650. It computes edge direction and local maxima, applies the source's one-pass topology-preserving thinning, then the default drawer paints a white 3×3 neighborhood with a black center pixel.

The 11–16 square restriction is the harness's fixed-workload bound; the original PGM program accepts general image dimensions. The 37-site scan reads only valid in-image neighbors, leaves borders unchanged, and draws default markers inside the scanned region.

## Provenance and rights

- Source: [`cBench/automotive_susan_e/src/susan.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/automotive_susan_e/src/susan.c), symbol `susan_edges`, pinned to `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`.
- Launcher: [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/automotive_susan_e/src/info.sh); dataset launcher: [`_ccc_run`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/automotive_susan_e/src/_ccc_run); mode command recorded in `_ccc_info_datasets` uses `-e`.
- License notice: [`LICENSE`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/automotive_susan_e/LICENSE).

The pinned source is research-only, must not be sold, and must not be passed on without retaining its header. This package and every port preserve the full notice below and are restricted to research use; they are not for sale.

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

The cBench license file also states:

```text
This code is issued for research purposes only and remains the
property of the UK Secretary of State for Defence. This code must not
be passed on without this header information being kept
intact. This code must not be sold.

A UK patent has been granted: "Method for digitally processing
images to determine the position of edges and/or corners therein for
guidance of unmanned vehicle", UK Patent 2272285. Proprietor:
Secretary of State for Defence, UK. 15 January 1997


Source Code obtained from:

http://www.fmrib.ox.ac.uk/~steve/susan/index.html
```

## Ports

| Language | File |
|---|---|
| C | [`c/c/cbench_automotive_susan_e.c`](../../../c/c/cbench_automotive_susan_e.c) |
| C3 | [`c3/c/cbench_automotive_susan_e.c3`](../../../c3/c/cbench_automotive_susan_e.c3) |
| C++ | [`cpp/c/cbench_automotive_susan_e.cpp`](../../../cpp/c/cbench_automotive_susan_e.cpp) |
| Elisa | [`elisa/c/cbench_automotive_susan_e.elisa`](../../../elisa/c/cbench_automotive_susan_e.elisa) |
| Nim | [`nim/c/cbench_automotive_susan_e.nim`](../../../nim/c/cbench_automotive_susan_e.nim) |
| Odin | [`odin/c/cbench_automotive_susan_e.odin`](../../../odin/c/cbench_automotive_susan_e.odin) |
| Rust | [`rust/c/cbench_automotive_susan_e.rs`](../../../rust/c/cbench_automotive_susan_e.rs) |
| V | [`v/c/cbench_automotive_susan_e.v`](../../../v/c/cbench_automotive_susan_e.v) |
| Zig | [`zig/c/cbench_automotive_susan_e.zig`](../../../zig/c/cbench_automotive_susan_e.zig) |

- Independent package oracle: [`cbench_automotive_susan_e_oracle.py`](../../cbench_automotive_susan_e_oracle.py)
- Harness contract: [`workload.json`](workload.json)

