# ANSIbench coverage and algorithm crosswalk

The source inventory is pinned to [nfinit/ansibench commit `ef90abd09d7b7bb1f2809f896d6f67fb9724bebe`](https://github.com/nfinit/ansibench/tree/ef90abd09d7b7bb1f2809f896d6f67fb9724bebe). This crosswalk covers its benchmarkable algorithm kernels and synthetic benchmark cores. Each newly added package documents its bounded contract, workload, oracle, source attribution, and implementations in C, C3, C++, Elisa, Nim, Odin, Rust, V, and Zig.

The pinned revision has no remaining unrepresented benchmarkable kernel: every algorithm family in this inventory maps to a local suite package below.

The local contracts are portable algorithm workloads; they do not claim comparable ANSIbench scores. Upstream timers, makefiles, platform presets, and reporting code are not part of an algorithm kernel.

## Classic benchmarks

| ANSIbench source | Local coverage | Scope |
| --- | --- | --- |
| [LINPACK](https://github.com/nfinit/ansibench/tree/ef90abd09d7b7bb1f2809f896d6f67fb9724bebe/linpack) | [LINPACK LU solve profile](l/linpack_lu_solve/README.md), [LU decomposition](l/lu_decompose/README.md), [pivoted LU decomposition](l/lu_pivot_decomposition/README.md), and [LU elimination/solve](l/lu_elimination/README.md) | The dedicated profile follows ANSIbench's rolled `dgefa`/`dgesl` solve path. Existing packages cover additional LU decomposition families. |
| [STREAM](https://github.com/nfinit/ansibench/tree/ef90abd09d7b7bb1f2809f896d6f67fb9724bebe/stream) | [STREAM vector kernels](s/stream_vector_kernels/README.md) | Bounded portable copy, scale, add, and triad loops over signed 64-bit vectors; not an official bandwidth result. |
| [Whetstone](https://github.com/nfinit/ansibench/tree/ef90abd09d7b7bb1f2809f896d6f67fb9724bebe/whetstone) | [ANSIbench Whetstone kernel](a/ansibench_whetstone/README.md) | A deterministic bounded pass through the source's operation mix; excludes timing and the official score. |
| [Dhrystone](https://github.com/nfinit/ansibench/tree/ef90abd09d7b7bb1f2809f896d6f67fb9724bebe/dhrystone) | [ANSIbench Dhrystone kernel](a/ansibench_dhrystone/README.md) | A deterministic bounded pass through the source's record, string, array, and control-flow workload; excludes timing and the official score. |

## NBench

| NBench kernel | Local coverage |
| --- | --- |
| Numeric sort (heapsort core) | [Heap sort](h/heap_sort/README.md) |
| String sort | [NBench string heap sort](s/string_heap_sort/README.md) |
| Bitfield | [Bitmap block allocation](b/bitmap_block_allocation/README.md) |
| Emulated floating point | [NBench emulated floating-point arithmetic](n/nbench_emulated_float_arithmetic/README.md) |
| Fourier coefficients | [NBench Fourier coefficients](n/nbench_fourier_coefficients/README.md) |
| Assignment | [NBench resource assignment](n/nbench_resource_assignment/README.md) |
| Huffman compression | [NBench Huffman compression](n/nbench_huffman_compression/README.md) |
| IDEA | [IDEA encrypt/decrypt](i/idea_encrypt_decrypt/README.md) |
| Neural network | [NBench neural-network kernel](n/nbench_neural_network/README.md) |
| LU decomposition | [LU decomposition](l/lu_decompose/README.md) and [pivoted LU decomposition](l/lu_pivot_decomposition/README.md) |

The NBench entries use deterministic bounded contracts rather than the original timing driver and score aggregation.

## CoreMark, HINT, and tripforce

| ANSIbench source kernel | Local coverage | Scope |
| --- | --- | --- |
| CoreMark list processing | [Embedded list stress](e/embedded_list_stress/README.md) | Bounded linked-list operations from the CoreMark list workload. |
| CoreMark matrix manipulation | [CoreMark matrix manipulation](m/coremark_matrix_manipulation/README.md) | Bounded source-ordered matrix operation pipeline, distinct from general matrix multiplication. |
| CoreMark state machine | [Numeric token state machine](n/numeric_token_state_machine/README.md) | Bounded printable-ASCII state-machine workload. |
| CoreMark CRC helpers | [CoreMark CRC](c/coremark_crc/README.md) | `crcu8`, `crcu16`, `crcu32`, and `crc16`; separate from the local CRC-16/CCITT-FALSE contract. |
| HINT area-refinement kernel | [HINT area bound refinement](h/hint_area_bound_refinement/README.md) | Bounded integer refinement kernel; not the full HINT score. |
| tripforce | [Tripforce tripcode](t/tripforce_tripcode/README.md) | One fixed candidate's tripcode computation; not brute-force candidate throughput. |

The associated source project describes LINPACK, STREAM, Whetstone, Dhrystone, NBench, CoreMark, and HINT in its [README](https://github.com/nfinit/ansibench/blob/ef90abd09d7b7bb1f2809f896d6f67fb9724bebe/README.md). The algorithm-specific guides link to the exact source files and preserve each source's applicable license notice.
