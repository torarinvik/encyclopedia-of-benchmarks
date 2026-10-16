# Binary representation length

Returns the number of bits in the ordinary base-two representation of a positive integer.

## Contract

- Uses the unary signed 64-bit scalar ABI.
- Inputs from 1 through 2,147,483,647 return `floor(log2(n)) + 1`, evaluated with binary64 `log2` and `floor` as in the primary Julia routine.
- Inputs outside that positive bounded domain return `-1`. In particular, the benchmark encodes the source's exception for nonpositive values as `-1`.
- The input bound keeps every accepted integer exactly representable in binary64 and gives ample separation from adjacent power-of-two boundaries, so the primary source formula agrees with the mathematical bit length over the full contract.

## Source semantics

The pinned [TheAlgorithms Julia `binary_length.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/binary_length.jl) defines `bin_length` by rejecting `binNum <= 0` and returning `floor(log2(binNum)) + 1`. The same file also contains separate long and short loop implementations; this benchmark covers only the primary logarithm-based routine. The source throws `DomainError` for nonpositive inputs, while the scalar benchmark uses `-1` as its out-of-domain result.

## Workload and build

[`workload.json`](workload.json) covers one-bit values, powers of two and their neighbors, representative examples from the source, the upper bound, and invalid nonpositive or oversized values.

Verify the nine ports against the independent oracle with `python3 benchmarks/verify_scalar.py --algorithms binary_length`.

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm binary_length --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/b/binary_length/rust/build.json
```

The implementations are in `c/b/binary_length.c`, `c3/b/binary_length.c3`, `cpp/b/binary_length.cpp`, `elisa/b/binary_length.elisa`, `nim/b/binary_length.nim`, `odin/b/binary_length.odin`, `rust/b/binary_length.rs`, `v/b/binary_length.v`, and `zig/b/binary_length.zig`.
