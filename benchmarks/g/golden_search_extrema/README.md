# Golden-section search for extrema

Find a bounded minimum by repeatedly reducing an interval with the golden-section search. This package uses the same minimization strategy as the pinned C++ source and remains distinct from Brent's interpolation-based extrema method.

## Contract

- `float64_triple` input is `[objective_id, left, right]`.
- Objective `0` is `(x - 2)^2`; both endpoints must be in `[0, 4]` and strictly bracket `2`.
- Objective `1` is `cos(x)`; both endpoints must be in `[2, 4]` and strictly bracket π.
- Endpoints may be supplied in either order. After normalization, interval width must be at least `2e-7`. This lower bound avoids the source's one-iteration case, where its initial prior midpoint is positive infinity, and ensures the returned prior midpoint is finite.
- The search uses the source threshold `1e-7`, a bounded 128-iteration cap, and returns the prior midpoint from the final update, matching the source's `prev_mean` behavior. Invalid IDs, bounds, or brackets return `-1.0`; valid extrema are positive, so the sentinel is unambiguous.
- The workload records the source recurrence's previous midpoint for valid cases and uses the runner's `input_scaled_tolerance` to compare the nine language implementations.

## Source semantics

The pinned `get_minima` function compares two golden-section points, keeps the lower-valued side, and stops when the interval width is at most `1e-7`. It returns the midpoint from the previous iteration rather than the final midpoint. The C++ sources spell the golden ratio as a `float` literal, which widens to `1.61803400516510009765625`; all ports use that source constant. The source also prints iteration counts from its test harness; that console output is outside the benchmark function. The source's test suite includes objectives with domains or brackets that are not suitable for a deterministic shared contract, so this benchmark uses two smooth objectives with known unique minima inside the bounded intervals above.

## Workload and build

[`workload.json`](workload.json) covers the quadratic minimum, cosine minimum, reversed endpoints, a narrow valid interval, and invalid IDs, brackets, and widths.

```sh
python3 benchmarks/build_abi.py --family float64_triple --algorithm golden_search_extrema --language rust
python3 benchmarks/run_float64_triple.py --build-manifest build/float64_triple/g/golden_search_extrema/rust/build.json
```

## Pinned sources

- [C++ `golden_search_extrema.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/numerical_methods/golden_search_extrema.cpp)
- [Duplicate C++ source in C-Plus-Plus-1](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/numerical_methods/golden_search_extrema.cpp)

## Ports

| Language | Source |
| --- | --- |
| C | [`c/g/golden_search_extrema.c`](../../../c/g/golden_search_extrema.c) |
| C3 | [`c3/g/golden_search_extrema.c3`](../../../c3/g/golden_search_extrema.c3) |
| C++ | [`cpp/g/golden_search_extrema.cpp`](../../../cpp/g/golden_search_extrema.cpp) |
| Elisa | [`elisa/g/golden_search_extrema.elisa`](../../../elisa/g/golden_search_extrema.elisa) |
| Nim | [`nim/g/golden_search_extrema.nim`](../../../nim/g/golden_search_extrema.nim) |
| Odin | [`odin/g/golden_search_extrema.odin`](../../../odin/g/golden_search_extrema.odin) |
| Rust | [`rust/g/golden_search_extrema.rs`](../../../rust/g/golden_search_extrema.rs) |
| V | [`v/g/golden_search_extrema.v`](../../../v/g/golden_search_extrema.v) |
| Zig | [`zig/g/golden_search_extrema.zig`](../../../zig/g/golden_search_extrema.zig) |
