# Add Two Numbers

This benchmark combines C LeetCode 2 and JavaScript `AddTwoNumbers`. Both add decimal digit lists stored in reverse order, propagating a carry from the least significant digit through each node position.

## Contract

- Input is `[length1, length2, digits1..., digits2...]`. Each length is 0 to 1,024 and must exactly match the packed input. Digits are in 0..9 and stored least-significant first.
- Invalid lengths or digits return `-1`.
- The output is the sum's digit list, also least-significant first, with one digit per output byte. Input digits are preserved, including trailing zero-valued high-order nodes; a final carry adds one digit. Two empty lists produce an empty output, matching the source functions' null result.
- Insufficient output capacity returns `-2` before writing bytes.
- Implementations process corresponding digits in one pass, adding the carry and appending a final carry if present.

The C numeric filename `2` is cataloged as the canonical `add_two_numbers` candidate. The JavaScript `add_two_numbers` candidate has the same little-endian digit-list semantics and is recorded as an alias.

Run `python3 benchmarks/verify_add_two_numbers.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` to check all nine ports against exhaustive short list pairs, seeded inputs up to maximum length, carry chains, malformed lengths and digits, output-capacity failure, and workload records.

## Implementations

Portable ports are [`c/a/add_two_numbers.c`](../../../c/a/add_two_numbers.c), [`c3/a/add_two_numbers.c3`](../../../c3/a/add_two_numbers.c3), [`cpp/a/add_two_numbers.cpp`](../../../cpp/a/add_two_numbers.cpp), [`elisa/a/add_two_numbers.elisa`](../../../elisa/a/add_two_numbers.elisa), [`nim/a/add_two_numbers.nim`](../../../nim/a/add_two_numbers.nim), [`odin/a/add_two_numbers.odin`](../../../odin/a/add_two_numbers.odin), [`rust/a/add_two_numbers.rs`](../../../rust/a/add_two_numbers.rs), [`v/a/add_two_numbers.v`](../../../v/a/add_two_numbers.v), and [`zig/a/add_two_numbers.zig`](../../../zig/a/add_two_numbers.zig). They use generic compiler targets and no architecture-specific instructions.

## Upstream references

- [TheAlgorithms/C LeetCode 2](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/2.c)
- [TheAlgorithms/JavaScript `AddTwoNumbers`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Linked-List/AddTwoNumbers.js)
