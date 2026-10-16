# Longest subsequence

The pinned C routine recursively chooses the first value as a pivot. It tests each later value below the pivot by recursively filtering its suffix to values at least that candidate, then tests the pivot followed by the suffix filtered to values at least the pivot. Strictly longer candidates replace the current best, preserving this traversal’s tie choice. This is a longest nondecreasing subsequence search.

## Contract

Input is `[n,x0,...]`, with 1..10 values in [-10,10]. The selected sequence length and elements are packed as base-21 digits: begin with its length, then append each value plus 10. Malformed inputs return -1.

See [workload](workload.json), [oracle](../../longest_subsequence_oracle.py), and pinned [C source](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/misc/longest_subsequence.c).

| Language | Port |
|---|---|
| C | c/l/longest_subsequence.c |
| C3 | c3/l/longest_subsequence.c3 |
| C++ | cpp/l/longest_subsequence.cpp |
| Elisa | elisa/l/longest_subsequence.elisa |
| Nim | nim/l/longest_subsequence.nim |
| Odin | odin/l/longest_subsequence.odin |
| Rust | rust/l/longest_subsequence.rs |
| V | v/l/longest_subsequence.v |
| Zig | zig/l/longest_subsequence.zig |
