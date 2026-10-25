# FreeBench Pifft

This package provides a bounded, clean-room profile of FreeBench `pifft`, a
benchmark whose main computation estimates π with an FFT-accelerated modified
arithmetic-geometric-mean iteration.

## Bounded contract

- ABI: scalar signed 64-bit input and output; exported symbol
  `freebench_pifft`.
- The sole valid input is `nfft = 8`. The pinned program rounds its input up to
  a power of two; this profile fixes the transform size to eight to bound work.
  Other inputs return `-1`.
- Each port runs the source's modified AGM initialization, its iterative
  geometric/arithmetic update, and the source's final π expression. The loop
  stops when the fixed-point residual is at most one micro-unit or after eight
  rounds.
- Multiplication decomposes values into base-1000 limbs, performs an
  eight-point radix-2 FFT convolution, reconstructs the integer product, and
  rounds back to six fractional decimal places. Square root and division use
  bounded integer fixed-point operations.
- Return π rounded half-up to milli-units; `3142` represents `3.142`. Invalid
  inputs return `-1`.
- This is a reduced precision workload, not a reproduction of the launcher's
  16,384-point test or 1,048,576-point reference profile. The reduced precision
  and fixed-point arithmetic make the result deterministic across the nine
  language ports while retaining the FFT-multiplication/AGM computation.
- The existing `gauss_legendre` package also computes π with an AGM recurrence,
  but uses ordinary binary64 multiplication. This profile is kept for the
  FFT-convolution multiplication workload; its FFT operations alone are not a
  repeat of the standalone transform package.
- The Python oracle evaluates the same fixed-point recurrence with exact
  integer multiplication instead of FFT convolution.

## Provenance and rights

The pinned `pifft.c` header attributes the program to T. Ooura and describes
the FFT-based multiple-precision calculation. Neither `pifft.c` nor the pinned
`fftsg.c` header contains an explicit license grant, and the package has no
separate license file. No upstream license is inferred. The ports and oracle
are independently written from the published AGM equations and observed
behavior; they do not copy upstream source code or comments.

- [Pinned `pifft.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/pifft/pifft.c)
- [Pinned `fftsg.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/pifft/fftsg.c)
- [Pinned `info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/pifft/info.sh)
- [Pinned `test.in`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/pifft/test.in)
- [Pinned `ref.in`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/pifft/ref.in)
- [Pinned reference output](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/pifft/pifft.reference_output)

## Language ports

| Language | Source |
| --- | --- |
| C | [c/f/freebench_pifft.c](../../../c/f/freebench_pifft.c) |
| C3 | [c3/f/freebench_pifft.c3](../../../c3/f/freebench_pifft.c3) |
| C++ | [cpp/f/freebench_pifft.cpp](../../../cpp/f/freebench_pifft.cpp) |
| Elisa | [elisa/f/freebench_pifft.elisa](../../../elisa/f/freebench_pifft.elisa) |
| Nim | [nim/f/freebench_pifft.nim](../../../nim/f/freebench_pifft.nim) |
| Odin | [odin/f/freebench_pifft.odin](../../../odin/f/freebench_pifft.odin) |
| Rust | [rust/f/freebench_pifft.rs](../../../rust/f/freebench_pifft.rs) |
| V | [v/f/freebench_pifft.v](../../../v/f/freebench_pifft.v) |
| Zig | [zig/f/freebench_pifft.zig](../../../zig/f/freebench_pifft.zig) |
