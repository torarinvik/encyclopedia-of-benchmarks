# Sylvester sequence

This benchmark returns the one-based `n`th term of Sylvester's sequence.

## Contract

- The unary scalar input is a signed 64-bit integer.
- For `1 <= n <= 7`, return the exact term defined by `a(1) = 2` and
  `a(n) = a(n - 1) * (a(n - 1) - 1) + 1`.
- Inputs `n <= 0` preserve the source's invalid-input outcome as `-1`.
- Inputs above 7 return `-1` because the eighth term does not fit the scalar
  signed 64-bit result type. This is a benchmark bound; the pinned Java and
  Python sources can represent larger terms, while the pinned Rust source uses
  signed 128-bit results.

The implementations preserve the source's recursive recurrence and explicit
`n = 1` base case. Every multiplication through term 7 fits signed 64-bit.

## Pinned sources

- [Java `SylvesterSequence.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/recursion/SylvesterSequence.java)
- [Python `sylvester_sequence.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/sylvester_sequence.py)
- [Rust `sylvester_sequence.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a4c939ec5163648458a8c2b46fd4c/src/math/sylvester_sequence.rs)

## Workload and build

[`workload.json`](workload.json) uses the unary `scalar` ABI and covers the
base case, early terms, the largest supported term, and both sides of the
supported range. Build and record with:

```sh
python3 benchmarks/build_abi.py --family scalar --algorithm sylvester_sequence --language rust
python3 benchmarks/run_scalar.py --build-manifest build/scalar/s/sylvester_sequence/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/s/sylvester_sequence.c`](../../../c/s/sylvester_sequence.c) |
| C3 | [`c3/s/sylvester_sequence.c3`](../../../c3/s/sylvester_sequence.c3) |
| C++ | [`cpp/s/sylvester_sequence.cpp`](../../../cpp/s/sylvester_sequence.cpp) |
| Elisa | [`elisa/s/sylvester_sequence.elisa`](../../../elisa/s/sylvester_sequence.elisa) |
| Nim | [`nim/s/sylvester_sequence.nim`](../../../nim/s/sylvester_sequence.nim) |
| Odin | [`odin/s/sylvester_sequence.odin`](../../../odin/s/sylvester_sequence.odin) |
| Rust | [`rust/s/sylvester_sequence.rs`](../../../rust/s/sylvester_sequence.rs) |
| V | [`v/s/sylvester_sequence.v`](../../../v/s/sylvester_sequence.v) |
| Zig | [`zig/s/sylvester_sequence.zig`](../../../zig/s/sylvester_sequence.zig) |
