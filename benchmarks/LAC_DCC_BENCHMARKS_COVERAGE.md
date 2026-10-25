# lac-dcc/Benchmarks launcher crosswalk

This inventory maps all 273 launcher records from `/tmp/lac-dcc-benchmarks-info-full.tsv` to local benchmark packages conservatively. Upstream paths are linked at pinned commit [5d7b75df749241efa7a6e6f5be613d3fcc5cce38](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38); its root tree SHA is `4ecc50e54cbf265d2803deb53e9c3badd004893b`. The snapshot is the complete 273-record inventory.

A matching name alone is not evidence of coverage. “Exact local semantic match” means the local package implements the same core operation for its supported input domain. “Partial/related” records an inspected overlap with a material contract or algorithm difference. “Newly implemented in this batch” means a local package and source-backed contract are present; this document does not claim runtime validation. All other rows remain pending source/semantic review and, where needed, implementation.

## Reviewed crosswalk

| Upstream launcher path | Executable | Status | Local package / reason |
|---|---|---|---|
| `BenchmarkGame/fannkuch/info.sh` | `fannkuch` | Newly implemented in this batch | [`fannkuch`](f/fannkuch/README.md): bounded counter-driven prefix-reversal maximum. |
| `BenchmarkGame/n-body/info.sh` | `nbody` | Newly implemented in this batch | [`benchmarkgame_nbody`](b/benchmarkgame_nbody/README.md): bounded classic five-body 3D integration and initial/final energy outputs. |
| `BenchmarkGame/nsieve-bits/info.sh` | `nsieve-bits` | Partial/related | [`sieve_of_eratosthenes`](s/sieve_of_eratosthenes/README.md) already implements the same prime sieve; packed-bit storage and three bounds are source-specific representation and workload details, not a distinct algorithm. |
| `BenchmarkGame/partialsums/info.sh` | `partialsums` | Newly implemented in this batch | [`partialsums`](p/partialsums/README.md): nine sums in source order, bounded to `n<=10000`. |
| `BenchmarkGame/puzzle/info.sh` | `puzzle` | Newly implemented in this batch | [`benchmarkgame_puzzle`](b/benchmarkgame_puzzle/README.md): deterministic array generation, shuffle, and XOR cancellation. |
| `BenchmarkGame/recursive/info.sh` | `recursive` | Newly implemented in this batch | [`benchmarkgame_recursive`](b/benchmarkgame_recursive/README.md): all five source-ordered recursive outputs, including floating-point Fibonacci and Takeuchi, with bounded `n`. |
| `BenchmarkGame/spectral-norm/info.sh` | `spectral-norm` | Newly implemented in this batch | [`spectral_norm`](s/spectral_norm/README.md): ten paired `AᵀA` multiplications on the implicit source matrix. |
| `BitBench/drop3/info.sh` | `drop3` | Newly implemented in this batch | [`drop3`](d/drop3/README.md): bounded 3-bit stream filtering with the source offset schedule and 20 passes. |
| `BitBench/uuencode/info.sh` | `uuencode` | Newly implemented in this batch | [`uuencode`](u/uuencode/README.md): bounded source-order uuencoding with the fixed header, 45-byte lines, and exact output framing. |
| `BitBench/uudecode/info.sh` | `uudecode` | Newly implemented in this batch | [`uudecode`](u/uudecode/README.md): bounded fixed-header stream decoder with source-order line groups and exact terminator. |
| `BitBench/five11/info.sh` | `five11` | Newly implemented in this batch | [`five11`](f/five11/README.md): bounded MSB-first packet parsing, 11-bit channel sum, and source repetition count. |
| `CoyoteBench/almabench/info.sh` | `almabench` | Newly implemented in this batch | [`almabench`](a/almabench/README.md): bounded eight-planet ephemeris output with source-compatible `fmod` angle normalization and six-decimal formatting. |
| `CoyoteBench/huffbench/info.sh` | `huffbench` | Newly implemented in this batch | [`huffbench`](h/huffbench/README.md): bounded source-seeded Huffman compression and round-trip decompression with packed-size and decoded-checksum output; source declares the implementation public domain. |
| [`CoyoteBench/lpbench/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/CoyoteBench/lpbench/info.sh) | `lpbench` | Partial/related | [`linpack_lu_solve`](l/linpack_lu_solve/README.md) already covers the pivoted `dgefa` factorization and `dgesl` solve; LPBench's matrix generation, size, and timing wrapper are workload details. |
| [`Linpack/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Linpack/info.sh) | `Linpack` | Partial/related | [`linpack_lu_solve`](l/linpack_lu_solve/README.md) already covers the pivoted `dgefa` factorization and `dgesl` solve; this launcher keeps the broader classic LINPACK matrix-size and reporting profile. |
| `PolyBench/linear-algebra/blas/gesummv/info.sh` | `gesummv` | Newly implemented in this batch | [`gesummv`](g/gesummv/README.md): source-ordered matrix-vector combination and output reduction. |
| `PolyBench/linear-algebra/blas/gemm/info.sh` | `gemm` | Newly implemented in this batch | [`gemm`](g/gemm/README.md): bounded source-ordered alpha/beta matrix multiplication and row-major reduction. |
| `PolyBench/linear-algebra/blas/gemver/info.sh` | `gemver` | Newly implemented in this batch | [`gemver`](g/gemver/README.md): four ordered matrix/vector update passes and final vector reduction. |
| `PolyBench/linear-algebra/blas/syrk/info.sh` | `syrk` | Newly implemented in this batch | [`syrk`](s/syrk/README.md): bounded source-ordered lower-triangle rank-k update returning the full matrix. |
| `PolyBench/linear-algebra/blas/syr2k/info.sh` | `syr2k` | Newly implemented in this batch | [`syr2k`](s/syr2k/README.md): bounded source-ordered lower-triangle rank-2k update returning the full matrix. |
| `PolyBench/linear-algebra/blas/symm/info.sh` | `symm` | Newly implemented in this batch | [`polybench_symm`](p/polybench_symm/README.md): bounded source-ordered symmetric matrix multiplication update and row-major reduction. |
| `PolyBench/linear-algebra/kernels/atax/info.sh` | `atax` | Newly implemented in this batch | [`atax`](a/atax/README.md): bounded source-ordered ATAX matrix-vector and transpose accumulation. |
| `PolyBench/linear-algebra/kernels/bicg/info.sh` | `bicg` | Newly implemented in this batch | [`bicg`](b/bicg/README.md): source-ordered biconjugate-gradient matrix-vector reductions with both live-out vectors. |
| `PolyBench/linear-algebra/kernels/2mm/info.sh` | `2mm` | Newly implemented in this batch | [`2mm`](0-9/2mm/README.md): bounded source-ordered two-stage matrix multiplication and row-major reduction. |
| `PolyBench/linear-algebra/kernels/3mm/info.sh` | `3mm` | Newly implemented in this batch | [`3mm`](0-9/3mm/README.md): bounded source-ordered three-stage matrix multiplication and row-major reduction. |
| `PolyBench/datamining/covariance/info.sh` | `covariance` | Newly implemented in this batch | [`covariance`](c/covariance/README.md): bounded source-ordered mean, centering, symmetric covariance, and matrix reduction. |
| `PolyBench/linear-algebra/kernels/doitgen/info.sh` | `doitgen` | Newly implemented in this batch | [`doitgen`](d/doitgen/README.md): bounded source-ordered 3D tensor transform with slice buffering and row-major reduction. |
| `PolyBench/linear-algebra/solvers/cholesky/info.sh` | `cholesky` | Newly implemented in this batch | [`polybench_cholesky`](p/polybench_cholesky/README.md): bounded source-ordered lower Cholesky factorization and lower-triangle reduction. |
| `PolyBench/linear-algebra/solvers/ludcmp/info.sh` | `ludcmp` | Newly implemented in this batch | [`polybench_ludcmp`](p/polybench_ludcmp/README.md): bounded source-ordered no-pivot LU factorization and triangular solves. |
| `PolyBench/linear-algebra/solvers/durbin/info.sh` | `durbin` | Newly implemented in this batch | [`durbin`](d/durbin/README.md): bounded source-ordered Durbin coefficient recurrence. |
| `PolyBench/linear-algebra/solvers/trisolv/info.sh` | `trisolv` | Newly implemented in this batch | [`trisolv`](t/trisolv/README.md): bounded source-ordered lower-triangular solve. |
| `PolyBench/stencils/jacobi-1d/info.sh` | `jacobi-1d` | Newly implemented in this batch | [`jacobi_1d`](j/jacobi_1d/README.md): bounded source-ordered two-array 1D Jacobi stencil. |
| `PolyBench/stencils/jacobi-2d/info.sh` | `jacobi-2d` | Newly implemented in this batch | [`jacobi_2d`](j/jacobi_2d/README.md): bounded source-ordered two-array 2D Jacobi stencil. |
| `PolyBench/medley/deriche/info.sh` | `deriche` | Newly implemented in this batch | [`deriche`](d/deriche/README.md): bounded recursive f32 image filter with row-major checksum output. |
| `PolyBench/linear-algebra/kernels/mvt/info.sh` | `mvt` | Newly implemented in this batch | [`mvt`](m/mvt/README.md): source-ordered matrix-vector and transposed matrix-vector updates. |
| `Misc/revertBits/info.sh` | `revertBits` | Newly implemented in this batch | [`revert_bits`](r/revert_bits/README.md): paired 32-bit and 64-bit bit-reversal operations with little-endian byte output. |
| `Misc/matmul_f64_4x4/info.sh` | `matmul_f64_4x4` | Newly implemented in this batch | [`matmul_f64_4x4`](m/matmul_f64_4x4/README.md): bounded unrolled 4×4 double-precision matrix product. |
| `Misc/fp-convert/info.sh` | `misc_fp_convert` | Newly implemented in this batch | [`misc_fp_convert`](m/misc_fp_convert/README.md): bounded float32 vector conversion and float64 dot-product accumulation. |
| `Misc/dt/info.sh` | `misc_dt` | Newly implemented in this batch | [`misc_dt`](m/misc_dt/README.md): repeated elementwise array division with float32 trigonometric initialization, distinct from local multiply and STREAM kernels. |
| `Misc/perlin/info.sh` | `improved_perlin_noise_3d` | Newly implemented in this batch | [`improved_perlin_noise_3d`](i/improved_perlin_noise_3d/README.md): fixed-permutation 3D gradient noise, distinct from the local seeded 2D value-noise package. |
| [`Misc/himenobmtxpa/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/himenobmtxpa/info.sh) | `himenobmtxpa` | Newly implemented in this batch | [`himenobmtxpa`](h/himenobmtxpa/README.md): bounded binary32 weighted point-Jacobi relaxation for the 3D Poisson pressure equation, returning final residual sum; distinct from the 2D Jacobi stencil and 3D heat-diffusion kernel. |
| `Misc/evalloop/info.sh` | `evalloop` | Newly implemented in this batch | [`evalloop`](e/evalloop/README.md): bounded source opcode stream evaluation with uint32 accumulation and exact stdout bytes. |
| [`Misc/salsa20/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/salsa20/info.sh) | `salsa20` | Partial/related | [`salsa`](s/salsa/README.md) already implements the same 16-word Salsa core and ten double rounds; the counter-based PRNG wrapper is not a distinct core algorithm. |
| `Misc/ReedSolomon/info.sh` | `ReedSolomon` | Newly implemented in this batch | [`misc_reed_solomon`](m/misc_reed_solomon/README.md): bounded shortened RS(204,188) encoding and zero/one-symbol error correction with source-compatible GF(256) arithmetic. |
| [`Misc/mandel/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/mandel/info.sh) | `mandel` | Partial/related | [`mandelbrot`](m/mandelbrot/README.md) already implements the same `z = z*z + c` escape-time recurrence. This launcher samples a 500×500 grid for ten iterations and reduces the final complex values to one integer, so it is not added as a separate algorithm package. |
| [`Misc/mandel-2/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/mandel-2/info.sh) | `mandel-2` | Partial/related | [`mandelbrot`](m/mandelbrot/README.md) already implements the same Mandelbrot escape-time recurrence. This launcher uses a fixed 78×78 grid, a 65,536-iteration limit, and ASCII output; it is treated as another rendering profile rather than a separate algorithm. |
| `McGill/misr/info.sh` | `misr` | Newly implemented in this batch | [`mcgill_misr`](m/mcgill_misr/README.md): bounded ten-vector MISR simulation with source-seeded `lrand48` and exact two-line report. |
| `PolyBench/linear-algebra/solvers/gramschmidt/info.sh` | `gramschmidt` | Partial/related | [`gram_schmidt`](g/gram_schmidt/README.md): same method, but matrix and output contracts differ. |
| [`McCat/01-qbsort/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/01-qbsort/info.sh) | `01-qbsort` | Newly implemented in this batch | [`mccat_qbsort`](m/mccat_qbsort/README.md): both source sorting paths, mode-selected, with the 1,000-repeat launcher profile. |
| [`McCat/15-trie/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/15-trie/info.sh) | `15-trie` | Newly implemented in this batch | [`mccat_trie`](m/mccat_trie/README.md): inserts tokens into the source's continuation/alternative trie and emits distinct words in traversal order. |
| [`McCat/03-testtrie/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/03-testtrie/info.sh) | `03-testtrie` | Partial/related | [`mccat_trie`](m/mccat_trie/README.md) already covers trie insertion and traversal. `03-testtrie` uses a 26-child trie and prints occurrence counts, while `15-trie` uses continuation/alternative links and emits each token once; no separate package is added for the shared trie algorithm. |
| `PolyBench/medley/floyd-warshall/info.sh` | `floyd-warshall` | Partial/related | [`floyd_warshall`](f/floyd_warshall/README.md): same recurrence, local contract returns a requested source row. |
| `PolyBench/medley/nussinov/info.sh` | `nussinov` | Newly implemented in this batch | [`nussinov`](n/nussinov/README.md): bounded dynamic-programming RNA folding recurrence. |
| `Olden/treeadd/info.sh` | `treeadd` | Partial/related | [`binary_tree_node_sum`](b/binary_tree_node_sum/README.md) already implements recursive depth-first summation over a binary tree. Olden's full value-one tree and repeated traversal are input and repetition profiles, so no duplicate package is retained. |
| [`Olden/mst/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/mst/info.sh) | `mst` | Partial/related | [`prim`](p/prim/README.md) already implements the same Prim/BlueRule minimum-spanning-tree growth algorithm; Olden's graph generator and output profile do not define a second algorithm package. |
| `Olden/bh/info.sh` | `bh` | Newly implemented in this batch | [`olden_bh`](o/olden_bh/README.md): bounded 3D Barnes–Hut octree with monopole gravity approximation. |
| `Olden/em3d/info.sh` | `em3d` | Newly implemented in this batch | [`olden_em3d`](o/olden_em3d/README.md): source-ordered in-place field updates over a bipartite electric/magnetic graph. |
| `Olden/health/info.sh` | `health` | Newly implemented in this batch | [`olden_health`](o/olden_health/README.md): deterministic health-system simulation over a four-way village tree and FIFO hospital queues. |
| `MiBench/automotive-bitcount/info.sh` | `automotive-bitcount` | Newly implemented in this batch | [`automotive_bitcount`](a/automotive_bitcount/README.md): seven source-selected bit-count kernels over deterministic streams. |
| [`MiBench/network-dijkstra/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/network-dijkstra/info.sh) | `network-dijkstra` | Newly implemented in this batch | [`mibench_network_dijkstra`](m/mibench_network_dijkstra/README.md): FIFO queue-based label-correcting shortest paths, distinct from label-setting Dijkstra and full-pass Bellman–Ford. |
| [`MiBench/network-patricia/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/network-patricia/info.sh) | `network-patricia` | Partial/related | [`radix_tree`](r/radix_tree/README.md) already covers path-compressed radix/Patricia trie insertion and exact lookup; the fixed-width IPv4 trace is a specialized key/workload profile. The cBench copy is the same implementation. |
| [`MiBench/security-blowfish/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/security-blowfish/info.sh) | `security-blowfish` | Partial/related | [`mibench_security_blowfish`](m/mibench_security_blowfish/README.md) ports one bounded Blowfish ECB block; the launcher’s file-processing flow and CBC/CFB/OFB stages are outside the package. |
| `MiBench/telecomm-FFT/info.sh` | `telecomm-FFT` | Partial/related | [`fast_fourier_transform`](f/fast_fourier_transform/README.md) and [`inverse_fast_fourier_transform`](i/inverse_fast_fourier_transform/README.md) already cover the radix-2 forward and inverse FFT algorithms. MiBench's float32 complex-vector profile and launcher are not retained as a duplicate package. |
| `MiBench/office-stringsearch/info.sh` | `office-stringsearch` | Partial/related | [`boyer_moore_horspool`](b/boyer_moore_horspool/README.md) implements the same case-sensitive BMH shift algorithm as `bmhsrch.c`; its shared contract returns all match positions. The launcher's other case-folded/Pratt variants and demo are not separate packages. |
| `MiBench/telecomm-CRC32/info.sh` | `telecomm-CRC32` | Partial/related | [`crc32`](c/crc32/README.md) already uses the same reflected IEEE CRC-32 recurrence. MiBench's table lookup and file wrapper do not define a second algorithm package. |
| [`cBench/telecom_CRC32/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/telecom_CRC32/src/info.sh) | `telecom_CRC32` | Partial/related | [`crc32`](c/crc32/README.md) already implements the same reflected IEEE CRC-32 table recurrence; cBench's launcher and dataset wrapper are workload details. |
| [`cBench/automotive_bitcount/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/automotive_bitcount/src/info.sh) | `automotive_bitcount` | Partial/related | [`automotive_bitcount`](a/automotive_bitcount/README.md) already implements the same seven bit-count algorithms; cBench's per-kernel seed `1` and dataset-1 repeat/input profile are workload details. |
| `Shootout/ackermann/info.sh` | `ackermann` | Newly implemented in this batch | [`ackermann`](a/ackermann/README.md): direct recursive source recurrence, including the launcher default `Ack(3,8)`. |
| `Shootout/hello/info.sh` | `hello` | Newly implemented in this batch | [`shootout_hello`](s/shootout_hello/README.md): exact single `puts("hello world\\n")` call, including its second newline. |
| `Shootout/lists/info.sh` | `lists` | Newly implemented in this batch | [`shootout_lists`](s/shootout_lists/README.md): full circular doubly linked-list transformations and source stdout for zero or positive pass counts. |
| `Shootout/strcat/info.sh` | `strcat` | Newly implemented in this batch | [`shootout_strcat`](s/shootout_strcat/README.md): bounded repeated `hello\n` appends with the exact decimal final length output. |
| [`Shootout/matrix/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/matrix/info.sh) | `matrix` | Partial/related | [`matrix_multiplication`](m/matrix_multiplication/README.md) already implements the same row-by-column multiplication; fixed dimensions, repeated passes, and printed cells are source-profile details. |
| `Shootout/methcall/info.sh` | `methcall` | Newly implemented in this batch | [`shootout_methcall`](s/shootout_methcall/README.md): bounded Toggle/NthToggle calls with exact `puts` newline framing. |
| `Shootout/hash/info.sh` | `hash` | Newly implemented in this batch | [`shootout_hash`](s/shootout_hash/README.md): bounded source-compatible chained hash inserts and descending decimal lookups. |
| `Shootout/sieve/info.sh` | `sieve` | Partial/related | [`sieve_of_eratosthenes`](s/sieve_of_eratosthenes/README.md) already implements the same byte-flag prime sieve; repeated passes, fixed bounds, and stdout framing do not add a distinct algorithm. |
| `Shootout/random/info.sh` | `random` | Newly implemented in this batch | [`shootout_random`](s/shootout_random/README.md): bounded source LCG sequence with exact nine-place final-value output. |
| [`Shootout/heapsort/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/heapsort/info.sh) | `heapsort` | Partial/related | [`heap_sort`](h/heap_sort/README.md) already implements heapsort; generated doubles and maximum-only stdout are source-profile details. |
| `Shootout/nestedloop/info.sh` | `nestedloop` | Exact local semantic match | [`nestedloop`](n/nestedloop/README.md) preserves the six nested loops and counter semantics. |
| `Shootout/fib2/info.sh` | `fib2` | Newly implemented in this batch | [`fib2`](f/fib2/README.md): uncached recursive Fibonacci variant with source base values `fib(0)=fib(1)=1`. |
| `Shootout/ary3/info.sh` | `ary3` | Newly implemented in this batch | [`ary3`](a/ary3/README.md): bounded reverse-index array accumulation with exact two-value output framing. |
| [`Stanford/FloatMM/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/FloatMM/info.sh) | `FloatMM` | Partial/related | [`matrix_multiplication`](m/matrix_multiplication/README.md) already implements the same row-by-column multiplication; binary32 values and printed diagonals are source-profile details. |
| [`Stanford/IntMM/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/IntMM/info.sh) | `IntMM` | Partial/related | [`matrix_multiplication`](m/matrix_multiplication/README.md) already implements the same row-by-column multiplication; matrix size, generated integers, and diagonal output are source-profile details. |
| [`Stanford/RealMM/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/RealMM/info.sh) | `RealMM` | Partial/related | [`matrix_multiplication`](m/matrix_multiplication/README.md) already implements the same row-by-column multiplication; floating-point values, matrix size, and diagonal output are source-profile details. |
| [`Stanford/Bubblesort/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Bubblesort/info.sh) | `Bubblesort` | Partial/related | [`bubble_sort`](b/bubble_sort/README.md) already implements adjacent-swap bubble sort; the fixed generated input, no-early-exit pass count, and selected-rank output are source-profile details. |
| `Stanford/Queens/info.sh` | `Queens` | Newly implemented in this batch | [`stanford_queens`](s/stanford_queens/README.md): 50 repeated first-solution eight-queens searches per pass and exact ordinal stdout. |
| [`Stanford/Quicksort/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Quicksort/info.sh) | `Quicksort` | Partial/related | [`quick_sort`](q/quick_sort/README.md) already implements quicksort; the midpoint pivot, generated input, and output prefix are source-profile details. |
| [`Stanford/Treesort/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Treesort/info.sh) | `Treesort` | Partial/related | [`tree_sort`](t/tree_sort/README.md) already implements the same BST-based sorting structure; duplicate-dropping and selected original-key output are source-profile details. |
| [`Stanford/Towers/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Towers/info.sh) | `Towers` | Partial/related | [`tower_of_hanoi`](t/tower_of_hanoi/README.md) already implements the same three-peg recursive move recurrence; the 14-disk profile and count-only output do not define another algorithm. |
| `McGill/queens/info.sh` | `queens` | Newly implemented in this batch | [`queens`](q/queens/README.md): launcher’s count-only 14-queens search and exact two-line output. |
| `Trimaran/netbench-crc/info.sh` | `netbench-crc` | Newly implemented in this batch | [`netbench_crc`](n/netbench_crc/README.md): bounded NetBench CRC table generation and byte-update kernel with its redistribution notice preserved. |
| `Trimaran/netbench-url/info.sh` | `netbench-url` | Partial/related | [`trimaran_netbench_url_internet_checksum`](t/trimaran_netbench_url_internet_checksum/README.md): standalone `internet_checksum` helper with the pinned NetBench redistribution terms retained; routing rules, packet generation, Boyer–Moore search, and launcher report are excluded. |
| `Trimaran/enc-rc4/info.sh` | `enc-rc4` | Newly implemented in this batch | [`trimaran_enc_rc4`](t/trimaran_enc_rc4/README.md): six fixed ARC4 validation vectors with the 2,000-pass small-launcher bound and GPL-2.0-or-later notice. |
| `Trimaran/enc-3des/info.sh` | `enc-3des` | Partial/related | [`trimaran_enc_3des`](t/trimaran_enc_3des/README.md): bounded fixed-key, three-key 3DES ECB single-block encrypt/decrypt stage. Single-DES and two-key variants, the 10,000-transform Monte Carlo loop, launcher repeats, and CLI report are excluded. |
| `NPB-serial/is/info.sh` | `is` | Newly implemented in this batch | [`npb_is`](n/npb_is/README.md): class-W integer sort with partial-rank checks and final full-order verification. |
| [`McGill/exptree/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McGill/exptree/info.sh) | `exptree` | Newly implemented in this batch | [`mcgill_exptree`](m/mcgill_exptree/README.md): bounded iterative-deepening expression-tree search with source-order tie behavior. |
| [`McGill/chomp/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McGill/chomp/info.sh) | `chomp` | Newly implemented in this batch | [`mcgill_chomp`](c/mcgill_chomp/README.md): fixed 7-column Chomp game-state solver for the launcher's 7- and 8-row profiles. |
| [`Olden/bisort/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/bisort/info.sh) | `bisort` | Partial/related | [`bitonic_sort`](b/bitonic_sort/README.md) already implements bitonic sorting. Olden's version uses a generated binary-tree topology and spill value, so its input profile differs while the core sorting algorithm is the same; no duplicate package is added. |
| [`Olden/perimeter/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/perimeter/info.sh) | `perimeter` | Newly implemented in this batch | [`olden_perimeter`](o/olden_perimeter/README.md): bounded TORONTO quadtree perimeter, under a distinct symbol because local [`perimeter`](p/perimeter/README.md) computes a regular polygon. |
| [`Olden/power/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/power/info.sh) | `power` | Newly implemented in this batch | [`olden_power`](o/olden_power/README.md): bounded feeder-tree optimizer recurrence with an observable fixed-point projection of the final state. |
| [`Olden/tsp/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/tsp/info.sh) | `tsp` | Newly implemented in this batch | [`olden_tsp`](o/olden_tsp/README.md): bounded closest-point insertion leaves with the source Karp cycle merge. |
| [`Olden/voronoi/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/voronoi/info.sh) | `voronoi` | Newly implemented in this batch | [`olden_voronoi`](o/olden_voronoi/README.md): bounded quad-edge divide-and-conquer Delaunay triangulation and Voronoi dual. |
| [`Misc/pi/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/pi/info.sh) | `pi` | Partial/related | [`pi_approximation`](p/pi_approximation/README.md) already counts points inside a quarter circle and estimates π. The lac-dcc variant generates its own deterministic samples and retains a float32 recurrence, so it is tracked as the same Monte Carlo estimation algorithm rather than added as a duplicate package. |
| [`Misc/whetstone/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/whetstone/info.sh) | `whetstone` | Partial/related | [`ansibench_whetstone`](a/ansibench_whetstone/README.md) already implements the same C Converted Whetstone Double Precision Benchmark 1.2 operation mix from the shared Netlib basis. The launcher repetition and timer profile differ; no duplicate algorithm package is added. |
| `PolyBench/datamining/correlation/info.sh` | `correlation` | Newly implemented in this batch | [`polybench_correlation`](c/polybench_correlation/README.md): bounded initialized matrix correlation kernel; distinct from local scalar `correlation`. |
| [`Prolangs-C/allroots/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/allroots/info.sh) | `allroots` | Newly implemented in this batch | [`prolangs_c_allroots`](a/prolangs_c_allroots/README.md): bounded cubic real-root path using simultaneous Horner/Newton evaluation, synthetic deflation, and the quadratic formula. |

The source-backed new packages are linked to commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38` in their READMEs. Their presence is recorded here as implementation coverage, not as a test result.

## Complete launcher-path inventory

Rows not assigned a reviewed overlap above remain **Pending semantic review/implementation**. The pending status avoids treating suite labels, executable names, or nearby local algorithms as equivalence.

### ASCI_Purple

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`ASCI_Purple/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/ASCI_Purple/info.sh) | `smg2000` | Pending semantic review/implementation |

### ASC_Sequoia

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`ASC_Sequoia/AMGmk/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/ASC_Sequoia/AMGmk/info.sh) | `AMGmk` | Pending semantic review/implementation |
| [`ASC_Sequoia/CrystalMk/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/ASC_Sequoia/CrystalMk/info.sh) | `CrystalMK` | Pending semantic review/implementation |
| [`ASC_Sequoia/IRSmk/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/ASC_Sequoia/IRSmk/info.sh) | `IRSmk` | Pending semantic review/implementation |

### BenchmarkGame

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`BenchmarkGame/fannkuch/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BenchmarkGame/fannkuch/info.sh) | `fannkuch` | Newly implemented in this batch |
| [`BenchmarkGame/n-body/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BenchmarkGame/n-body/info.sh) | `nbody` | Newly implemented in this batch |
| [`BenchmarkGame/nsieve-bits/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BenchmarkGame/nsieve-bits/info.sh) | `nsieve-bits` | Partial/related: same Sieve of Eratosthenes algorithm as [`sieve_of_eratosthenes`](s/sieve_of_eratosthenes/README.md); no duplicate package |
| [`BenchmarkGame/partialsums/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BenchmarkGame/partialsums/info.sh) | `partialsums` | Newly implemented in this batch |
| [`BenchmarkGame/puzzle/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BenchmarkGame/puzzle/info.sh) | `puzzle` | Newly implemented in this batch |
| [`BenchmarkGame/recursive/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BenchmarkGame/recursive/info.sh) | `recursive` | Newly implemented in this batch |
| [`BenchmarkGame/spectral-norm/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BenchmarkGame/spectral-norm/info.sh) | `spectral-norm` | Newly implemented in this batch |

### BitBench

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`BitBench/drop3/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BitBench/drop3/info.sh) | `drop3` | Newly implemented in this batch |
| [`BitBench/five11/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BitBench/five11/info.sh) | `five11` | Newly implemented in this batch |
| [`BitBench/uudecode/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BitBench/uudecode/info.sh) | `uudecode` | Newly implemented in this batch |
| [`BitBench/uuencode/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BitBench/uuencode/info.sh) | `uuencode` | Newly implemented in this batch |

### CoyoteBench

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`CoyoteBench/almabench/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/CoyoteBench/almabench/info.sh) | `almabench` | Newly implemented in this batch |
| [`CoyoteBench/huffbench/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/CoyoteBench/huffbench/info.sh) | `huffbench` | Newly implemented in this batch |
| [`CoyoteBench/lpbench/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/CoyoteBench/lpbench/info.sh) | `lpbench` | Partial/related: uses the same pivoted LINPACK `dgefa`/`dgesl` factor-and-solve algorithm as [`linpack_lu_solve`](l/linpack_lu_solve/README.md); matrix generation, size, and timing are profile details. |

### DOE_ProxyApps_C

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`DOE_ProxyApps_C/Pathfinder/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/DOE_ProxyApps_C/Pathfinder/info.sh) | `Pathfinder` | Pending semantic review/implementation |
| [`DOE_ProxyApps_C/RSBench/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/DOE_ProxyApps_C/RSBench/info.sh) | `RSBench` | Pending semantic review/implementation |
| [`DOE_ProxyApps_C/SimpleMOC/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/DOE_ProxyApps_C/SimpleMOC/info.sh) | `SimpleMOC` | Pending semantic review/implementation |
| [`DOE_ProxyApps_C/XSBench/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/DOE_ProxyApps_C/XSBench/info.sh) | `XSBench` | Pending semantic review/implementation |
| [`DOE_ProxyApps_C/miniAMR/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/DOE_ProxyApps_C/miniAMR/info.sh) | `miniAMR` | Pending semantic review/implementation |
| [`DOE_ProxyApps_C/miniGMG/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/DOE_ProxyApps_C/miniGMG/info.sh) | `miniGMG` | Pending semantic review/implementation |

### Dhrystone

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`Dhrystone/dry/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Dhrystone/dry/info.sh) | `dry` | Pending semantic review/implementation |
| [`Dhrystone/fldry/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Dhrystone/fldry/info.sh) | `fldry` | Pending semantic review/implementation |

### Fhourstones

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`Fhourstones/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Fhourstones/info.sh) | `Fhourstones` | Pending semantic review/implementation |

### Fhourstones_31

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`Fhourstones_31/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Fhourstones_31/info.sh) | `Fhourstones_31` | Pending semantic review/implementation |

### FreeBench

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`FreeBench/analyzer/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/analyzer/info.sh) | `analyzer` | Pending semantic review/implementation |
| [`FreeBench/distray/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/distray/info.sh) | `distray` | Pending semantic review/implementation |
| [`FreeBench/fourinarow/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/fourinarow/info.sh) | `fourinarow` | Pending semantic review/implementation |
| [`FreeBench/mason/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/mason/info.sh) | `mason` | Pending semantic review/implementation |
| [`FreeBench/neural/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/neural/info.sh) | `neural` | Pending semantic review/implementation |
| [`FreeBench/pcompress2/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/pcompress2/info.sh) | `pcompress2` | Pending semantic review/implementation |
| [`FreeBench/pifft/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/FreeBench/pifft/info.sh) | `pifft` | Pending semantic review/implementation |

### Linpack

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`Linpack/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Linpack/info.sh) | `Linpack` | Partial/related: uses the same pivoted LINPACK `dgefa`/`dgesl` factor-and-solve algorithm as [`linpack_lu_solve`](l/linpack_lu_solve/README.md); matrix size and reporting are profile details. |

### MallocBench

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`MallocBench/cfrac/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MallocBench/cfrac/info.sh) | `cfrac` | Pending semantic review/implementation |
| [`MallocBench/espresso/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MallocBench/espresso/info.sh) | `espresso` | Pending semantic review/implementation |
| [`MallocBench/gs/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MallocBench/gs/info.sh) | `gs` | Pending semantic review/implementation |
| [`MallocBench/make/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MallocBench/make/info.sh) | `make` | Pending semantic review/implementation |

### McCat

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`McCat/01-qbsort/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/01-qbsort/info.sh) | `01-qbsort` | Newly implemented in this batch |
| [`McCat/03-testtrie/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/03-testtrie/info.sh) | `03-testtrie` | Partial/related: shares trie insertion and traversal with [`mccat_trie`](m/mccat_trie/README.md); its 26-child representation and duplicate occurrence counts are not ported as a separate package. |
| [`McCat/04-bisect/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/04-bisect/info.sh) | `04-bisect` | Newly implemented in this batch | [`mccat_bisect`](m/mccat_bisect/README.md): bounded source-ordered Sturm bisection over the launcher's symmetric tridiagonal matrix, returning the printed eigenvalue/diagnostic vector. |
| [`McCat/05-eks/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/05-eks/info.sh) | `05-eks` | Pending semantic review/implementation |
| [`McCat/08-main/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/08-main/info.sh) | `08-main` | Pending semantic review/implementation |
| [`McCat/09-vor/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/09-vor/info.sh) | `09-vor` | Pending semantic review/implementation |
| [`McCat/12-IOtest/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/12-IOtest/info.sh) | `12-IOtest` | Pending semantic review/implementation |
| [`McCat/15-trie/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/15-trie/info.sh) | `15-trie` | Newly implemented in this batch: [`mccat_trie`](m/mccat_trie/README.md) |
| [`McCat/17-bintr/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/17-bintr/info.sh) | `17-bintr` | Pending semantic review/implementation |

### McGill

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`McGill/chomp/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McGill/chomp/info.sh) | `chomp` | Newly implemented in this batch |
| [`McGill/exptree/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McGill/exptree/info.sh) | `exptree` | Newly implemented in this batch |
| [`McGill/misr/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McGill/misr/info.sh) | `misr` | Newly implemented in this batch |
| [`McGill/queens/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McGill/queens/info.sh) | `queens` | Newly implemented in this batch |

### MiBench

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`MiBench/automotive-basicmath/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/automotive-basicmath/info.sh) | `automotive-basicmath` | Partial/related: [`mibench_automotive_basicmath_cubic`](m/mibench_automotive_basicmath_cubic/README.md) ports the public-domain `SolveCubic` kernel from `cubic.c`; the launcher’s integer square-root and angle-conversion kernels are not included. |
| [`MiBench/automotive-bitcount/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/automotive-bitcount/info.sh) | `automotive-bitcount` | Newly implemented in this batch |
| [`MiBench/automotive-susan/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/automotive-susan/info.sh) | `automotive-susan` | Pending semantic review/implementation |
| [`MiBench/consumer-jpeg/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/consumer-jpeg/info.sh) | `consumer-jpeg` | Pending semantic review/implementation |
| [`MiBench/consumer-lame/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/consumer-lame/info.sh) | `consumer-lame` | Pending semantic review/implementation |
| [`MiBench/network-dijkstra/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/network-dijkstra/info.sh) | `network-dijkstra` | Newly implemented in this batch | [`mibench_network_dijkstra`](m/mibench_network_dijkstra/README.md) implements FIFO label-correcting relaxation with a queue of `(node,distance)` labels; it differs from global-minimum label selection and full-pass Bellman–Ford. The pinned license gives no GPL version, and the ports do not copy its source. |
| [`MiBench/network-patricia/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/network-patricia/info.sh) | `network-patricia` | Partial/related: [`radix_tree`](r/radix_tree/README.md) covers the same path-compressed radix/Patricia trie insertion and exact-search algorithm; the IPv4 key encoding and launcher trace are profile details. |
| [`MiBench/office-stringsearch/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/office-stringsearch/info.sh) | `office-stringsearch` | Partial/related: [`boyer_moore_horspool`](b/boyer_moore_horspool/README.md) uses the same case-sensitive BMH shift algorithm as `bmhsrch.c`; its all-match contract covers the same core operation. The other three launcher variants and demo workload are excluded. |
| [`MiBench/security-blowfish/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/security-blowfish/info.sh) | `security-blowfish` | Partial/related: [`mibench_security_blowfish`](m/mibench_security_blowfish/README.md) covers a bounded ECB block with the pinned terms retained; the launcher’s file flow and CBC/CFB/OFB stages are excluded. |
| [`MiBench/security-rijndael/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/security-rijndael/info.sh) | `security-rijndael` | Newly implemented in this batch | [`mibench_security_rijndael`](m/mibench_security_rijndael/README.md): source `set_key` and `encrypt` AES-256 single-block kernel, with Brian Gladman's redistribution terms retained. |
| [`MiBench/security-sha/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/security-sha/info.sh) | `security-sha` | Pending semantic review/implementation | The launcher leaves `USE_MODIFIED_SHA` disabled, selecting the pre-SHA-1 160-bit variant; the pinned `LICENSE` has attribution/comments but no redistribution grant, and local `sha2` implements a different SHA family. |
| [`MiBench/telecomm-CRC32/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/telecomm-CRC32/info.sh) | `telecomm-CRC32` | Partial/related | [`crc32`](c/crc32/README.md) already computes the same reflected IEEE CRC-32 value over explicit bytes; the table-driven implementation is an optimization of the same recurrence. |
| [`MiBench/telecomm-FFT/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/telecomm-FFT/info.sh) | `telecomm-FFT` | Partial/related | The same radix-2 forward and inverse FFT algorithms are covered by [`fast_fourier_transform`](f/fast_fourier_transform/README.md) and [`inverse_fast_fourier_transform`](i/inverse_fast_fourier_transform/README.md); MiBench's float32 complex-vector profile does not warrant another package. |

### Misc

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`Misc/ReedSolomon/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/ReedSolomon/info.sh) | `ReedSolomon` | Newly implemented in this batch |
| [`Misc/dt/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/dt/info.sh) | `dt` | Newly implemented in this batch |
| [`Misc/evalloop/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/evalloop/info.sh) | `evalloop` | Newly implemented in this batch |
| [`Misc/fbench/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/fbench/info.sh) | `fbench` | Pending semantic review/implementation |
| [`Misc/ffbench/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/ffbench/info.sh) | `ffbench` | Pending semantic review/implementation |
| [`Misc/flops-1/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/flops-1/info.sh) | `flops-1` | Pending semantic review/implementation |
| [`Misc/flops-2/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/flops-2/info.sh) | `flops-2` | Pending semantic review/implementation |
| [`Misc/flops-3/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/flops-3/info.sh) | `flops-3` | Pending semantic review/implementation |
| [`Misc/flops-4/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/flops-4/info.sh) | `flops-4` | Pending semantic review/implementation |
| [`Misc/flops-5/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/flops-5/info.sh) | `flops-5` | Pending semantic review/implementation |
| [`Misc/flops-6/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/flops-6/info.sh) | `flops-6` | Pending semantic review/implementation |
| [`Misc/flops-7/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/flops-7/info.sh) | `flops-7` | Pending semantic review/implementation |
| [`Misc/flops-8/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/flops-8/info.sh) | `flops-8` | Pending semantic review/implementation |
| [`Misc/flops/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/flops/info.sh) | `flops` | Pending semantic review/implementation |
| [`Misc/fp-convert/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/fp-convert/info.sh) | `fp-convert` | Newly implemented in this batch |
| [`Misc/perlin/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/perlin/info.sh) | `perlin` | Newly implemented in this batch | [`improved_perlin_noise_3d`](i/improved_perlin_noise_3d/README.md) ports the fixed-permutation 3D gradient-noise kernel. Local [`perlin_noise`](p/perlin_noise/README.md) is seeded 2D value noise, a different algorithm. |
| [`Misc/himenobmtxpa/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/himenobmtxpa/info.sh) | `himenobmtxpa` | Newly implemented in this batch |
| [`Misc/lowercase/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/lowercase/info.sh) | `lowercase` | Newly implemented in this batch: [`misc_lowercase`](l/misc_lowercase/README.md) |
| [`Misc/mandel-2/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/mandel-2/info.sh) | `mandel-2` | Partial/related: the core Mandelbrot iteration is covered by [`mandelbrot`](m/mandelbrot/README.md); this launcher changes only the fixed grid, limit, and text output profile. |
| [`Misc/mandel/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/mandel/info.sh) | `mandel` | Partial/related: [`mandelbrot`](m/mandelbrot/README.md) covers the same escape-time recurrence; the source's 500×500 ten-iteration complex-value reduction is not a separate algorithm. |
| [`Misc/matmul_f64_4x4/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/matmul_f64_4x4/info.sh) | `matmul_f64_4x4` | Newly implemented in this batch |
| [`Misc/oourafft/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/oourafft/info.sh) | `oourafft` | Pending semantic review/implementation |
| [`Misc/pi/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/pi/info.sh) | `pi` | Partial/related |
| [`Misc/revertBits/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/revertBits/info.sh) | `revertBits` | Newly implemented in this batch |
| [`Misc/richards_benchmark/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/richards_benchmark/info.sh) | `richards_benchmark` | Pending semantic review/implementation |
| [`Misc/salsa20/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/salsa20/info.sh) | `salsa20` | Partial/related: same 16-word Salsa core as [`salsa`](s/salsa/README.md); no duplicate package |
| [`Misc/whetstone/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/whetstone/info.sh) | `whetstone` | Partial/related |

### NPB-serial

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`NPB-serial/dc/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/NPB-serial/dc/info.sh) | `dc` | Pending semantic review/implementation |
| [`NPB-serial/is/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/NPB-serial/is/info.sh) | `is` | Newly implemented in this batch |

### Olden

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`Olden/bh/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/bh/info.sh) | `bh` | Newly implemented in this batch |
| [`Olden/bisort/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/bisort/info.sh) | `bisort` | Partial/related |
| [`Olden/em3d/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/em3d/info.sh) | `em3d` | Newly implemented in this batch |
| [`Olden/health/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/health/info.sh) | `health` | Newly implemented in this batch |
| [`Olden/mst/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/mst/info.sh) | `mst` | Partial/related: [`prim`](p/prim/README.md) uses the same Prim/BlueRule tree-growth algorithm; no duplicate package is added. |
| [`Olden/perimeter/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/perimeter/info.sh) | `perimeter` | Newly implemented in this batch |
| [`Olden/power/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/power/info.sh) | `power` | Newly implemented in this batch |
| [`Olden/treeadd/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/treeadd/info.sh) | `treeadd` | Partial/related |
| [`Olden/tsp/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/tsp/info.sh) | `tsp` | Newly implemented in this batch |
| [`Olden/voronoi/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/voronoi/info.sh) | `voronoi` | Newly implemented in this batch |

### PAQ8p

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`PAQ8p/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PAQ8p/info.sh) | `PAQ8p` | Pending semantic review/implementation |

### PolyBench

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`PolyBench/datamining/correlation/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/datamining/correlation/info.sh) | `correlation` | Newly implemented in this batch |
| [`PolyBench/datamining/covariance/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/datamining/covariance/info.sh) | `covariance` | Newly implemented in this batch |
| [`PolyBench/linear-algebra/blas/gemm/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/blas/gemm/info.sh) | `gemm` | Newly implemented in this batch |
| [`PolyBench/linear-algebra/blas/gemver/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/blas/gemver/info.sh) | `gemver` | Newly implemented in this batch |
| [`PolyBench/linear-algebra/blas/gesummv/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/blas/gesummv/info.sh) | `gesummv` | Newly implemented in this batch |
| [`PolyBench/linear-algebra/blas/symm/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/blas/symm/info.sh) | `symm` | Newly implemented in this batch |
| [`PolyBench/linear-algebra/blas/syr2k/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/blas/syr2k/info.sh) | `syr2k` | Newly implemented in this batch |
| [`PolyBench/linear-algebra/blas/syrk/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/blas/syrk/info.sh) | `syrk` | Newly implemented in this batch |
| [`PolyBench/linear-algebra/blas/trmm/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/blas/trmm/info.sh) | `trmm` | Newly implemented in this batch | [`trmm`](t/trmm/README.md): bounded source-ordered triangular matrix multiplication update with full row-major B output. |
| [`PolyBench/linear-algebra/kernels/2mm/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/kernels/2mm/info.sh) | `2mm` | Newly implemented in this batch |
| [`PolyBench/linear-algebra/kernels/3mm/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/kernels/3mm/info.sh) | `3mm` | Newly implemented in this batch |
| [`PolyBench/linear-algebra/kernels/atax/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/kernels/atax/info.sh) | `atax` | Newly implemented in this batch |
| [`PolyBench/linear-algebra/kernels/bicg/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/kernels/bicg/info.sh) | `bicg` | Newly implemented in this batch |
| [`PolyBench/linear-algebra/kernels/doitgen/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/kernels/doitgen/info.sh) | `doitgen` | Newly implemented in this batch |
| [`PolyBench/linear-algebra/kernels/mvt/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/kernels/mvt/info.sh) | `mvt` | Newly implemented in this batch |
| [`PolyBench/linear-algebra/solvers/cholesky/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/solvers/cholesky/info.sh) | `cholesky` | Newly implemented in this batch |
| [`PolyBench/linear-algebra/solvers/durbin/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/solvers/durbin/info.sh) | `durbin` | Newly implemented in this batch |
| [`PolyBench/linear-algebra/solvers/gramschmidt/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/solvers/gramschmidt/info.sh) | `gramschmidt` | Partial/related |
| [`PolyBench/linear-algebra/solvers/lu/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/solvers/lu/info.sh) | `lu` | Newly implemented in this batch |
| [`PolyBench/linear-algebra/solvers/ludcmp/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/solvers/ludcmp/info.sh) | `ludcmp` | Newly implemented in this batch |
| [`PolyBench/linear-algebra/solvers/trisolv/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/solvers/trisolv/info.sh) | `trisolv` | Newly implemented in this batch |
| [`PolyBench/medley/deriche/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/medley/deriche/info.sh) | `deriche` | Newly implemented in this batch |
| [`PolyBench/medley/floyd-warshall/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/medley/floyd-warshall/info.sh) | `floyd-warshall` | Partial/related |
| [`PolyBench/medley/nussinov/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/medley/nussinov/info.sh) | `nussinov` | Newly implemented in this batch |
| [`PolyBench/stencils/adi/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/stencils/adi/info.sh) | `adi` | Newly implemented in this batch ([`polybench_adi`](p/polybench_adi/README.md)) |
| [`PolyBench/stencils/fdtd-2d/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/stencils/fdtd-2d/info.sh) | `fdtd-2d` | Newly implemented in this batch |
| [`PolyBench/stencils/heat-3d/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/stencils/heat-3d/info.sh) | `heat-3d` | Newly implemented in this batch |
| [`PolyBench/stencils/jacobi-1d/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/stencils/jacobi-1d/info.sh) | `jacobi-1d` | Newly implemented in this batch |
| [`PolyBench/stencils/jacobi-2d/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/stencils/jacobi-2d/info.sh) | `jacobi-2d` | Newly implemented in this batch |
| [`PolyBench/stencils/seidel-2d/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/stencils/seidel-2d/info.sh) | `seidel-2d` | Newly implemented in this batch |

### Prolangs-C

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`Prolangs-C/TimberWolfMC/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/TimberWolfMC/info.sh) | `TimerWolfMC` | Pending semantic review/implementation |
| [`Prolangs-C/agrep/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/agrep/info.sh) | `agrep` | Pending semantic review/implementation |
| [`Prolangs-C/allroots/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/allroots/info.sh) | `allroots` | Newly implemented in this batch |
| [`Prolangs-C/archie-client/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/archie-client/info.sh) | `archie-client` | Pending semantic review/implementation |
| [`Prolangs-C/assembler/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/assembler/info.sh) | `assembler` | Pending semantic review/implementation |
| [`Prolangs-C/bison/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/bison/info.sh) | `bison` | Pending semantic review/implementation |
| [`Prolangs-C/cdecl/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/cdecl/info.sh) | `cdecl` | Pending semantic review/implementation |
| [`Prolangs-C/compiler/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/compiler/info.sh) | `compiler` | Pending semantic review/implementation |
| [`Prolangs-C/fixoutput/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/fixoutput/info.sh) | `fixoutput` | Pending semantic review/implementation |
| [`Prolangs-C/football/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/football/info.sh) | `football` | Pending semantic review/implementation |
| [`Prolangs-C/gnugo/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/gnugo/info.sh) | `gnugo` | Pending semantic review/implementation |
| [`Prolangs-C/loader/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/loader/info.sh) | `loader` | Pending semantic review/implementation |
| [`Prolangs-C/plot2fig/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/plot2fig/info.sh) | `plot2fig` | Pending semantic review/implementation |
| [`Prolangs-C/simulator/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/simulator/info.sh) | `simulator` | Pending semantic review/implementation |
| [`Prolangs-C/unix-smail/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/unix-smail/info.sh) | `unix-smail` | Pending semantic review/implementation |
| [`Prolangs-C/unix-tbl/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/unix-tbl/info.sh) | `unix-tbl` | Pending semantic review/implementation |

### Ptrdist

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`Ptrdist/anagram/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Ptrdist/anagram/info.sh) | `anagram` | Pending semantic review/implementation |
| [`Ptrdist/bc/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Ptrdist/bc/info.sh) | `bc` | Pending semantic review/implementation |
| [`Ptrdist/ft/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Ptrdist/ft/info.sh) | `ft` | Pending semantic review/implementation |
| [`Ptrdist/ks/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Ptrdist/ks/info.sh) | `ks` | Pending semantic review/implementation |
| [`Ptrdist/yacr2/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Ptrdist/yacr2/info.sh) | `yacr2` | Pending semantic review/implementation |

### SciMark2-C

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`SciMark2-C/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/SciMark2-C/info.sh) | `SciMark2-C` | Pending semantic review/implementation |

### Shootout

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`Shootout/ackermann/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/ackermann/info.sh) | `ackermann` | Newly implemented in this batch |
| [`Shootout/ary3/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/ary3/info.sh) | `ary3` | Newly implemented in this batch |
| [`Shootout/fib2/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/fib2/info.sh) | `fib2` | Newly implemented in this batch |
| [`Shootout/hash/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/hash/info.sh) | `hash` | Newly implemented in this batch |
| [`Shootout/heapsort/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/heapsort/info.sh) | `heapsort` | Partial/related: same heapsort algorithm as [`heap_sort`](h/heap_sort/README.md); no duplicate package |
| [`Shootout/hello/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/hello/info.sh) | `hello` | Newly implemented in this batch |
| [`Shootout/lists/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/lists/info.sh) | `lists` | Newly implemented in this batch |
| [`Shootout/matrix/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/matrix/info.sh) | `matrix` | Partial/related: same row-by-column matrix multiplication as [`matrix_multiplication`](m/matrix_multiplication/README.md); no duplicate package |
| [`Shootout/methcall/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/methcall/info.sh) | `methcall` | Newly implemented in this batch |
| [`Shootout/nestedloop/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/nestedloop/info.sh) | `nestedloop` | Exact local semantic match |
| [`Shootout/objinst/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/objinst/info.sh) | `objinst` | Newly implemented in this batch: [`shootout_objinst`](s/shootout_objinst/README.md) |
| [`Shootout/random/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/random/info.sh) | `random` | Newly implemented in this batch |
| [`Shootout/sieve/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/sieve/info.sh) | `sieve` | Partial/related: same Sieve of Eratosthenes algorithm as [`sieve_of_eratosthenes`](s/sieve_of_eratosthenes/README.md); no duplicate package |
| [`Shootout/strcat/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/strcat/info.sh) | `strcat` | Newly implemented in this batch |

### Stanford

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`Stanford/Bubblesort/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Bubblesort/info.sh) | `Bubblesort` | Partial/related: same bubble-sort algorithm as [`bubble_sort`](b/bubble_sort/README.md); no duplicate package |
| [`Stanford/FloatMM/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/FloatMM/info.sh) | `FloatMM` | Partial/related: same row-by-column matrix multiplication as [`matrix_multiplication`](m/matrix_multiplication/README.md); no duplicate package |
| [`Stanford/IntMM/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/IntMM/info.sh) | `IntMM` | Partial/related: same row-by-column matrix multiplication as [`matrix_multiplication`](m/matrix_multiplication/README.md); no duplicate package |
| [`Stanford/Oscar/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Oscar/info.sh) | `Oscar` | Pending semantic review/implementation |
| [`Stanford/Puzzle/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Puzzle/info.sh) | `Puzzle` | Pending semantic review/implementation |
| [`Stanford/Queens/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Queens/info.sh) | `Queens` | Newly implemented in this batch |
| [`Stanford/Quicksort/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Quicksort/info.sh) | `Quicksort` | Partial/related: same quicksort algorithm as [`quick_sort`](q/quick_sort/README.md); no duplicate package |
| [`Stanford/RealMM/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/RealMM/info.sh) | `RealMM` | Partial/related: same row-by-column matrix multiplication as [`matrix_multiplication`](m/matrix_multiplication/README.md); no duplicate package |
| [`Stanford/Towers/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Towers/info.sh) | `Towers` | Partial/related: same Tower of Hanoi recurrence as [`tower_of_hanoi`](t/tower_of_hanoi/README.md); no duplicate package |
| [`Stanford/Treesort/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Treesort/info.sh) | `Treesort` | Partial/related: same BST-based tree-sort structure as [`tree_sort`](t/tree_sort/README.md); no duplicate package |

### TSVC

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`TSVC/ControlFlow-dbl/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/ControlFlow-dbl/info.sh) | `ControlFlow-dbl` | Pending semantic review/implementation |
| [`TSVC/ControlFlow-flt/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/ControlFlow-flt/info.sh) | `ControlFlow-flt` | Pending semantic review/implementation |
| [`TSVC/ControlLoops-dbl/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/ControlLoops-dbl/info.sh) | `ControlLoops-dbl` | Pending semantic review/implementation |
| [`TSVC/ControlLoops-flt/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/ControlLoops-flt/info.sh) | `ControlLoops-flt` | Pending semantic review/implementation |
| [`TSVC/CrossingThresholds-dbl/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/CrossingThresholds-dbl/info.sh) | `CrossingThresholds-dbl` | Pending semantic review/implementation |
| [`TSVC/CrossingThresholds-flt/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/CrossingThresholds-flt/info.sh) | `CrossingThresholds-flt` | Pending semantic review/implementation |
| [`TSVC/Equivalencing-dbl/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Equivalencing-dbl/info.sh) | `Equivalencing-dbl` | Pending semantic review/implementation |
| [`TSVC/Equivalencing-flt/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Equivalencing-flt/info.sh) | `Equivalencing-flt` | Pending semantic review/implementation |
| [`TSVC/Expansion-dbl/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Expansion-dbl/info.sh) | `Expansion-dbl` | Pending semantic review/implementation |
| [`TSVC/Expansion-flt/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Expansion-flt/info.sh) | `Expansion-flt` | Pending semantic review/implementation |
| [`TSVC/GlobalDataFlow-dbl/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/GlobalDataFlow-dbl/info.sh) | `GlobalDataFlow-dbl` | Pending semantic review/implementation |
| [`TSVC/GlobalDataFlow-flt/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/GlobalDataFlow-flt/info.sh) | `GlobalDataFlow-flt` | Pending semantic review/implementation |
| [`TSVC/IndirectAddressing-dbl/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/IndirectAddressing-dbl/info.sh) | `IndirectAddressing-dbl` | Pending semantic review/implementation |
| [`TSVC/IndirectAddressing-flt/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/IndirectAddressing-flt/info.sh) | `IndirectAddressing-flt` | Pending semantic review/implementation |
| [`TSVC/InductionVariable-dbl/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/InductionVariable-dbl/info.sh) | `InductionVariable-dbl` | Pending semantic review/implementation |
| [`TSVC/InductionVariable-flt/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/InductionVariable-flt/info.sh) | `InductionVariable-flt` | Pending semantic review/implementation |
| [`TSVC/LinearDependence-dbl/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/LinearDependence-dbl/info.sh) | `LinearDependence-dbl` | Pending semantic review/implementation |
| [`TSVC/LinearDependence-flt/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/LinearDependence-flt/info.sh) | `LinearDependence-flt` | Pending semantic review/implementation |
| [`TSVC/LoopRerolling-dbl/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/LoopRerolling-dbl/info.sh) | `LoopRerolling-dbl` | Pending semantic review/implementation |
| [`TSVC/LoopRerolling-flt/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/LoopRerolling-flt/info.sh) | `LoopRerolling-flt` | Pending semantic review/implementation |
| [`TSVC/LoopRestructuring-dbl/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/LoopRestructuring-dbl/info.sh) | `LoopRestructuring-dbl` | Pending semantic review/implementation |
| [`TSVC/LoopRestructuring-flt/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/LoopRestructuring-flt/info.sh) | `LoopRestructuring-flt` | Pending semantic review/implementation |
| [`TSVC/NodeSplitting-dbl/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/NodeSplitting-dbl/info.sh) | `NodeSplitting-dbl` | Pending semantic review/implementation |
| [`TSVC/NodeSplitting-flt/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/NodeSplitting-flt/info.sh) | `NodeSplitting-flt` | Pending semantic review/implementation |
| [`TSVC/Packing-dbl/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Packing-dbl/info.sh) | `Packing-dbl` | Pending semantic review/implementation |
| [`TSVC/Packing-flt/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Packing-flt/info.sh) | `Packing-flt` | Pending semantic review/implementation |
| [`TSVC/Recurrences-dbl/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Recurrences-dbl/info.sh) | `Recurrences-dbl` | Pending semantic review/implementation |
| [`TSVC/Recurrences-flt/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Recurrences-flt/info.sh) | `Recurrences-flt` | Pending semantic review/implementation |
| [`TSVC/Reductions-dbl/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Reductions-dbl/info.sh) | `Reductions-dbl` | Pending semantic review/implementation |
| [`TSVC/Reductions-flt/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Reductions-flt/info.sh) | `Reductions-flt` | Pending semantic review/implementation |
| [`TSVC/Searching-dbl/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Searching-dbl/info.sh) | `Searching-dbl` | Pending semantic review/implementation |
| [`TSVC/Searching-flt/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Searching-flt/info.sh) | `Searching-flt` | Pending semantic review/implementation |
| [`TSVC/StatementReordering-dbl/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/StatementReordering-dbl/info.sh) | `StatementReordering-dbl` | Pending semantic review/implementation |
| [`TSVC/StatementReordering-flt/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/StatementReordering-flt/info.sh) | `StatementReordering-flt` | Pending semantic review/implementation |
| [`TSVC/Symbolics-dbl/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Symbolics-dbl/info.sh) | `Symbolics-dbl` | Pending semantic review/implementation |
| [`TSVC/Symbolics-flt/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/TSVC/Symbolics-flt/info.sh) | `Symbolics-flt` | Pending semantic review/implementation |

### Trimaran

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`Trimaran/enc-3des/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Trimaran/enc-3des/info.sh) | `enc-3des` | Partial/related: [`trimaran_enc_3des`](t/trimaran_enc_3des/README.md) covers the source's fixed three-key EDE block stage with one transform; the single-DES and two-key variants, repeated Monte Carlo profile, and CLI output are not represented. |
| [`Trimaran/enc-md5/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Trimaran/enc-md5/info.sh) | `enc-md5` | Partial/related: [`md5`](m/md5/README.md) implements the same MD5 digest operation in all nine languages; the launcher-specific deterministic 100,000-byte buffer, 512 incremental updates per digest, repeat-count profile, and hexadecimal printing are outside the local one-shot raw-byte digest contract. |
| [`Trimaran/enc-pc1/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Trimaran/enc-pc1/info.sh) | `enc-pc1` | Pending semantic review/implementation |
| [`Trimaran/enc-rc4/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Trimaran/enc-rc4/info.sh) | `enc-rc4` | Newly implemented in this batch |
| [`Trimaran/netbench-crc/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Trimaran/netbench-crc/info.sh) | `netbench-crc` | Newly implemented in this batch |
| [`Trimaran/netbench-url/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Trimaran/netbench-url/info.sh) | `netbench-url` | Partial/related: [`trimaran_netbench_url_internet_checksum`](t/trimaran_netbench_url_internet_checksum/README.md) ports only `internet_checksum` from `url.c`; URL routing rules, packet generation, Boyer–Moore search, and launcher output remain outside the profile. |

### VersaBench

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`VersaBench/8b10b/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/8b10b/info.sh) | `8b10b` | Newly implemented in this batch |
| [`VersaBench/beamformer/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/beamformer/info.sh) | `beamformer` | Partial/related: [`versabench_beamformer`](b/versabench_beamformer/README.md) covers the standalone complex `BeamForm` stage; the full launcher also runs FIR decimation, magnitude, and detector stages. |
| [`VersaBench/bmm/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/bmm/info.sh) | `bmm` | Newly implemented in this batch | [`bmm`](b/bmm/README.md): bounded source-order blocked matrix multiply with the fixed LCG matrices and final `printf` sum; the HP license limits use and redistribution. |
| [`VersaBench/dbms/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/dbms/info.sh) | `dbms` | Pending semantic review/implementation |
| [`VersaBench/ecbdes/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/ecbdes/info.sh) | `ecbdes` | Pending semantic review/implementation |

### cBench

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`cBench/automotive_bitcount/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/automotive_bitcount/src/info.sh) | `automotive_bitcount` | Partial/related: the same seven bit-count algorithms as [`automotive_bitcount`](a/automotive_bitcount/README.md), with a different seed and launcher repetition profile. |
| [`cBench/automotive_qsort1/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/automotive_qsort1/src/info.sh) | `automotive_qsort1` | Partial/related: [`cbench_automotive_qsort1`](a/cbench_automotive_qsort1/README.md) implements the bounded 3D-vector distance-ordering kernel with the source quicksort; it does not reproduce the launcher's multi-dataset file input, repeat counts, or sampled output file. |
| [`cBench/automotive_susan_c/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/automotive_susan_c/src/info.sh) | `automotive_susan_c` | Pending semantic review/implementation |
| [`cBench/automotive_susan_e/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/automotive_susan_e/src/info.sh) | `automotive_susan_e` | Pending semantic review/implementation |
| [`cBench/automotive_susan_s/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/automotive_susan_s/src/info.sh) | `automotive_susan_s` | Pending semantic review/implementation |
| [`cBench/bzip2d/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/bzip2d/src/info.sh) | `bzip2d` | Pending semantic review/implementation |
| [`cBench/bzip2e/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/bzip2e/src/info.sh) | `bzip2e` | Pending semantic review/implementation |
| [`cBench/consumer_jpeg_c/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/consumer_jpeg_c/src/info.sh) | `consumer_jpeg_c` | Pending semantic review/implementation |
| [`cBench/consumer_jpeg_d/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/consumer_jpeg_d/src/info.sh) | `consumer_jpeg_d` | Pending semantic review/implementation |
| [`cBench/consumer_lame/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/consumer_lame/src/info.sh) | `consumer_lame` | Pending semantic review/implementation |
| [`cBench/consumer_mad/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/consumer_mad/src/info.sh) | `consumer_mad` | Pending semantic review/implementation |
| [`cBench/consumer_tiff2bw/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/consumer_tiff2bw/src/info.sh) | `consumer_tiff2bw` | Pending semantic review/implementation |
| [`cBench/consumer_tiff2rgba/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/consumer_tiff2rgba/src/info.sh) | `consumer_tiff2rgba` | Pending semantic review/implementation |
| [`cBench/consumer_tiffdither/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/consumer_tiffdither/src/info.sh) | `consumer_tiffdither` | Pending semantic review/implementation |
| [`cBench/consumer_tiffmedian/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/consumer_tiffmedian/src/info.sh) | `consumer_tiffmedian` | Pending semantic review/implementation |
| [`cBench/network_dijkstra/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/network_dijkstra/src/info.sh) | `network_dijkstra` | Pending semantic review/implementation |
| [`cBench/network_patricia/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/network_patricia/src/info.sh) | `network_patricia` | Partial/related: same Patricia implementation as MiBench `network-patricia` (with `memmove` replacing `bcopy`); both map to [`radix_tree`](r/radix_tree/README.md), so there is no separate package. |
| [`cBench/office_ghostscript/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/office_ghostscript/src/info.sh) | `office_ghostscript` | Pending semantic review/implementation |
| [`cBench/office_ispell/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/office_ispell/src/info.sh) | `office_ispell` | Pending semantic review/implementation |
| [`cBench/office_rsynth/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/office_rsynth/src/info.sh) | `office_rsynth` | Pending semantic review/implementation |
| [`cBench/office_stringsearch1/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/office_stringsearch1/src/info.sh) | `office_stringsearch1` | Pending semantic review/implementation |
| [`cBench/security_blowfish_d/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/security_blowfish_d/src/info.sh) | `security_blowfish_d` | Pending semantic review/implementation |
| [`cBench/security_blowfish_e/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/security_blowfish_e/src/info.sh) | `security_blowfish_e` | Pending semantic review/implementation |
| [`cBench/security_pgp_d/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/security_pgp_d/src/info.sh) | `security_pgp_d` | Pending semantic review/implementation |
| [`cBench/security_pgp_e/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/security_pgp_e/src/info.sh) | `security_pgp_e` | Pending semantic review/implementation |
| [`cBench/security_rijndael_d/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/security_rijndael_d/src/info.sh) | `security_rijndael_d` | Pending semantic review/implementation |
| [`cBench/security_rijndael_e/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/security_rijndael_e/src/info.sh) | `security_rijndael_e` | Pending semantic review/implementation |
| [`cBench/security_sha/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/security_sha/src/info.sh) | `security_sha` | Pending semantic review/implementation |
| [`cBench/telecom_CRC32/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/telecom_CRC32/src/info.sh) | `telecom_CRC32` | Partial/related: the same reflected IEEE CRC-32 table recurrence as [`crc32`](c/crc32/README.md); its cBench dataset wrapper is a launcher profile. |
| [`cBench/telecom_adpcm_c/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/telecom_adpcm_c/src/info.sh) | `telecom_adpcm_c` | Pending semantic review/implementation |
| [`cBench/telecom_adpcm_d/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/telecom_adpcm_d/src/info.sh) | `telecom_adpcm_d` | Pending semantic review/implementation |
| [`cBench/telecom_gsm/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/telecom_gsm/src/info.sh) | `telecom_gsm` | Pending semantic review/implementation |

### llubenchmark

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`llubenchmark/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/llubenchmark/info.sh) | `llu` | Pending semantic review/implementation |

### mafft

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`mafft/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mafft/info.sh) | `mafft` | Pending semantic review/implementation |

### mediabench

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`mediabench/adpcm/rawcaudio/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mediabench/adpcm/rawcaudio/info.sh) | `adpcm-rawcaudio` | Pending semantic review/implementation |
| [`mediabench/adpcm/rawdaudio/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mediabench/adpcm/rawdaudio/info.sh) | `adpcm-rawdaudio` | Pending semantic review/implementation |
| [`mediabench/g721/g721encode/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mediabench/g721/g721encode/info.sh) | `g721` | Pending semantic review/implementation |
| [`mediabench/gsm/toast/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mediabench/gsm/toast/info.sh) | `gsm` | Pending semantic review/implementation |
| [`mediabench/jpeg/jpeg-6a/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mediabench/jpeg/jpeg-6a/info.sh) | `jpeg-6a` | Pending semantic review/implementation |
| [`mediabench/mpeg2/mpeg2dec/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/mediabench/mpeg2/mpeg2dec/info.sh) | `mpeg2` | Pending semantic review/implementation |

### nbench

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`nbench/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/nbench/info.sh) | `nbench` | Pending semantic review/implementation |

### sim

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`sim/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/sim/info.sh) | `sim` | Pending semantic review/implementation |

### test

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`test/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/test/info.sh) | `test` | Pending semantic review/implementation |

### tramp3d-v4

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`tramp3d-v4/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/tramp3d-v4/info.sh) | `tramp3d-v4` | Pending semantic review/implementation |

## Coverage notes

- The launcher inventory has 273 records across 36 top-level suites. Large suites such as TSVC, cBench, PolyBench, Misc, and Prolangs-C remain pending unless an inspected row above establishes a local relationship.
- A local package can share the same named algorithm and still be only partial when the upstream executable measures a different variant, representation, domain, or output contract.
- No pending row is asserted to be absent with certainty; those entries need source inspection before a package match or new implementation is assigned.
