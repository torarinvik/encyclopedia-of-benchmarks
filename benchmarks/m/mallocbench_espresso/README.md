# MallocBench Espresso bounded minimization profile

Espresso is a heuristic two-level Boolean and multi-valued PLA minimizer. The pinned MallocBench launcher runs its default `espresso(F,D,R)` path on a 16-input, 40-output PLA. That full workload is too large and too broad for a small portable ABI. This package isolates two core phases used by that path: cube expansion and irredundant-cover extraction for a bounded, single-output binary function.

## Contract

- Input is exactly `[variable_count, on_set_mask, dont_care_mask]`.
- `variable_count` is 1 through 5. Bit `k` of either mask describes minterm `k`; the least-significant minterm variable is variable 0.
- The masks are nonnegative signed 64-bit integers, contain no bits above the `2^variable_count` minterms, and are disjoint. Minterms in neither mask form the OFF-set.
- Begin with one minterm cube per ON point. In ascending minterm order, attempt to drop each variable literal in ascending variable order. Keep a deletion only when the expanded cube contains no OFF point. Then visit terms in their original order and remove each one whose ON points are already covered by other active terms.
- Return `1024 * cube_count + literal_count` for the resulting valid cover. The encoding gives cube count priority; at most 32 cubes and 160 literals fit without overlap between fields. It is a deterministic heuristic cover cost, not a claim of global optimality.
- Invalid shape, masks, or domains return `-1`. An empty ON-set returns zero.

This profile is deliberately narrower than the source executable. It preserves the source algorithm's EXPAND and IRREDUNDANT operations, but omits multi-output PLA parsing, essential-prime removal, the repeated REDUCE/EXPAND/IRREDUNDANT and LAST_GASP convergence loop, MAKE_SPARSE, command-line handling, and timing/output. It should therefore be read as a bounded source-phase benchmark, not as a port of the entire Berkeley Espresso optimizer or as a reproduction of `largest.espresso`'s result.

## Workload and oracle

[`workload.json`](workload.json) includes hand-checkable constant, minterm, adjacent-minterm, don't-care, and overlapping-cover cases plus malformed inputs. [`mallocbench_espresso_oracle.py`](../../mallocbench_espresso_oracle.py) is an independent Python implementation using explicit minterm sets.

## Provenance and rights

Source: [lac-dcc/Benchmarks `MallocBench/espresso`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MallocBench/espresso), pinned at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Its `info.sh` launches `-t INPUT/largest.espresso`; `main.c` selects the default Espresso operation; `espresso.c` invokes EXPAND, IRREDUNDANT, ESSENTIAL, REDUCE, LAST_GASP, and MAKE_SPARSE phases.

The source tree's `copyright.h` attributes the software to the Regents of the University of California (1988–1990), permits use, copying, and derivative works when the notice is retained, and disclaims warranties. The complete copyright and warranty notice is retained in each language port. These implementations are clean-room ports of the described bounded phase profile; no upstream source code or PLA input rows were copied. The pinned Espresso directory did not contain a separate license file at the checked `LICENSE.TXT` path.
