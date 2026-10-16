# Lexicographical numbers

This benchmark follows the pinned Python `lexical_order(max_number)` iterator, which emits the integers from 1 through N in decimal lexicographical order using a stack over decimal prefixes.

## Contract

- Input is one signed 64-bit integer N in `[0, 4096]`; N=0 produces an empty sequence.
- To fit the scalar ABI, the benchmark returns the deterministic checksum `sum((position + 1) * number)` over the sequence in the source's lexical order. All checksum arithmetic is signed 64-bit; even the loose bound `N * sum(1..N)` is at most 34,368,126,976.
- Invalid array shape, non-i64 values, or N outside the bounded domain returns `-1`.
- The ports preserve the source traversal order: push `number + 1` first, then `number * 10`, so the decimal child is popped first.

## Source

Pinned source: [TheAlgorithms/Python `lexicographical_numbers.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/stacks/lexicographical_numbers.py). Its `lexical_order` generator yields 1 through the maximum in lexical order. This benchmark uses a bounded integer maximum and a scalar checksum adapter instead of returning the full list.

## Workload and running

[`workload.json`](workload.json) covers the pinned examples, decimal-prefix transitions, N=0, the maximum bound, and invalid shapes and values. The independent oracle is [`benchmarks/lexicographical_numbers_oracle.py`](../../lexicographical_numbers_oracle.py).

Build and verify a selected port with:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm lexicographical_numbers --language rust
python3 benchmarks/verify_i64_array_scalar.py --algorithm lexicographical_numbers --languages rust
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/l/lexicographical_numbers.c`](../../../c/l/lexicographical_numbers.c) |
| C3 | [`c3/l/lexicographical_numbers.c3`](../../../c3/l/lexicographical_numbers.c3) |
| C++ | [`cpp/l/lexicographical_numbers.cpp`](../../../cpp/l/lexicographical_numbers.cpp) |
| Elisa | [`elisa/l/lexicographical_numbers.elisa`](../../../elisa/l/lexicographical_numbers.elisa) |
| Nim | [`nim/l/lexicographical_numbers.nim`](../../../nim/l/lexicographical_numbers.nim) |
| Odin | [`odin/l/lexicographical_numbers.odin`](../../../odin/l/lexicographical_numbers.odin) |
| Rust | [`rust/l/lexicographical_numbers.rs`](../../../rust/l/lexicographical_numbers.rs) |
| V | [`v/l/lexicographical_numbers.v`](../../../v/l/lexicographical_numbers.v) |
| Zig | [`zig/l/lexicographical_numbers.zig`](../../../zig/l/lexicographical_numbers.zig) |
