# Minimum Operations to Move All Balls

This benchmark implements the linear two-pass count-and-distance algorithm from the pinned C LeetCode 1769 candidate in TheAlgorithms/C. It returns, for each box, the number of one-box moves required to gather all balls at that position.

Input values are `0` for an empty box and `1` for a box containing one ball, with up to 256 boxes. The ABI returns the number of boxes and writes one unsigned 16-bit little-endian move count per box into the caller's output buffer. This fixed byte order makes the output portable across host endianness. Empty input returns an empty output; invalid values or excess length return -1, and insufficient output capacity returns -2.

The verifier exhausts binary box patterns through length eight, adds seeded cases and maximum-length patterns, and checks capacity failures against an independent direct-distance oracle. The pinned source is [TheAlgorithms/C LeetCode 1769](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/1769.c). Run the verifier with the Elisa stage1 compiler path supplied.
