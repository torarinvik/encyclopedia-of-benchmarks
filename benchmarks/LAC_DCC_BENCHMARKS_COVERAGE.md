# lac-dcc/Benchmarks launcher crosswalk

This inventory maps all 273 launcher records from `/tmp/lac-dcc-benchmarks-info-full.tsv` to local benchmark packages conservatively. Upstream paths are linked at pinned commit [5d7b75df749241efa7a6e6f5be613d3fcc5cce38](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38); its root tree SHA is `4ecc50e54cbf265d2803deb53e9c3badd004893b`. The snapshot is the complete 273-record inventory.

A matching name alone is not evidence of coverage. “Exact local semantic match” means the local package implements the same core operation for its supported input domain. “Partial/related” records an inspected overlap with a material contract or algorithm difference. “Newly implemented in this batch” means a local package and source-backed contract are present; this document does not claim runtime validation. All other rows remain pending source/semantic review and, where needed, implementation.

## Reviewed crosswalk

| Upstream launcher path | Executable | Status | Local package / reason |
|---|---|---|---|
| `BenchmarkGame/fannkuch/info.sh` | `fannkuch` | Newly implemented in this batch | [`fannkuch`](f/fannkuch/README.md): bounded counter-driven prefix-reversal maximum. |
| `BenchmarkGame/n-body/info.sh` | `nbody` | Partial/related | [`n_body_simulation`](n/n_body_simulation/README.md) is 2D and softened; upstream is fixed 3D solar-system integration. |
| `BenchmarkGame/nsieve-bits/info.sh` | `nsieve-bits` | Partial/related | [`sieve_of_eratosthenes`](s/sieve_of_eratosthenes/README.md) uses a boolean sieve and one small limit; upstream uses packed bits and three large limits. |
| `BenchmarkGame/partialsums/info.sh` | `partialsums` | Newly implemented in this batch | [`partialsums`](p/partialsums/README.md): nine sums in source order, bounded to `n<=10000`. |
| `BenchmarkGame/puzzle/info.sh` | `puzzle` | Partial/related | [`find_duplicate_number`](f/find_duplicate_number/README.md) returns the same kind of result, but uses Floyd cycle entry; upstream uses deterministic array generation and XOR cancellation. |
| `BenchmarkGame/recursive/info.sh` | `recursive` | Partial/related | [`ackermann`](a/ackermann/README.md) and [`fibonacci_recursive`](f/fibonacci_recursive/README.md) cover only some components, with different bounds/recurrences; Takeuchi is missing. |
| `BenchmarkGame/spectral-norm/info.sh` | `spectral-norm` | Newly implemented in this batch | [`spectral_norm`](s/spectral_norm/README.md): ten paired `AᵀA` multiplications on the implicit source matrix. |
| `PolyBench/linear-algebra/solvers/gramschmidt/info.sh` | `gramschmidt` | Partial/related | [`gram_schmidt`](g/gram_schmidt/README.md): same method, but matrix and output contracts differ. |
| `PolyBench/medley/floyd-warshall/info.sh` | `floyd-warshall` | Partial/related | [`floyd_warshall`](f/floyd_warshall/README.md): same recurrence, local contract returns a requested source row. |
| `Shootout/ackermann/info.sh` | `ackermann` | Partial/related | [`ackermann`](a/ackermann/README.md): same recurrence, but upstream calls `A(3,11)`, outside the local bound. |
| `Shootout/heapsort/info.sh` | `heapsort` | Partial/related | [`heap_sort`](h/heap_sort/README.md): same heap-sort operation; upstream sorts generated doubles and prints only the maximum. |
| `Stanford/Bubblesort/info.sh` | `Bubblesort` | Partial/related | [`bubble_sort`](b/bubble_sort/README.md): same adjacent-swap family; upstream runs a fixed generated workload and prints selected ranks. |
| `Stanford/Quicksort/info.sh` | `Quicksort` | Partial/related | [`quick_sort`](q/quick_sort/README.md): same sort family, different pivot and partition scheme. |
| `Stanford/Treesort/info.sh` | `Treesort` | Partial/related | [`tree_sort`](t/tree_sort/README.md): same BST-sort family, but upstream drops duplicate keys while local preserves them. |
| `NPB-serial/is/info.sh` | `is` | Pending semantic review/implementation | Same-name collision: local [`is`](i/is/README.md) is a uint53 predicate, not NPB integer sort. |
| `Olden/perimeter/info.sh` | `perimeter` | Pending semantic review/implementation | Same-name collision: local [`perimeter`](p/perimeter/README.md) computes regular-polygon perimeter. |
| `PolyBench/datamining/correlation/info.sh` | `correlation` | Pending semantic review/implementation | Same-name collision: local [`correlation`](c/correlation/README.md) is a scalar Java-specific formula, not the matrix kernel. |

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
| [`BenchmarkGame/n-body/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BenchmarkGame/n-body/info.sh) | `nbody` | Partial/related |
| [`BenchmarkGame/nsieve-bits/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BenchmarkGame/nsieve-bits/info.sh) | `nsieve-bits` | Partial/related |
| [`BenchmarkGame/partialsums/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BenchmarkGame/partialsums/info.sh) | `partialsums` | Newly implemented in this batch |
| [`BenchmarkGame/puzzle/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BenchmarkGame/puzzle/info.sh) | `puzzle` | Partial/related |
| [`BenchmarkGame/recursive/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BenchmarkGame/recursive/info.sh) | `recursive` | Partial/related |
| [`BenchmarkGame/spectral-norm/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BenchmarkGame/spectral-norm/info.sh) | `spectral-norm` | Newly implemented in this batch |

### BitBench

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`BitBench/drop3/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BitBench/drop3/info.sh) | `drop3` | Pending semantic review/implementation |
| [`BitBench/five11/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BitBench/five11/info.sh) | `five11` | Pending semantic review/implementation |
| [`BitBench/uudecode/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BitBench/uudecode/info.sh) | `uudecode` | Pending semantic review/implementation |
| [`BitBench/uuencode/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BitBench/uuencode/info.sh) | `uuencode` | Pending semantic review/implementation |

### CoyoteBench

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`CoyoteBench/almabench/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/CoyoteBench/almabench/info.sh) | `almabench` | Pending semantic review/implementation |
| [`CoyoteBench/huffbench/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/CoyoteBench/huffbench/info.sh) | `huffbench` | Pending semantic review/implementation |
| [`CoyoteBench/lpbench/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/CoyoteBench/lpbench/info.sh) | `lpbench` | Pending semantic review/implementation |

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
| [`Linpack/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Linpack/info.sh) | `Linpack` | Pending semantic review/implementation |

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
| [`McCat/01-qbsort/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/01-qbsort/info.sh) | `01-qbsort` | Pending semantic review/implementation |
| [`McCat/03-testtrie/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/03-testtrie/info.sh) | `03-testtrie` | Pending semantic review/implementation |
| [`McCat/04-bisect/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/04-bisect/info.sh) | `04-bisect` | Pending semantic review/implementation |
| [`McCat/05-eks/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/05-eks/info.sh) | `05-eks` | Pending semantic review/implementation |
| [`McCat/08-main/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/08-main/info.sh) | `08-main` | Pending semantic review/implementation |
| [`McCat/09-vor/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/09-vor/info.sh) | `09-vor` | Pending semantic review/implementation |
| [`McCat/12-IOtest/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/12-IOtest/info.sh) | `12-IOtest` | Pending semantic review/implementation |
| [`McCat/15-trie/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/15-trie/info.sh) | `15-trie` | Pending semantic review/implementation |
| [`McCat/17-bintr/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McCat/17-bintr/info.sh) | `17-bintr` | Pending semantic review/implementation |

### McGill

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`McGill/chomp/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McGill/chomp/info.sh) | `chomp` | Pending semantic review/implementation |
| [`McGill/exptree/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McGill/exptree/info.sh) | `exptree` | Pending semantic review/implementation |
| [`McGill/misr/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McGill/misr/info.sh) | `misr` | Pending semantic review/implementation |
| [`McGill/queens/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/McGill/queens/info.sh) | `queens` | Pending semantic review/implementation |

### MiBench

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`MiBench/automotive-basicmath/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/automotive-basicmath/info.sh) | `automotive-basicmath` | Pending semantic review/implementation |
| [`MiBench/automotive-bitcount/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/automotive-bitcount/info.sh) | `automotive-bitcount` | Pending semantic review/implementation |
| [`MiBench/automotive-susan/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/automotive-susan/info.sh) | `automotive-susan` | Pending semantic review/implementation |
| [`MiBench/consumer-jpeg/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/consumer-jpeg/info.sh) | `consumer-jpeg` | Pending semantic review/implementation |
| [`MiBench/consumer-lame/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/consumer-lame/info.sh) | `consumer-lame` | Pending semantic review/implementation |
| [`MiBench/network-dijkstra/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/network-dijkstra/info.sh) | `network-dijkstra` | Pending semantic review/implementation |
| [`MiBench/network-patricia/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/network-patricia/info.sh) | `network-patricia` | Pending semantic review/implementation |
| [`MiBench/office-stringsearch/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/office-stringsearch/info.sh) | `office-stringsearch` | Pending semantic review/implementation |
| [`MiBench/security-blowfish/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/security-blowfish/info.sh) | `security-blowfish` | Pending semantic review/implementation |
| [`MiBench/security-rijndael/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/security-rijndael/info.sh) | `security-rijndael` | Pending semantic review/implementation |
| [`MiBench/security-sha/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/security-sha/info.sh) | `security-sha` | Pending semantic review/implementation |
| [`MiBench/telecomm-CRC32/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/telecomm-CRC32/info.sh) | `telecomm-CRC32` | Pending semantic review/implementation |
| [`MiBench/telecomm-FFT/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/telecomm-FFT/info.sh) | `telecomm-FFT` | Pending semantic review/implementation |

### Misc

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`Misc/ReedSolomon/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/ReedSolomon/info.sh) | `ReedSolomon` | Pending semantic review/implementation |
| [`Misc/dt/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/dt/info.sh) | `dt` | Pending semantic review/implementation |
| [`Misc/evalloop/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/evalloop/info.sh) | `evalloop` | Pending semantic review/implementation |
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
| [`Misc/fp-convert/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/fp-convert/info.sh) | `fp-convert` | Pending semantic review/implementation |
| [`Misc/himenobmtxpa/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/himenobmtxpa/info.sh) | `himenobmtxpa` | Pending semantic review/implementation |
| [`Misc/lowercase/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/lowercase/info.sh) | `lowercase` | Pending semantic review/implementation |
| [`Misc/mandel-2/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/mandel-2/info.sh) | `mandel-2` | Pending semantic review/implementation |
| [`Misc/mandel/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/mandel/info.sh) | `mandel` | Pending semantic review/implementation |
| [`Misc/matmul_f64_4x4/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/matmul_f64_4x4/info.sh) | `matmul_f64_4x4` | Pending semantic review/implementation |
| [`Misc/oourafft/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/oourafft/info.sh) | `oourafft` | Pending semantic review/implementation |
| [`Misc/perlin/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/perlin/info.sh) | `perlin` | Pending semantic review/implementation |
| [`Misc/pi/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/pi/info.sh) | `pi` | Pending semantic review/implementation |
| [`Misc/revertBits/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/revertBits/info.sh) | `revertBits` | Pending semantic review/implementation |
| [`Misc/richards_benchmark/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/richards_benchmark/info.sh) | `richards_benchmark` | Pending semantic review/implementation |
| [`Misc/salsa20/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/salsa20/info.sh) | `salsa20` | Pending semantic review/implementation |
| [`Misc/whetstone/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/whetstone/info.sh) | `whetstone` | Pending semantic review/implementation |

### NPB-serial

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`NPB-serial/dc/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/NPB-serial/dc/info.sh) | `dc` | Pending semantic review/implementation |
| [`NPB-serial/is/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/NPB-serial/is/info.sh) | `is` | Pending semantic review/implementation |

### Olden

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`Olden/bh/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/bh/info.sh) | `bh` | Pending semantic review/implementation |
| [`Olden/bisort/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/bisort/info.sh) | `bisort` | Pending semantic review/implementation |
| [`Olden/em3d/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/em3d/info.sh) | `em3d` | Pending semantic review/implementation |
| [`Olden/health/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/health/info.sh) | `health` | Pending semantic review/implementation |
| [`Olden/mst/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/mst/info.sh) | `mst` | Pending semantic review/implementation |
| [`Olden/perimeter/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/perimeter/info.sh) | `perimeter` | Pending semantic review/implementation |
| [`Olden/power/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/power/info.sh) | `power` | Pending semantic review/implementation |
| [`Olden/treeadd/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/treeadd/info.sh) | `treeadd` | Pending semantic review/implementation |
| [`Olden/tsp/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/tsp/info.sh) | `tsp` | Pending semantic review/implementation |
| [`Olden/voronoi/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/voronoi/info.sh) | `voronoi` | Pending semantic review/implementation |

### PAQ8p

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`PAQ8p/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PAQ8p/info.sh) | `PAQ8p` | Pending semantic review/implementation |

### PolyBench

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`PolyBench/datamining/correlation/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/datamining/correlation/info.sh) | `correlation` | Pending semantic review/implementation |
| [`PolyBench/datamining/covariance/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/datamining/covariance/info.sh) | `covariance` | Pending semantic review/implementation |
| [`PolyBench/linear-algebra/blas/gemm/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/blas/gemm/info.sh) | `gemm` | Pending semantic review/implementation |
| [`PolyBench/linear-algebra/blas/gemver/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/blas/gemver/info.sh) | `gemver` | Pending semantic review/implementation |
| [`PolyBench/linear-algebra/blas/gesummv/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/blas/gesummv/info.sh) | `gesummv` | Pending semantic review/implementation |
| [`PolyBench/linear-algebra/blas/symm/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/blas/symm/info.sh) | `symm` | Pending semantic review/implementation |
| [`PolyBench/linear-algebra/blas/syr2k/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/blas/syr2k/info.sh) | `syr2k` | Pending semantic review/implementation |
| [`PolyBench/linear-algebra/blas/syrk/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/blas/syrk/info.sh) | `syrk` | Pending semantic review/implementation |
| [`PolyBench/linear-algebra/blas/trmm/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/blas/trmm/info.sh) | `trmm` | Pending semantic review/implementation |
| [`PolyBench/linear-algebra/kernels/2mm/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/kernels/2mm/info.sh) | `2mm` | Pending semantic review/implementation |
| [`PolyBench/linear-algebra/kernels/3mm/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/kernels/3mm/info.sh) | `3mm` | Pending semantic review/implementation |
| [`PolyBench/linear-algebra/kernels/atax/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/kernels/atax/info.sh) | `atax` | Pending semantic review/implementation |
| [`PolyBench/linear-algebra/kernels/bicg/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/kernels/bicg/info.sh) | `bicg` | Pending semantic review/implementation |
| [`PolyBench/linear-algebra/kernels/doitgen/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/kernels/doitgen/info.sh) | `doitgen` | Pending semantic review/implementation |
| [`PolyBench/linear-algebra/kernels/mvt/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/kernels/mvt/info.sh) | `mvt` | Pending semantic review/implementation |
| [`PolyBench/linear-algebra/solvers/cholesky/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/solvers/cholesky/info.sh) | `cholesky` | Pending semantic review/implementation |
| [`PolyBench/linear-algebra/solvers/durbin/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/solvers/durbin/info.sh) | `durbin` | Pending semantic review/implementation |
| [`PolyBench/linear-algebra/solvers/gramschmidt/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/solvers/gramschmidt/info.sh) | `gramschmidt` | Partial/related |
| [`PolyBench/linear-algebra/solvers/lu/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/solvers/lu/info.sh) | `lu` | Pending semantic review/implementation |
| [`PolyBench/linear-algebra/solvers/ludcmp/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/solvers/ludcmp/info.sh) | `ludcmp` | Pending semantic review/implementation |
| [`PolyBench/linear-algebra/solvers/trisolv/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/linear-algebra/solvers/trisolv/info.sh) | `trisolv` | Pending semantic review/implementation |
| [`PolyBench/medley/deriche/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/medley/deriche/info.sh) | `deriche` | Pending semantic review/implementation |
| [`PolyBench/medley/floyd-warshall/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/medley/floyd-warshall/info.sh) | `floyd-warshall` | Partial/related |
| [`PolyBench/medley/nussinov/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/medley/nussinov/info.sh) | `nussinov` | Pending semantic review/implementation |
| [`PolyBench/stencils/adi/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/stencils/adi/info.sh) | `adi` | Pending semantic review/implementation |
| [`PolyBench/stencils/fdtd-2d/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/stencils/fdtd-2d/info.sh) | `fdtd-2d` | Pending semantic review/implementation |
| [`PolyBench/stencils/heat-3d/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/stencils/heat-3d/info.sh) | `heat-3d` | Pending semantic review/implementation |
| [`PolyBench/stencils/jacobi-1d/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/stencils/jacobi-1d/info.sh) | `jacobi-1d` | Pending semantic review/implementation |
| [`PolyBench/stencils/jacobi-2d/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/stencils/jacobi-2d/info.sh) | `jacobi-2d` | Pending semantic review/implementation |
| [`PolyBench/stencils/seidel-2d/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/PolyBench/stencils/seidel-2d/info.sh) | `seidel-2d` | Pending semantic review/implementation |

### Prolangs-C

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`Prolangs-C/TimberWolfMC/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/TimberWolfMC/info.sh) | `TimerWolfMC` | Pending semantic review/implementation |
| [`Prolangs-C/agrep/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/agrep/info.sh) | `agrep` | Pending semantic review/implementation |
| [`Prolangs-C/allroots/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Prolangs-C/allroots/info.sh) | `allroots` | Pending semantic review/implementation |
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
| [`Shootout/ackermann/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/ackermann/info.sh) | `ackermann` | Partial/related |
| [`Shootout/ary3/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/ary3/info.sh) | `ary3` | Pending semantic review/implementation |
| [`Shootout/fib2/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/fib2/info.sh) | `fib2` | Pending semantic review/implementation |
| [`Shootout/hash/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/hash/info.sh) | `hash` | Pending semantic review/implementation |
| [`Shootout/heapsort/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/heapsort/info.sh) | `heapsort` | Partial/related |
| [`Shootout/hello/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/hello/info.sh) | `hello` | Pending semantic review/implementation |
| [`Shootout/lists/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/lists/info.sh) | `lists` | Pending semantic review/implementation |
| [`Shootout/matrix/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/matrix/info.sh) | `matrix` | Pending semantic review/implementation |
| [`Shootout/methcall/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/methcall/info.sh) | `methcall` | Pending semantic review/implementation |
| [`Shootout/nestedloop/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/nestedloop/info.sh) | `nestedloop` | Pending semantic review/implementation |
| [`Shootout/objinst/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/objinst/info.sh) | `objinst` | Pending semantic review/implementation |
| [`Shootout/random/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/random/info.sh) | `random` | Pending semantic review/implementation |
| [`Shootout/sieve/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/sieve/info.sh) | `sieve` | Pending semantic review/implementation |
| [`Shootout/strcat/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/strcat/info.sh) | `strcat` | Pending semantic review/implementation |

### Stanford

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`Stanford/Bubblesort/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Bubblesort/info.sh) | `Bubblesort` | Partial/related |
| [`Stanford/FloatMM/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/FloatMM/info.sh) | `FloatMM` | Pending semantic review/implementation |
| [`Stanford/IntMM/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/IntMM/info.sh) | `IntMM` | Pending semantic review/implementation |
| [`Stanford/Oscar/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Oscar/info.sh) | `Oscar` | Pending semantic review/implementation |
| [`Stanford/Puzzle/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Puzzle/info.sh) | `Puzzle` | Pending semantic review/implementation |
| [`Stanford/Queens/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Queens/info.sh) | `Queens` | Pending semantic review/implementation |
| [`Stanford/Quicksort/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Quicksort/info.sh) | `Quicksort` | Partial/related |
| [`Stanford/RealMM/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/RealMM/info.sh) | `RealMM` | Pending semantic review/implementation |
| [`Stanford/Towers/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Towers/info.sh) | `Towers` | Pending semantic review/implementation |
| [`Stanford/Treesort/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Stanford/Treesort/info.sh) | `Treesort` | Partial/related |

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
| [`Trimaran/enc-3des/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Trimaran/enc-3des/info.sh) | `enc-3des` | Pending semantic review/implementation |
| [`Trimaran/enc-md5/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Trimaran/enc-md5/info.sh) | `enc-md5` | Pending semantic review/implementation |
| [`Trimaran/enc-pc1/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Trimaran/enc-pc1/info.sh) | `enc-pc1` | Pending semantic review/implementation |
| [`Trimaran/enc-rc4/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Trimaran/enc-rc4/info.sh) | `enc-rc4` | Pending semantic review/implementation |
| [`Trimaran/netbench-crc/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Trimaran/netbench-crc/info.sh) | `netbench-crc` | Pending semantic review/implementation |
| [`Trimaran/netbench-url/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Trimaran/netbench-url/info.sh) | `netbench-url` | Pending semantic review/implementation |

### VersaBench

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`VersaBench/8b10b/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/8b10b/info.sh) | `8b10b` | Pending semantic review/implementation |
| [`VersaBench/beamformer/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/beamformer/info.sh) | `beamformer` | Pending semantic review/implementation |
| [`VersaBench/bmm/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/bmm/info.sh) | `bmm` | Pending semantic review/implementation |
| [`VersaBench/dbms/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/dbms/info.sh) | `dbms` | Pending semantic review/implementation |
| [`VersaBench/ecbdes/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/VersaBench/ecbdes/info.sh) | `ecbdes` | Pending semantic review/implementation |

### cBench

| Upstream launcher path | Executable | Crosswalk status |
|---|---|---|
| [`cBench/automotive_bitcount/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/automotive_bitcount/src/info.sh) | `automotive_bitcount` | Pending semantic review/implementation |
| [`cBench/automotive_qsort1/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/automotive_qsort1/src/info.sh) | `automotive_qsort1` | Pending semantic review/implementation |
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
| [`cBench/network_patricia/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/network_patricia/src/info.sh) | `network_patricia` | Pending semantic review/implementation |
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
| [`cBench/telecom_CRC32/src/info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/telecom_CRC32/src/info.sh) | `telecom_CRC32` | Pending semantic review/implementation |
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
