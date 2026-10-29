# Eertree distinct-palindrome prefixes

This benchmark builds an eertree, also called a palindromic tree, as lowercase characters arrive one at a time. Each non-root node represents one distinct nonempty palindrome. After each character, the benchmark records the number of such nodes and returns a checksum weighted by the prefix length.

## Contract

- Input is `[text_length, letter_0, ..., letter_(n-1)]`, where each lowercase ASCII letter is encoded as `a = 0` through `z = 25`.
- Text length is 0–128. The packed input length must be exactly `text_length + 1`; the maximum length is 129 values.
- The result is `Σ(i * distinct_palindromes(prefix[0:i]))` for one-based prefix lengths `i = 1..n`. Empty input returns zero.
- Invalid length, malformed framing, codes outside `0..25`, or a null input pointer return `-1`.

The online tree has two sentinel roots, for odd and even palindrome extension. For each new letter it follows suffix links until it finds a suffix palindrome that can be extended; a missing transition creates exactly one new palindrome node. The count after a prefix is the number of non-root nodes created so far. At most `n + 2` nodes are needed. A dense transition row for each of 26 letters gives `O(26n)` logical storage and initialization work, which is linear for this fixed alphabet. Suffix-link searches take amortized `O(n)` total time over all prefixes. The ports reserve space for the maximum 130 nodes.

[`workload.json`](workload.json) covers empty and singleton strings, unary and alternating strings, nested palindromes, repeated prefixes that add no new palindrome, all 26 letters, malformed inputs, and a null-input probe. [`benchmarks/eertree_oracle.py`](../../eertree_oracle.py) independently enumerates every substring of each prefix and compares it with its reversal. [`benchmarks/verify_eertree.py`](../../verify_eertree.py) statically checks fixture results, contract metadata, provenance, and all nine source files; it does not compile or execute the ports.

## Algorithm references

- [Library Checker: Eertree](https://judge.yosupo.jp/problem/eertree) lists the eertree task in its string-problem index.
- [Rubinchik and Shur: EERTREE: An Efficient Data Structure for Processing Palindromes in Strings](https://arxiv.org/abs/1506.04862) describes the online structure and suffix-link approach used as the algorithm basis. These implementations are clean-room ports and do not copy code, tests, submissions, or text.

## Implementations

The nine ports use the shared `i64_array_scalar` ABI. Source files are in the `e` directory for `c`, `c3`, `cpp`, `elisa`, `nim`, `odin`, `rust`, `v`, and `zig`.
