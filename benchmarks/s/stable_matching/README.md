# Stable Matching

Compute the men-optimal stable matching for two equally sized groups with complete, strict preference lists.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[n, men_preferences[n*n], women_preferences[n*n]]`, with each side's rows flattened in participant-ID order. The exact length is `1 + 2*n*n` and `0 <= n <= 8`.
- Each row is a permutation of participant IDs `0..n-1`. Invalid length, size, ID, or duplicate within a row returns `-1` before output storage is checked.
- Use men-proposing deferred acceptance. Every free man proposes to his next-ranked woman; each woman keeps the more-preferred of her current partner and the new proposer. A displaced man returns to the free queue.
- Return `n` `(man_id, woman_id)` pairs in ascending man ID. Each ID is encoded as a little-endian signed i64, for `16*n` bytes total.
- Null output returns `-2`, including for `n=0`. A nonnull capacity-0 buffer succeeds for `n=0`; a short buffer returns `-2` without writes.

The source initializes free men from a hash map, so proposal traces can vary. With complete strict preferences the men-optimal matching is unique; these ports use ascending IDs for the initial queue and sort the final pairs by man ID for stable output.

## Workload

[`workload.json`](workload.json) covers the empty and one-person cases, rejection and displacement, a larger preference profile, the maximum size, null and short output, and invalid rows and framing. The independent [`oracle`](../../stable_matching_oracle.py) enumerates assignments, keeps stable matchings, and chooses the men-optimal one.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/stable_matching.c`](../../../c/s/stable_matching.c) |
| C3 | [`c3/s/stable_matching.c3`](../../../c3/s/stable_matching.c3) |
| C++ | [`cpp/s/stable_matching.cpp`](../../../cpp/s/stable_matching.cpp) |
| Elisa | [`elisa/s/stable_matching.elisa`](../../../elisa/s/stable_matching.elisa) |
| Nim | [`nim/s/stable_matching.nim`](../../../nim/s/stable_matching.nim) |
| Odin | [`odin/s/stable_matching.odin`](../../../odin/s/stable_matching.odin) |
| Rust | [`rust/s/stable_matching.rs`](../../../rust/s/stable_matching.rs) |
| V | [`v/s/stable_matching.v`](../../../v/s/stable_matching.v) |
| Zig | [`zig/s/stable_matching.zig`](../../../zig/s/stable_matching.zig) |

## Pinned source

- [Rust `stable_matching.rs` at `fed66cb0c74c4a939ec5163648458a8c2b46fd4c`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/greedy/stable_matching.rs)

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm stable_matching --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm stable_matching
```
