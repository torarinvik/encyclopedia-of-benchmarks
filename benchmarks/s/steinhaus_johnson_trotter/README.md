# Steinhaus–Johnson–Trotter permutations

Emit the input followed by every indexed permutation in the order produced by the pinned Rust implementation. This exact implementation sometimes swaps non-adjacent positions; the benchmark preserves its inversion-vector order rather than claiming the classic adjacent-swap property. Positions are distinct even when their values are equal, so duplicate-valued inputs produce duplicate rows and still emit exactly `n!` rows.

## Contract

- The `i32_array_bytes_output` input is a signed-i32 array of length 1 through 6.
- Output contains `n!` rows, each with `n` signed-i32 values, flattened row-major and serialized little-endian. The return value and output length are `4 * n! * n` bytes, at most 17,280.
- A null input or invalid length returns `-1`. A null output or capacity below the full output size returns `-2` without writing.
- The pinned inversion-vector order starts with the original array. It scans `i` upward from 1; if `inversion[i] < i`, it swaps positions `(0,i)` for even `i` and `(inversion[i],i)` for odd `i`, emits the row, increments that inversion entry, and resets `i` to 1. Otherwise it resets the entry and advances `i`.

For `[1, 2, 3]`, the pinned output order is `[1,2,3]`, `[2,1,3]`, `[3,1,2]`, `[1,3,2]`, `[2,3,1]`, `[3,2,1]`.

Source: [TheAlgorithms/Rust `steinhaus_johnson_trotter.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/general/permutations/steinhaus_johnson_trotter.rs).
