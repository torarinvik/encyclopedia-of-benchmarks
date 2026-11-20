# Ternary search trie

This benchmark implements a bounded symbol table using a ternary search trie
(TST). At each character position, left and right links compare alternative
characters at the same depth, while the middle link advances to the next
character after an equality. The existing [trie](../trie/README.md) uses a
26-way child array at each node; it does not implement this three-link
character-search structure.

## Contract

The ABI is i64_array_scalar, exported symbol ternary_search_trie. Input is
[operation_count, fixed-width records...]. Each record has nine signed
64-bit values: [opcode, key_length, six character slots, value]. There are
at most 64 operations; each key or query has at most six characters. Stored
keys use nonempty lowercase ASCII a through z; queries may be empty.
Wildcard patterns use the ASCII dot as a one-character wildcard.

- Opcode 0 inserts or overwrites a key. Its value is in 1..65535; the result
  is the old value or zero if the key was absent.
- Opcode 1 looks up a nonempty key and returns its value, or zero if absent.
- Opcode 2 deletes a nonempty key and returns the removed value, or zero if
  absent. Empty trie nodes are pruned after deletion.
- Opcode 3 returns the length of the longest stored key that prefixes the
  query, or zero if none.
- Opcode 4 counts stored keys beginning with the prefix. The empty prefix
  returns the table size.
- Opcode 5 counts stored keys of the same length matching the pattern, with
  dot matching any one lowercase letter.
- Opcode 6 returns the table size and requires all remaining record fields to
  be zero.

Character slots after the declared key length and all unused value fields must
be zero. Input must contain exactly one header plus nine values per operation.
Malformed input returns -1. The maximum valid frame is 577 values. Parsers
accept frames up to 578 values for validation, and explicitly reject a
578-value frame as an extra-value malformed frame. The
scalar result is the sum of each operation's observed result multiplied by
its one-based operation index.

There are at most 384 TST nodes because a trace has at most 64 operations and
each insertion has at most six characters. A call uses fixed arrays and
bounded recursion. For N allocated nodes and key length L, updates and
lookups follow one comparison path of at most N nodes; prefix and wildcard
queries may visit multiple matching branches. The profile imposes no balancing
guarantee on the left/right character-search links.

## Oracles and workload

[primary_oracle.py](primary_oracle.py) uses the same left/middle/right
ternary-search-trie structure as the ports.
[independent_oracle.py](independent_oracle.py) uses a Python dictionary and
direct string scans for the query operations. [workload.json](workload.json)
contains deterministic fixtures for insertion, overwrite, prefix lookup,
wildcard matching, deletion, malformed characters, and nonzero padding,
including short and maximum-length trailing-value frames. The callable
`validate_inventory(workload)` in [verify_workload.py](verify_workload.py)
checks package inventory, language exports, local documentation links, and
fixture expectations against both oracles. It is provided for static review
and was not run.

## Provenance and ports

The algorithm is covered in Section 5.2, “Tries,” and is represented by
Princeton's TST class. The upstream source is GPLv3; this package uses only
the algorithmic description and contains no copied source or prose. See
[RIGHTS.md](RIGHTS.md), the [official TST documentation](https://algs4.cs.princeton.edu/code/javadoc/edu/princeton/cs/algs4/TST.html),
the [published Java source](https://algs4.cs.princeton.edu/code/edu/princeton/cs/algs4/TST.java.html),
and the [official repository and license](https://github.com/kevin-wayne/algs4).

| Language | Source |
|---|---|
| C | [c/t/ternary_search_trie.c](../../../c/t/ternary_search_trie.c) |
| C3 | [c3/t/ternary_search_trie.c3](../../../c3/t/ternary_search_trie.c3) |
| C++ | [cpp/t/ternary_search_trie.cpp](../../../cpp/t/ternary_search_trie.cpp) |
| Elisa | [elisa/t/ternary_search_trie.elisa](../../../elisa/t/ternary_search_trie.elisa) |
| Mojo | [mojo/t/ternary_search_trie.mojo](../../../mojo/t/ternary_search_trie.mojo) |
| Nim | [nim/t/ternary_search_trie.nim](../../../nim/t/ternary_search_trie.nim) |
| Odin | [odin/t/ternary_search_trie.odin](../../../odin/t/ternary_search_trie.odin) |
| Rust | [rust/t/ternary_search_trie.rs](../../../rust/t/ternary_search_trie.rs) |
| V | [v/t/ternary_search_trie.v](../../../v/t/ternary_search_trie.v) |
| Zig | [zig/t/ternary_search_trie.zig](../../../zig/t/ternary_search_trie.zig) |
