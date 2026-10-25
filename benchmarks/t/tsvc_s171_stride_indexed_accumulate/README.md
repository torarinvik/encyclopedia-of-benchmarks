# TSVC s171 stride-indexed accumulation

This package is a bounded, clean-room one-sweep profile of TSVC s171 in the
Symbolics-dbl family. The loop updates one affine destination per input item:
A[i*stride] receives its previous value plus B[i]. Positive strides make
destinations unique; slots between those destinations pass through unchanged.

## Contract

The exported function is tsvc_s171_stride_indexed_accumulate and uses the
i64_array_bytes_output ABI.

- Input is [n, stride, A[a_length], B[n]], where n is 1..32, stride is 1..4,
  and a_length is 1 + (n - 1) * stride.
- A and B values are in [-8,8]. The result remains an exact signed i64.
- Visit i from zero upward and apply A[i*stride] += B[i].
- Emit the full final A span as little-endian signed i64 values. Return a_length;
  required capacity is 8*a_length bytes. The input buffer is unchanged.
- Malformed input returns -1. Null output or insufficient capacity returns -2
  without writing.

The pinned launcher calls s171 with inc=1. This package keeps the source's
parameterized affine subscript and also includes strides 2 through 4 so the
indexed-write pattern is measurable. It profiles one loop-body pass and omits
the source's timing repetitions, initialization, dummy call, and checksum.

## Source and rights

The source reference is s171 at lines 1666–1687 of
[TSVC/tsc.inc](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L1666),
pinned to LAC-DCC Benchmarks commit
5d7b75df749241efa7a6e6f5be613d3fcc5cce38. Its initialization is at lines
331–333 and its launcher is
[TSVC/Symbolics-dbl/tsc.c](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Symbolics-dbl/tsc.c).
TSVC comments attribute its non-four-digit codelets to David Callahan, Jack
Dongarra, and David Levine, Test Suite for Vectorizing Compilers.

No explicit license grant was found in the pinned TSVC source or repository
material reviewed. These ports independently implement the bounded operation
and reuse no upstream source code or comments. No upstream license or
endorsement is claimed; see [LICENSE.txt](LICENSE.txt).

The independent oracle and fixed workload are
[tsvc_s171_stride_indexed_accumulate_oracle.py](../../tsvc_s171_stride_indexed_accumulate_oracle.py)
and [workload.json](workload.json).

## Ports

| Language | Port |
|---|---|
| C | [tsvc_s171_stride_indexed_accumulate.c](../../../c/t/tsvc_s171_stride_indexed_accumulate.c) |
| C3 | [tsvc_s171_stride_indexed_accumulate.c3](../../../c3/t/tsvc_s171_stride_indexed_accumulate.c3) |
| C++ | [tsvc_s171_stride_indexed_accumulate.cpp](../../../cpp/t/tsvc_s171_stride_indexed_accumulate.cpp) |
| Elisa | [tsvc_s171_stride_indexed_accumulate.elisa](../../../elisa/t/tsvc_s171_stride_indexed_accumulate.elisa) |
| Nim | [tsvc_s171_stride_indexed_accumulate.nim](../../../nim/t/tsvc_s171_stride_indexed_accumulate.nim) |
| Odin | [tsvc_s171_stride_indexed_accumulate.odin](../../../odin/t/tsvc_s171_stride_indexed_accumulate.odin) |
| Rust | [tsvc_s171_stride_indexed_accumulate.rs](../../../rust/t/tsvc_s171_stride_indexed_accumulate.rs) |
| V | [tsvc_s171_stride_indexed_accumulate.v](../../../v/t/tsvc_s171_stride_indexed_accumulate.v) |
| Zig | [tsvc_s171_stride_indexed_accumulate.zig](../../../zig/t/tsvc_s171_stride_indexed_accumulate.zig) |
