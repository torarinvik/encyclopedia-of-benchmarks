# Powers of 2 sequence

Returns the indexed term of the powers-of-two sequence: `1, 2, 4, 8, ...`.

## Contract

- Input is a zero-based index `n` from 0 through 62. Return `2^n`.
- Return `-1` for indices outside this range. `2^62` fits signed 64-bit output; `2^63` does not.
- The ports preserve the source generator's repeated multiplication by two.
- This sequence is distinct from `power_of_two`, which tests whether an input is a power of two.

## Source

- [TheAlgorithms/C-Sharp `PowersOf2Sequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/681ca7748206ca74d796912d9faeedd5336da432/Algorithms/Sequences/PowersOf2Sequence.cs)

## Workload and build

`workload.json` covers the initial terms, later terms, the largest signed 64-bit term, and invalid indices. Build with `python3 benchmarks/build_scalar.py --algorithm powers_of2_sequence --language LANGUAGE`.

## Ports

| Language | Source |
| --- | --- |
| C | [`c/p/powers_of2_sequence.c`](../../../c/p/powers_of2_sequence.c) |
| C3 | [`c3/p/powers_of2_sequence.c3`](../../../c3/p/powers_of2_sequence.c3) |
| C++ | [`cpp/p/powers_of2_sequence.cpp`](../../../cpp/p/powers_of2_sequence.cpp) |
| Elisa | [`elisa/p/powers_of2_sequence.elisa`](../../../elisa/p/powers_of2_sequence.elisa) |
| Nim | [`nim/p/powers_of2_sequence.nim`](../../../nim/p/powers_of2_sequence.nim) |
| Odin | [`odin/p/powers_of2_sequence.odin`](../../../odin/p/powers_of2_sequence.odin) |
| Rust | [`rust/p/powers_of2_sequence.rs`](../../../rust/p/powers_of2_sequence.rs) |
| V | [`v/p/powers_of2_sequence.v`](../../../v/p/powers_of2_sequence.v) |
| Zig | [`zig/p/powers_of2_sequence.zig`](../../../zig/p/powers_of2_sequence.zig) |
