# Indexed block list

This benchmark maintains an indexed sequence as a linked chain of fixed-size blocks. It supports insertion at any zero-based position, including either endpoint, and random access. A block has target size `B = 4`; after insertion makes its size exceed `2B`, the algorithm links a new successor and moves the block's last `B` values into it. The input is validated before output is written.

## Contract

The signed 64-bit input is `[initial_count, initial_values..., operation_count, operations...]`. `initial_count` is 0–16 and values are in `[-1,000,000, 1,000,000]`. There are at most 64 operations, at most 32 insertions, and at most 32 accesses. `[0,index,value]` inserts before `index` (valid from zero through the current length). `[1,index]` returns the value at a valid zero-based index. Access results are emitted as little-endian signed 64-bit words; the function result is the number of output bytes. Invalid input returns `-1`; a null or short output buffer for nonempty output returns `-2`; no error writes output. A valid workload with no accesses returns zero even when the output buffer is null.

The longest valid input has 178 words and the parseable malformed-frame limit is 179 words. Output is at most 256 bytes. The bounded port workspace is at most 4,096 bytes; it stores at most 16 block descriptors, nine values per block during an insertion, and 32 staged answers. In this fixed profile, each operation traverses the linked blocks and may shift at most `2B+1` values within one block, for `O(number_of_blocks + B)` work. The chosen `B = 4` is a small fixed constant for the bounded workload, not a claim of an asymptotic square-root bound as the input grows.

## Distinction and provenance

The existing `unrolled_linked_list` package only appends and flattens, with tail splitting. This package exercises indexed insertion, indexed access, and interior block splitting. Its operation design follows the linked-array block-list description in [OI Wiki](https://oi-wiki.org/ds/block-list/). The implementation and workload were written independently; no source code or examples were copied.

The primary oracle simulates linked fixed-array blocks and the prescribed split. The independent oracle uses a flat Python list and checks only sequence semantics.
