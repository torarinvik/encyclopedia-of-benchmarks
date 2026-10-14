# Trie

The pinned inventory finds trie implementations in 11 TheAlgorithms repositories. They share prefix-tree storage and exact-word lookup, while some add deletion, prefix queries, or occurrence counts. A few implementations count duplicate insertions; this benchmark uses set semantics so a repeated insertion leaves one word in the trie and returns zero.

## Contract

The i64_array_scalar function accepts up to 1,024 signed 64-bit values, encoded as variable-width records:

[opcode, word_length, character_code_1, ..., character_code_n]

Words contain lowercase ASCII letters a through z, and may be empty. Each word may contain up to 128 characters. The operations are:

- 0: insert a word; return 1 when new or 0 when already present
- 1: delete a word; return 1 when found or 0 otherwise
- 2: exact membership; return 1 or 0
- 3: prefix presence; return 1 if any stored word begins with the prefix
- 4: count stored words beginning with the prefix, including the prefix itself when it is a word
- 5: return total word count; this record must have word length zero

The empty prefix matches every stored word. The empty word is supported and is included in total and empty-prefix counts. Input longer than 1,024 values, truncated records, unknown operations, invalid character codes, word lengths above 128, or a nonempty size record returns -1. There can be at most 512 operations.

All implementations use a bounded node pool and 26-way child tables. Deletion updates word counts along the path; nodes can remain allocated after their words are removed. This keeps memory use predictable and avoids architecture-specific instructions.

Each operation contributes (operation_index + 1) * (observed_value + 1,000,000). The final active-word contribution uses a polynomial hash with base 31 modulo 1,000,000,007, summed over all stored words and weighted by one more than the operation count. Valid checksums fit in signed 64-bit.

workload.json publishes 23 traces for empty input, insertion, duplicates, empty words, shared prefixes, deletion, prefix counts, the maximum word length, and malformed inputs. benchmarks/verify_trie.py checks randomized and exhaustive traces against an independent Python set oracle, then verifies workload recording for all nine implementations.

## Implementations

The nine portable implementations are [C](../../../c/t/trie.c), [C3](../../../c3/t/trie.c3), [C++](../../../cpp/t/trie.cpp), [Elisa](../../../elisa/t/trie.elisa), [Nim](../../../nim/t/trie.nim), [Odin](../../../odin/t/trie.odin), [Rust](../../../rust/t/trie.rs), [V](../../../v/t/trie.v), and [Zig](../../../zig/t/trie.zig).

## Upstream references

- [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/trie/trie.c)
- [C-Sharp](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/Tries/Trie.cs)
- [F-Sharp](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/DataStructures/Trie.fs)
- [Go](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/structure/trie/trie.go)
- [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/trees/Trie.java)
- [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Tree/Trie.js)
- [PHP](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/DataStructures/Trie/Trie.php)
- [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/trie/trie.py)
- [Ruby](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/tries/trie.rb)
- [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/trie.rs)
- [Zig](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/dataStructures/trie.zig)
