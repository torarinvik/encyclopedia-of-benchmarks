# Project Euler Problem 79: Passcode derivation

## Contract

`problem79(0)` derives the shortest passcode for the pinned `keylog.txt` dataset and returns `73162890`. The attempts are embedded as three-digit integers and decoded by hundreds, tens, and ones, preserving a leading zero if an attempt begins with one. A nonzero placeholder returns `-1`; this gives the file-based source a portable scalar ABI without runtime file access.

The ports collect the digits that appear, enumerate their permutations in ascending digit order, and accept the first candidate where every keylog triple occurs in strictly increasing positions. There are eight distinct digits in the pinned file. The result is the integer representation of the satisfying passcode.

## Source review

The pinned Python [`sol1`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_079/sol1.py) reads the adjacent file with `splitlines()`, splits attempts into characters, permutes the unique characters, and checks their positions for each attempt. Its unique-character expression, `unique_chars = {*login for login in split_logins}`, is syntactically invalid in Python (`iterable unpacking cannot be used in comprehension`), so the pinned module cannot be imported as written. The ports implement its clear intended set-union/permutation behavior over the exact 50 entries from the pinned keylog file. The dataset is represented with fixed-width triples to preserve leading zeroes.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem79.c](../../../c/p/problem79.c) |
| C3 | [c3/p/problem79.c3](../../../c3/p/problem79.c3) |
| C++ | [cpp/p/problem79.cpp](../../../cpp/p/problem79.cpp) |
| Elisa | [elisa/p/problem79.elisa](../../../elisa/p/problem79.elisa) |
| Nim | [nim/p/problem79.nim](../../../nim/p/problem79.nim) |
| Odin | [odin/p/problem79.odin](../../../odin/p/problem79.odin) |
| Rust | [rust/p/problem79.rs](../../../rust/p/problem79.rs) |
| V | [v/p/problem79.v](../../../v/p/problem79.v) |
| Zig | [zig/p/problem79.zig](../../../zig/p/problem79.zig) |
