# Remove Element

This benchmark removes every occurrence of a target value from an integer array while preserving the order of the remaining values. It follows the write-index compaction in C LeetCode 27. The shared ABI keeps the input unchanged and serializes the survivor prefix to a separate output buffer.

## Contract

- Input is `[target, value0, value1, ...]`, with one target and zero to 4,095 signed 32-bit array values (at most 4,096 input integers total).
- Missing targets and values outside the signed 32-bit range return `-1`.
- The output contains the values unequal to the target, in their original order, as little-endian signed 32-bit integers. The return value is the survivor count. Insufficient output capacity returns `-2`.
- Implementations validate inputs and count survivors before writing output, then make a stable compaction pass.

The numeric C LeetCode source stem `27` is cataloged under the alphabetic algorithm name `remove_element`. The Ruby `remove_elements` candidate has the same removal goal and permits reordered survivors; the benchmark chooses stable output so results compare byte-for-byte.

Run `python3 benchmarks/verify_remove_element.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` to check all nine ports against exhaustive short arrays, seeded random arrays, signed boundaries, malformed values, output-capacity failure, and workload records.

## Implementations

The portable ports are [`c/r/remove_element.c`](../../../c/r/remove_element.c), [`c3/r/remove_element.c3`](../../../c3/r/remove_element.c3), [`cpp/r/remove_element.cpp`](../../../cpp/r/remove_element.cpp), [`elisa/r/remove_element.elisa`](../../../elisa/r/remove_element.elisa), [`nim/r/remove_element.nim`](../../../nim/r/remove_element.nim), [`odin/r/remove_element.odin`](../../../odin/r/remove_element.odin), [`rust/r/remove_element.rs`](../../../rust/r/remove_element.rs), [`v/r/remove_element.v`](../../../v/r/remove_element.v), and [`zig/r/remove_element.zig`](../../../zig/r/remove_element.zig). They use generic compiler targets without architecture-specific instructions.

## Upstream references

- [C LeetCode 27](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/27.c)
- [Ruby remove_elements](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/arrays/remove_elements.rb)
