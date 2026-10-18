# K-means (Julia source variant)

This benchmark preserves the deterministic initialization and convergence behavior of the pinned Julia `cluster` function.

## Contract

- The `i64_array_scalar` input is `[n, x0, ..., x(n-1)]`, with exactly `n + 1` signed 64-bit words. `n` is 3 through 8; coordinates are strictly increasing integers in `[-16, 16]`.
- The adapter converts each coordinate to binary64, fixes `k = 2` and `iter = 0`, and initializes centers from Julia's one-based indices `1` and `floor(1 + n / 2)`.
- Each point is assigned to the nearest center using Euclidean distance. A tie stays with the earlier center. Each center becomes the arithmetic mean of its assigned points. Iteration stops when the center vectors compare equal; the adapter caps this at 64 moves and returns `-2` only if that cap is reached.
- Return the two source-ordered centers, each quantized by truncating `center * 256` toward zero. For each quantized center `q`, encode `q + 4097`; pack the result as `code0 * 8194 + code1`. Malformed input returns `-1`.

See the [workload](workload.json) and [oracle](../../k_means_julia_oracle.py).

## Pinned source

[`k_means.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/machine_learning/k_means.jl), commit `384424b762bbb40d43f31001beeca0c6ffda2f1f`, function `cluster`.
