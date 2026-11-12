# Persistent range affine range sum

This profile implements the Library Checker persistent range-affine problem.
Each update or range-copy creates a new version from an earlier version;
queries read any existing version. The package uses a path-copying lazy segment
tree with modular affine tags and shares covered source subtrees for range-copy.

## Bounded ABI

The `i64_array_bytes_output` input is `[N,Q,initial[N],operations...]`. Type 0
has six words `[0,k,l,r,b,c]`: clone version `k` and apply
`x=(b*x+c) mod 998244353` on `[l,r)`. Type 1 has five words
`[1,k,s,l,r]`: clone `k` and copy that slice from `s`. Type 2 has four words
`[2,k,l,r]` and outputs the modular sum from version `k`; queries create no
version. Version `-1` means the initial array. A nonnegative reference must be
an earlier type-0 or type-1 operation. `N,Q` are each 1 through 16; ranges obey
`0<=l<r<=N`; initial values and offsets are `[0,MOD)`, and multipliers are
`[1,MOD)`. The maximum valid and parseable frames are 114 and 115 words.

Each query emits one little-endian signed 64-bit sum. Output is at most 128
bytes. Invalid input returns `-1`; null output or insufficient capacity returns
`-2`. The complete input is validated before output checks and no error writes
output. The ABI workspace field is the 128-byte output staging buffer. Internal
tree storage is separately bounded at 4096 nodes (131072 bytes). The small
bounds keep all modular products within signed 64-bit range.

## Source and rights

The task shape and constraints follow the official
[`persistent_range_affine_range_sum` statement](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/persistent_range_affine_range_sum/task.md)
and [`info.toml`](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/data_structure/persistent_range_affine_range_sum/info.toml).
The Library Checker repository is Apache-2.0 licensed. These ports and direct
array oracles are clean-room implementations; no upstream solution, generator,
or checker code is copied. See [`RIGHTS.md`](RIGHTS.md).

## Workload and oracles

[`workload.json`](workload.json) includes branching, affine-order, range-copy,
malformed-reference, and output-error fixtures. The primary direct-version
oracle is [`benchmarks/persistent_range_affine_range_sum_oracle.py`](../../persistent_range_affine_range_sum_oracle.py);
the independent snapshot checker is
[`benchmarks/persistent_range_affine_range_sum_verifier_oracle.py`](../../persistent_range_affine_range_sum_verifier_oracle.py).
[`verify_workload.py`](verify_workload.py) statically checks fixture values,
oracle agreement, rights metadata, and all ten port paths.

## Implementations

| Language | Port |
|---|---|
| C | [`c/p/persistent_range_affine_range_sum.c`](../../../c/p/persistent_range_affine_range_sum.c) |
| C3 | [`c3/p/persistent_range_affine_range_sum.c3`](../../../c3/p/persistent_range_affine_range_sum.c3) |
| C++ | [`cpp/p/persistent_range_affine_range_sum.cpp`](../../../cpp/p/persistent_range_affine_range_sum.cpp) |
| Elisa | [`elisa/p/persistent_range_affine_range_sum.elisa`](../../../elisa/p/persistent_range_affine_range_sum.elisa) |
| Mojo | [`mojo/p/persistent_range_affine_range_sum.mojo`](../../../mojo/p/persistent_range_affine_range_sum.mojo) |
| Nim | [`nim/p/persistent_range_affine_range_sum.nim`](../../../nim/p/persistent_range_affine_range_sum.nim) |
| Odin | [`odin/p/persistent_range_affine_range_sum.odin`](../../../odin/p/persistent_range_affine_range_sum.odin) |
| Rust | [`rust/p/persistent_range_affine_range_sum.rs`](../../../rust/p/persistent_range_affine_range_sum.rs) |
| V | [`v/p/persistent_range_affine_range_sum.v`](../../../v/p/persistent_range_affine_range_sum.v) |
| Zig | [`zig/p/persistent_range_affine_range_sum.zig`](../../../zig/p/persistent_range_affine_range_sum.zig) |
