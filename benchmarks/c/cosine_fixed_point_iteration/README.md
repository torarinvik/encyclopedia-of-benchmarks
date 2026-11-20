# Cosine fixed-point iteration

This profile replays the successive-approximation map used by TheAlgorithms/C-Plus-Plus:

\[
x_{k+1}=g(x_k)=\frac{\cos(x_k)+2}{2},
\qquad 3x-\cos(x)-2=0.
\]

Input is the `float64_pair` `[initial_x, source_n]`. The initial value must be finite and in `[0,2]`; `source_n` must be a finite integer-valued binary64 number in `[0,64]`. The source loop uses `i <= n`, so the profile performs exactly `source_n + 1` updates. It returns the last iterate without an early stopping rule. Invalid input returns `-1.0`.

The interval `[0,2]` is invariant under this map, and `|g'(x)|=|sin(x)|/2 <= 1/2` there. Thus the map is a contraction with a unique fixed point. This profile measures the fixed-point iteration itself; local bisection, Newton, false-position, Brent, and golden-section profiles use different update procedures. The local HITS fixed-point profile computes graph authority/hub scores and has a different state and output.

The bounded workload includes the source's zero-based update-count convention, interval endpoints, the maximum iteration count, and invalid range/count inputs. The primary reference uses the host binary64 cosine function. The independent reference evaluates cosine through a high-precision Taylor recurrence in `Decimal`; it shares the mathematical map but uses a separate numerical evaluation path.

| Language | Port |
|---|---|
| C | [`c/cosine_fixed_point_iteration.c`](../../../c/cosine_fixed_point_iteration.c) |
| C3 | [`c3/cosine_fixed_point_iteration.c3`](../../../c3/cosine_fixed_point_iteration.c3) |
| C++ | [`cpp/cosine_fixed_point_iteration.cpp`](../../../cpp/cosine_fixed_point_iteration.cpp) |
| Elisa | [`elisa/cosine_fixed_point_iteration.elisa`](../../../elisa/cosine_fixed_point_iteration.elisa) |
| Mojo | [`mojo/cosine_fixed_point_iteration.mojo`](../../../mojo/cosine_fixed_point_iteration.mojo) |
| Nim | [`nim/cosine_fixed_point_iteration.nim`](../../../nim/cosine_fixed_point_iteration.nim) |
| Odin | [`odin/cosine_fixed_point_iteration.odin`](../../../odin/cosine_fixed_point_iteration.odin) |
| Rust | [`rust/cosine_fixed_point_iteration.rs`](../../../rust/cosine_fixed_point_iteration.rs) |
| V | [`v/cosine_fixed_point_iteration.v`](../../../v/cosine_fixed_point_iteration.v) |
| Zig | [`zig/cosine_fixed_point_iteration.zig`](../../../zig/cosine_fixed_point_iteration.zig) |

## Provenance

- Discovery and concrete map: [TheAlgorithms/C-Plus-Plus `successive_approximation.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/master/numerical_methods/successive_approximation.cpp).
- General fixed-point recurrence and numerical-analysis context: [Applied Numerical Analysis, §1.5](https://www.cse.iitm.ac.in/~vplab/downloads/opt/Applied%20Numerical%20Analysis.pdf).
- The upstream repository identifies its implementation license as MIT. This package uses the algorithm and equation as references only; it contains independently written ports and references, with no source code or prose copied.

See [`workload.json`](workload.json), [`primary_oracle.py`](primary_oracle.py), [`independent_oracle.py`](independent_oracle.py), and [`INVENTORY.md`](INVENTORY.md).
