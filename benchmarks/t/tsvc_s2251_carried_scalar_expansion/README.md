# TSVC s2251 carried-scalar expansion

This package is a clean-room one-sweep profile of the Expansion s2251 loop-carried scalar kernel. The exported symbol is tsvc_s2251_carried_scalar_expansion and the ABI is float64_slice_io.

Input is [n,A[n],B[n],C[n],D[n],E[n]], n in 1..64; all values are integer-valued binary64 values in [-1,1]. A is validated but overwritten before reading. Initialize s=0 and, in ascending i, preserve the source order: A[i]=s*E[i]; s=B[i]+C[i] using old B; B[i]=A[i]+D[i]. Output final A followed by final B, length 2n. The carried scalar stays in [-2,2], A in [-2,2], and final B in [-3,3]; all are exactly representable in binary32/binary64. Inputs are unchanged. Invalid input returns -1; null output or capacity below 2n returns -2 without writes. Input validation precedes output validation.

This profiles one loop-body sweep with explicit arrays. Launcher timing, repeated passes, and shared global initialization are excluded.

Source: lac-dcc/Benchmarks commit 5d7b75df749241efa7a6e6f5be613d3fcc5cce38, TSVC/tsc.inc codelet s2251, selected by Expansion-dbl and Expansion-flt. The source comments attribute codelets to David Callahan, Jack Dongarra, and David Levine. No explicit license grant was found in the pinned materials reviewed; ports are clean-room and claim no upstream license. See LICENSE.txt. Oracle: benchmarks/tsvc_s2251_carried_scalar_expansion_oracle.py.

Ports exist in C, C3, C++, Elisa, Nim, Odin, Rust, V, and Zig under their respective t/ directories.
