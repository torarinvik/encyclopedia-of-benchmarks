# Radix-tree operation trace

This benchmark follows the pinned Python `RadixNode` implementation for
case-sensitive lowercase ASCII words. It applies a finite trace of insert,
find, and delete operations and returns a weighted checksum of the Boolean
query results.

## Contract

The `i64_array_scalar` input is
`[operation_count, opcode, word_length, ascii_bytes..., ...]`, with at most
256 operations. Each word is 1 through 32 bytes, and every byte is lowercase
ASCII `a` through `z` (97 through 122). Opcodes are:

- `0`: insert the word; inserting a duplicate leaves the tree unchanged
- `1`: find the exact word and observe 1 if present, otherwise 0
- `2`: delete the exact word and observe 1 if removed, otherwise 0

The trace starts with an empty root. Prefixes are not complete words unless
they were inserted separately. Each find or delete contributes
`(one_based_operation_index) * (1 + observed_boolean)` to the result; inserts
have no result contribution. The empty trace returns zero. Malformed framing,
invalid operations, empty or oversized words, or bytes outside the lowercase
ASCII range returns `-1`.

The nonempty-word restriction matters because source `find` and `delete`
access `word[0]`; the source's empty insert behavior is therefore outside
this contract. The source splits and compresses radix paths as words are
inserted and deleted. It also has a pinned root-collapse quirk: deleting a
root branch when exactly one other branch remains merges the survivor's
prefix into the root, but later lookups still index the root's children using
the first character of the full query. The surviving word can then become
unfindable. The workload preserves this observable behavior with the
`apple`/`banana` deletion case; it is part of this source-specific benchmark.
Repeated root collapses can also grow `root.prefix` beyond the 32-byte input-word
limit. Ports must preserve the source behavior for such prefixes: capping the
root prefix at 32 bytes changes insertion and lookup results. Keeping every byte
or using a saturated sentinel longer than every allowed query is equivalent,
because no query can equal a root prefix longer than 32 bytes. The workload
includes a 34-byte internal prefix and a 35-byte collapsed prefix.

The maximum valid input length is 8,705 integers; the maximum parseable input
length is 8,706. The finite limits keep input framing and recursive path
operations bounded.

## Pinned source

- TheAlgorithms/Python [`data_structures/trie/radix_tree.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/trie/radix_tree.py), commit `e1a2a8b016001309a73d5fec4818c35cca139795`
- The pinned MiBench [`network-patricia`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/network-patricia/patricia.c) and cBench [`network_patricia`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/network_patricia/src/patricia.c) use the same path-compressed Patricia/radix-trie insertion and exact-search algorithm on fixed-width IPv4 keys. Their key encoding and workload differ, so these sources are cross-referenced here instead of kept as duplicate algorithm packages.

## Workload

The workload is [`workload.json`](workload.json); the independent operation
oracle is [`benchmarks/radix_tree_oracle.py`](../../radix_tree_oracle.py).
