# Distinct substring count by rolling hash

Count the exact number of distinct nonempty contiguous substrings in one byte
sequence. For each substring length, the primary computes a polynomial
fingerprint from prefix hashes and groups equal fingerprints. It compares bytes
inside each same-hash group before treating a substring as a duplicate, so
collisions cannot change the result.

## Contract

- Input is `[n, byte_0, ..., byte_(n-1)]`, with `0<=n<=64`, bytes in `0..255`,
  and exact array length `n+1`.
- Return the exact count of distinct nonempty contiguous substrings. Empty
  input returns zero. Malformed, null, or out-of-profile input returns `-1`.
- The primary uses Horner hashes of `byte+1` with base 257 modulo 1,000,000,007. It checks
  candidate bytes whenever equal hashes occur. The fixed modulus is small enough
  to demonstrate why this check matters: `[0,0,0,0]` and `[58,234,70,157]`
  have the same length-four hash: the raw-byte hash of the latter is exactly
  1,000,000,007, and adding one to every digit contributes the same constant to
  both length-four hashes. Both remain distinct in the count.
- Prefix preprocessing takes `O(n)` time and space. The bounded implementation
  considers `O(n^2)` substrings. Exact checks cost `O(n^3)` on highly repetitive
  inputs and `O(n^4)` in the worst case if many distinct substrings collide;
  ordinary hash-table work is expected `O(n^2)` for well-distributed windows.
  The independent reference enumerates byte tuples directly.

This is a different method from [`suffix_automaton`](../../s/suffix_automaton/README.md),
which counts distinct substrings from automaton states, and from suffix-array
profiles, which use adjacent-suffix LCP values. It is related to
[`rabin_karp`](../../r/rabin_karp/README.md) through polynomial rolling hashes,
but this package deduplicates every substring length rather than searching for
one pattern.

## Provenance

The algorithm idea comes from CP-Algorithms' [String Hashing article,
distinct-substring application](https://cp-algorithms.com/string/string-hashing.html#determine-the-number-of-different-substrings-in-a-string).
The article is CC BY-SA 4.0. The bounded exact-collision contract, code,
references, fixtures, and prose are independently authored; no source code,
examples, or prose were copied. See [`RIGHTS.md`](RIGHTS.md).

## Workload and static inventory

[`workload.json`](workload.json) covers empty, singleton, periodic, full-byte,
maximum-count (the increasing byte sequence `0..63`), repeated-symbol,
malformed, and deliberate hash-collision inputs. The primary
and independent references are [`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py). The source-only
[`verify_workload.py`](verify_workload.py) checks package files, ten exported
symbols, bounds, required fixtures, and agreement between the two references.

## Language ports

| Language | Source |
|---|---|
| C | [c/d/distinct_substring_count_hashing.c](../../../c/d/distinct_substring_count_hashing.c) |
| C3 | [c3/d/distinct_substring_count_hashing.c3](../../../c3/d/distinct_substring_count_hashing.c3) |
| C++ | [cpp/d/distinct_substring_count_hashing.cpp](../../../cpp/d/distinct_substring_count_hashing.cpp) |
| Elisa | [elisa/d/distinct_substring_count_hashing.elisa](../../../elisa/d/distinct_substring_count_hashing.elisa) |
| Mojo | [mojo/d/distinct_substring_count_hashing.mojo](../../../mojo/d/distinct_substring_count_hashing.mojo) |
| Nim | [nim/d/distinct_substring_count_hashing.nim](../../../nim/d/distinct_substring_count_hashing.nim) |
| Odin | [odin/d/distinct_substring_count_hashing.odin](../../../odin/d/distinct_substring_count_hashing.odin) |
| Rust | [rust/d/distinct_substring_count_hashing.rs](../../../rust/d/distinct_substring_count_hashing.rs) |
| V | [v/d/distinct_substring_count_hashing.v](../../../v/d/distinct_substring_count_hashing.v) |
| Zig | [zig/d/distinct_substring_count_hashing.zig](../../../zig/d/distinct_substring_count_hashing.zig) |
