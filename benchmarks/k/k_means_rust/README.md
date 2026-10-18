# K-means (randomized Rust source variant)

This benchmark preserves the pinned Rust function's random two-dimensional center initialization and fixed iteration count. The adapter supplies an explicit deterministic draw stream so each workload call has a stable result.

## Contract

- Input is `[4, max_iter, x_draw0, 0, x_draw1, 0, x0, x1, x2, x3]`. The two draw coordinates are unsigned 53-bit integers converted to binary64 fractions by dividing by `2^53`; their y draws must be zero.
- The source uses `k = 2`, draws `(x,y)` for each center in order, assigns each point to its nearest center with ties going to the earlier center, updates nonempty center means, and returns labels after exactly `max_iter` passes.
- Data are four strictly increasing integer x coordinates in `[-16,16]`, with the first two negative and the last two greater than one. This keeps both clusters nonempty for either center draw order. All y coordinates are zero.
- Return one bit per point, `sum(label[i] << i)`. `max_iter` is 1 through 16; malformed input returns `-1`.

See the [workload](workload.json) and [oracle](../../k_means_rust_oracle.py).

## Pinned source

[`k_means.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/machine_learning/k_means.rs), commit `fed66cb0c74c4a939ec5163648458a8c2b46fd4c`, function `k_means`.
