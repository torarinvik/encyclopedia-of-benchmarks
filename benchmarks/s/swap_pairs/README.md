# Swap Nodes in Pairs

This benchmark swaps each adjacent pair in a singly linked list and keeps the final node unchanged when the list length is odd. It follows the recursive node-relinking algorithm in C LeetCode 24. The shared array ABI represents list order directly and serializes the swapped values into a separate output buffer.

## Contract

- Input is a list of zero to 1,024 signed 32-bit values.
- Values outside the signed 32-bit range return `-1`.
- Output contains the values with positions `(0,1)`, `(2,3)`, and so on swapped, encoded as little-endian signed 32-bit integers. The return value is the output length. Insufficient output capacity returns `-2`.
- Ports use one forward pass over the array representation, applying the same adjacent-pair rewrite without pointer-specific list allocation.

The numeric C LeetCode source stem `24` is cataloged under the alphabetic benchmark name `swap_pairs`.

Run `python3 benchmarks/verify_swap_pairs.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` to check all nine ports against exhaustive short lists, random lists, signed boundaries, invalid values, output-capacity failure, and workload records.

## Implementations

The portable ports are [`c/s/swap_pairs.c`](../../../c/s/swap_pairs.c), [`c3/s/swap_pairs.c3`](../../../c3/s/swap_pairs.c3), [`cpp/s/swap_pairs.cpp`](../../../cpp/s/swap_pairs.cpp), [`elisa/s/swap_pairs.elisa`](../../../elisa/s/swap_pairs.elisa), [`nim/s/swap_pairs.nim`](../../../nim/s/swap_pairs.nim), [`odin/s/swap_pairs.odin`](../../../odin/s/swap_pairs.odin), [`rust/s/swap_pairs.rs`](../../../rust/s/swap_pairs.rs), [`v/s/swap_pairs.v`](../../../v/s/swap_pairs.v), and [`zig/s/swap_pairs.zig`](../../../zig/s/swap_pairs.zig). They use generic compiler targets without architecture-specific instructions.

## Upstream reference

- [C LeetCode 24](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/24.c)
