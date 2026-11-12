# Old Driver Tree / Chtholly Tree

This benchmark represents an array as ordered, maximal intervals of equal values. Range operations split intervals at their boundaries, update or replace the covered runs, and merge equal neighbors. The ports use sorted run arrays; the bounded low-level implementations use fixed-capacity storage, while C++ uses a vector.

## Bounded ABI

The exported symbol is `old_driver_tree` with the `i64_array_bytes_output` ABI:

```c
int64_t old_driver_tree(const int64_t *input, size_t length,
                       uint8_t *output, size_t capacity);
```

Input is `[N,Q,initial_values...,operations...]`, with `1 <= N <= 32`, `0 <= Q <= 32`, and initial values in `[-1000,1000]`. Every range is zero-based and inclusive. Operations have variable width:

| Opcode | Record | Meaning |
|---|---|---|
| `0` | `[0,left,right,value]` | Assign the range to `value`. |
| `1` | `[1,left,right,delta]` | Add `delta` to every value in the range. |
| `2` | `[2,left,right,k]` | Return the one-based `k`th smallest value in the range. |
| `3` | `[3,left,right,exponent,modulus]` | Return the sum of `value^exponent mod modulus` over the range, reduced modulo `modulus`. |

Update arguments are in `[-1000,1000]`; exponents are `0..8`; moduli are `1..1,000,000,000`. Repeated updates keep every current value within `[-33000,33000]`. Exponent zero returns one for each value before the sum is reduced, including when the value is zero.

Malformed input returns `-1`. For traces producing answers, a null output buffer or capacity below eight bytes per answer returns `-2` without writing. The maximum valid input is 194 signed 64-bit words (195 words are accepted by the parser to reject a trailing-word trace); output is at most 256 bytes. With no answer operations, success returns zero and permits a null output pointer.

## Algorithm and workload

The interval map keeps runs sorted by their left endpoint. It first splits at `right + 1`, then at `left`; assignment removes covered runs and inserts one replacement, while addition adjusts the covered runs. Both updates then coalesce adjacent equal-valued runs. A kth query gathers the intersecting values and sorts them; a power-sum query visits only intersecting runs and multiplies each modular power by its overlap length.

With `R` current runs, the array-backed ordered set takes `O(R)` for boundary insertion, removal, and coalescing. Assignment, addition, and power-sum work can therefore reach `Theta(NQ)` over a trace when operations preserve `Theta(N)` runs. Kth queries also sort at most `N` values, adding `O(N^2)` worst-case work in the simple insertion-sort ports. Randomized-like assignment traces often merge runs and reduce the amount of per-operation scanning, but the algorithm has no worst-case guarantee; carefully chosen alternating singleton assignments can keep the run count high. This construction sensitivity is the behavior the workload is intended to expose.

The primary oracle uses the same maximal-run interval representation. The independent oracle applies each update to a direct array and answers queries by sorting or scanning that array. Fixtures include mixed randomized-like assignments and additions, run coalescing, a one-element array, empty output, malformed inputs, and output-buffer errors. See [`workload.json`](workload.json), [`primary_oracle.py`](primary_oracle.py), and [`independent_oracle.py`](independent_oracle.py).

The candidate is distinct from the existing lazy segment trees, which keep a fixed tree decomposition with aggregate and lazy-tag nodes, and from `treap_unique_key_set`, which stores unique keys and has no range-run operations.

## Source and rights

Algorithm reference: [OI Wiki Old Driver Tree / ODT](https://en.oi-wiki.org/ds/odt/). OI Wiki records CC BY-SA 4.0 and SATA terms; see [RIGHTS.md](RIGHTS.md). Only the algorithm description informs these clean-room ports, fixtures, oracles, and documentation.

## Ports

| Language | Source |
|---|---|
| C | [`c/o/old_driver_tree.c`](../../../c/o/old_driver_tree.c) |
| C3 | [`c3/o/old_driver_tree.c3`](../../../c3/o/old_driver_tree.c3) |
| C++ | [`cpp/o/old_driver_tree.cpp`](../../../cpp/o/old_driver_tree.cpp) |
| Elisa | [`elisa/o/old_driver_tree.elisa`](../../../elisa/o/old_driver_tree.elisa) |
| Mojo | [`mojo/o/old_driver_tree.mojo`](../../../mojo/o/old_driver_tree.mojo) |
| Nim | [`nim/o/old_driver_tree.nim`](../../../nim/o/old_driver_tree.nim) |
| Odin | [`odin/o/old_driver_tree.odin`](../../../odin/o/old_driver_tree.odin) |
| Rust | [`rust/o/old_driver_tree.rs`](../../../rust/o/old_driver_tree.rs) |
| V | [`v/o/old_driver_tree.v`](../../../v/o/old_driver_tree.v) |
| Zig | [`zig/o/old_driver_tree.zig`](../../../zig/o/old_driver_tree.zig) |

The package-local static inventory and oracle checker is [`verify_workload.py`](verify_workload.py); it has not been run.
