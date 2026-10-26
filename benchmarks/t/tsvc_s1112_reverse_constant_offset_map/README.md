# TSVC s1112 reverse constant-offset map

This clean-room bounded profile preserves the s1112 loop's descending index
order and computes `A[i] = B[i] + 1` for every index. The operation is an
elementwise constant-offset map; A's incoming values are overwritten and B is
read-only. It is not the shifted neighbor update in s112.

## Contract

Export `tsvc_s1112_reverse_constant_offset_map` with `i64_array_bytes_output`.
Input is `[n, A[n], B[n]]`, n=1..64, and both input arrays use values in
[-2,2]. The function visits i from n-1 down to 0 and writes final A as
little-endian signed i64; success returns n. Invalid input returns -1; null
output or capacity below `8*n` returns -2 without writes. All results remain
exact in binary32 and binary64.

See the independent [oracle](../../tsvc_s1112_reverse_constant_offset_map_oracle.py)
and [workload](workload.json).

## Source and rights

Pinned source is s1112 in `TSVC/tsc.inc`, lines 924–948, at LAC-DCC
[`Benchmarks` commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/tsc.inc#L924). The launcher is `TSVC/LinearDependence-dbl/info.sh` (`3570 14`; float uses `3570 5`). It initializes then overwrites A in descending order. TSVC comments attribute codelets to David Callahan, Jack Dongarra, and David Levine.

No explicit redistribution grant was found in the pinned repository material reviewed. The nine ports independently implement the bounded operation and copy no source code or comments; no upstream license or endorsement is claimed. See [LICENSE.txt](LICENSE.txt).
