# Brent method for univariate extrema

Find the location of a bracketed minimum of a bounded smooth function. The shared benchmark uses three deterministic objective identifiers so every language receives the same function through a plain C ABI:

| Third input | Objective minimized | Unique extremum location |
| --- | --- | --- |
| `0.0` | `(x - 2)^2` | minimum at `2` |
| `0.5` | `cos(x)` on `[0, 2π]` | minimum at `π` |
| `1.0` | `-cos(x)` on `[π, 3π]` | minimum at `2π`, the maximum of `cos(x)` |

The function accepts `(left, right, objective_id)` as three binary64 values and returns the extremum's `x` coordinate. Endpoints may be given in either order. A valid bracket must lie in `[-10, 10]`, have width greater than `sqrt(DBL_EPSILON)`, and strictly contain the unique extremum for its objective. Invalid bounds, objective identifiers, or brackets return `-1.0`; all valid extremum coordinates are positive, so the sentinel is unambiguous. The search is limited to 256 iterations. Results are compared with input-scaled absolute tolerance.

Brent's method combines parabolic interpolation with a golden-section fallback when interpolation would leave the bracket or make insufficient progress. This makes it distinct from the sibling `golden_search_extrema` candidate, which uses golden-section reduction alone. It is also different from `ternary_search`, which searches for a target in a discrete sorted array. The pinned source accepts a general `std::function<double(double)>` and returns a minimizer; one example obtains a maximum by minimizing a negated objective. Its cosine test is labeled as a maximum but expects `π`, the minimum of `cos(x)`. The benchmark maps the callable to a small fixed set of objectives and bounds the valid brackets for deterministic cross-language measurement.

## Workload and recording

Cases cover the pinned quadratic example, a cosine minimum, a maximum through a negated objective, reversed endpoints, a narrow but valid bracket, and invalid objective/bracket/width/bounds. The ports use the shared `float64_triple` ABI.

```sh
python3 benchmarks/build_abi.py --family float64_triple --algorithm brent_method_extrema --language rust
python3 benchmarks/run_float64_triple.py --build-manifest build/float64_triple/b/brent_method_extrema/rust/build.json
```

## TheAlgorithms reference

- [C++ `brent_method_extrema.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/numerical_methods/brent_method_extrema.cpp)
- [C++ `golden_search_extrema.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/numerical_methods/golden_search_extrema.cpp)
