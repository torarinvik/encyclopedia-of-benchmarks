# Reverse String In Place

This benchmark ports C LeetCode 344's two-pointer byte-array reversal. It reverses bytes from the outside inward by swapping the current left and right elements.

## Contract

- Input is a byte array of length 0 to 4,096. Each input value must be in 0..255.
- Invalid lengths or values return `-1`.
- The output is the input byte sequence in reverse order, written to a separate output buffer. The return value is the byte length.
- Insufficient output capacity returns `-2` before writing output.
- Each implementation copies the caller's bytes into the output buffer and performs the same inward two-pointer swaps there, adapting the source's in-place mutation to the benchmark ABI.

The numeric C candidate `344` is cataloged under the alphabetic benchmark name `reverse_string_in_place`. Other TheAlgorithms string-reversal candidates contain additional strategies and are reviewed separately.

Run `python3 benchmarks/verify_reverse_string_in_place.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` to check all nine ports against exhaustive short byte patterns, seeded longer inputs, byte boundaries, invalid values, maximum length, output-capacity failure, and workload records.

## Implementations

Portable ports are [`c/r/reverse_string_in_place.c`](../../../c/r/reverse_string_in_place.c), [`c3/r/reverse_string_in_place.c3`](../../../c3/r/reverse_string_in_place.c3), [`cpp/r/reverse_string_in_place.cpp`](../../../cpp/r/reverse_string_in_place.cpp), [`elisa/r/reverse_string_in_place.elisa`](../../../elisa/r/reverse_string_in_place.elisa), [`nim/r/reverse_string_in_place.nim`](../../../nim/r/reverse_string_in_place.nim), [`odin/r/reverse_string_in_place.odin`](../../../odin/r/reverse_string_in_place.odin), [`rust/r/reverse_string_in_place.rs`](../../../rust/r/reverse_string_in_place.rs), [`v/r/reverse_string_in_place.v`](../../../v/r/reverse_string_in_place.v), and [`zig/r/reverse_string_in_place.zig`](../../../zig/r/reverse_string_in_place.zig). They use generic compiler targets and no architecture-specific instructions.

## Upstream reference

- [TheAlgorithms/C LeetCode 344](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/344.c)
