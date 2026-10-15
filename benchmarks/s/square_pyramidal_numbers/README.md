# Square pyramidal numbers

## Contract

The pinned Rust function returns the sum of the first `n` squares using
`n * (n + 1) * (2 * n + 1) / 6` in `u64` arithmetic. The benchmark accepts a
single signed 64-bit input and returns the exact result for `0 <= n <=
2,097,151`; negative inputs and larger values return `-1`.

The upper bound is the largest `n` for which the source's pre-division product
fits in `u64`. The resulting value also fits in signed 64-bit output. The next
input, `2,097,152`, overflows that intermediate product. This is distinct from
the `sum_of_squares` benchmark, which returns the minimum number of square
terms needed to represent an integer.

## Workload and implementation

[`workload.json`](workload.json) covers boundary values, representative
values, the largest supported input, and invalid values. The workload uses the
`scalar` ABI.

Build and record with the scalar ABI:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm square_pyramidal_numbers --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/s/square_pyramidal_numbers/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/s/square_pyramidal_numbers.c`](../../../c/s/square_pyramidal_numbers.c) |
| C3 | [`c3/s/square_pyramidal_numbers.c3`](../../../c3/s/square_pyramidal_numbers.c3) |
| C++ | [`cpp/s/square_pyramidal_numbers.cpp`](../../../cpp/s/square_pyramidal_numbers.cpp) |
| Elisa | [`elisa/s/square_pyramidal_numbers.elisa`](../../../elisa/s/square_pyramidal_numbers.elisa) |
| Nim | [`nim/s/square_pyramidal_numbers.nim`](../../../nim/s/square_pyramidal_numbers.nim) |
| Odin | [`odin/s/square_pyramidal_numbers.odin`](../../../odin/s/square_pyramidal_numbers.odin) |
| Rust | [`rust/s/square_pyramidal_numbers.rs`](../../../rust/s/square_pyramidal_numbers.rs) |
| V | [`v/s/square_pyramidal_numbers.v`](../../../v/s/square_pyramidal_numbers.v) |
| Zig | [`zig/s/square_pyramidal_numbers.zig`](../../../zig/s/square_pyramidal_numbers.zig) |

## Pinned source

- [Rust `square_pyramidal_numbers.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/square_pyramidal_numbers.rs)
- [The distinct `sum_of_squares` benchmark](../sum_of_squares/README.md)
