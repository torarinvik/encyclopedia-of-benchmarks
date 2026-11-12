# Palindromes in Deque: bounded rebuild-Eertree profile

This package implements the operation and output contract of Library Checker’s
[Palindromes in Deque](https://github.com/yosupo06/library-checker-problems/blob/master/string/palindromes_in_deque/task.md).
The task is used as a clean-room specification; none of the official solution
code is copied.

## Contract

Input is `[Q, (operation, letter_code)*Q]`, with `1 <= Q <= 32`. Operation 0
inserts a lowercase letter at the front, operation 1 inserts it at the back,
operation 2 deletes the front letter, and operation 3 deletes the back letter.
Insertion codes are `0..25`; deletion arguments must be zero, and a deletion
from an empty deque is invalid. After every operation, return three signed
64-bit integers in little-endian order: the number of distinct nonempty
palindromic substrings, the longest palindromic prefix length, and the longest
palindromic suffix length. The empty string has summary `(0, 0, 0)`. Invalid
input returns `-1`; a null output or a capacity below `24*Q` bytes returns
`-2` without writing output.

## Algorithm and bounds

The ports store the current text in a bounded deque array. After each update,
they rebuild an ordinary insertion-only Eertree from left to right. The number
of non-root Eertree nodes is the distinct-palindrome count; the final
longest-suffix node gives the suffix length, and a suffix equal to the current
prefix gives the longest palindromic prefix. The tree has at most `N+2` nodes
for a snapshot of length `N`.

This is explicitly a **snapshot-rebuild Eertree profile**, not an amortized
double-ended palindromic tree. Each snapshot takes `O(N)` construction work for
the fixed 26-letter alphabet, so `Q` updates over a text bounded by `N <= Q`
take `O(Q*N)` time in this profile. The local cap is `Q <= 32`; input is at most
65 integers and output is at most 768 bytes. The independent Python oracle uses
direct substring enumeration instead of an Eertree.

## Distinction from existing string benchmarks

The existing `eertree` benchmark only appends on the right and reports its
distinct-palindrome prefix-count checksum. `manacher` analyzes a static string
and returns a selected longest palindrome. This package exercises front and
back insertion and deletion, and reports the distinct count plus both prefix
and suffix palindrome lengths after every operation. Its contract is therefore
a distinct two-ended update/output workload; this bounded implementation does
not claim the complexity of the specialized amortized double-ended structure.

## Provenance

The official task statement defines the operation sequence and the three values
reported after every operation. The ports and brute-force oracle are
independent clean-room implementations. See [`workload.json`](workload.json)
for deterministic fixtures and ABI bounds.

## Language ports

| Language | Source |
|---|---|
| C | [`c/p/palindromes_in_deque.c`](../../../c/p/palindromes_in_deque.c) |
| C3 | [`c3/p/palindromes_in_deque.c3`](../../../c3/p/palindromes_in_deque.c3) |
| C++ | [`cpp/p/palindromes_in_deque.cpp`](../../../cpp/p/palindromes_in_deque.cpp) |
| Elisa | [`elisa/p/palindromes_in_deque.elisa`](../../../elisa/p/palindromes_in_deque.elisa) |
| Mojo | [`mojo/p/palindromes_in_deque.mojo`](../../../mojo/p/palindromes_in_deque.mojo) |
| Nim | [`nim/p/palindromes_in_deque.nim`](../../../nim/p/palindromes_in_deque.nim) |
| Odin | [`odin/p/palindromes_in_deque.odin`](../../../odin/p/palindromes_in_deque.odin) |
| Rust | [`rust/p/palindromes_in_deque.rs`](../../../rust/p/palindromes_in_deque.rs) |
| V | [`v/palindromes_in_deque.v`](../../../v/palindromes_in_deque.v) |
| Zig | [`zig/p/palindromes_in_deque.zig`](../../../zig/p/palindromes_in_deque.zig) |
