# 3Sum

This benchmark returns every unique value triplet whose sum is zero. Its algorithm name and source filename retain the numeric-leading name `3sum` in the `0-9` bucket. Elisa identifiers cannot start with a digit, so the exported function uses the valid identifier `three_sum`; the file has no explicit Elisa module declaration.

## Contract

- Input is an integer array of length 0 through 257, with values from -100,000 through 100,000.
- Arrays shorter than three elements have no results.
- Each result contains three values in nondecreasing order. Triplets are unique and returned in lexicographic order.
- The function returns the number of triplets and writes each signed 32-bit value as four little-endian bytes. No separators or terminators are written. Input is not modified.
- Invalid input returns -1. Insufficient output capacity returns -2 without writing.
- Sorting and the two-pointer search use O(n log n) sorting and O(n²) search time, with O(n) space for a private sorted copy.

The 257-element benchmark bound keeps the conservative output capacity bound, C(n,2) triplets at 12 bytes each, within the byte-output harness limit of 400,004 bytes. The upstream LeetCode problem allows arrays up to 3,000 elements; this local cap is documented so workloads remain inside the current shared ABI.

## Source and verification

The catalog candidate is TheAlgorithms/Ruby data_structures/arrays/3sum.rb, pinned at commit bda11bdfd83b7958e1ca98247e5e43100ca88865. Its implementation sorts a copy, skips duplicate first values, and uses two pointers to find distinct triplets. The ports preserve those semantics, with a portable heap sort for the private copy and an explicit little-endian result encoding.

workload.json covers empty and short arrays, duplicate values, signed boundaries, invalid inputs, and the 257-element bound. The verifier compares all nine ports against a frequency-table oracle that enumerates value pairs independently of the sorted two-pointer implementation.
