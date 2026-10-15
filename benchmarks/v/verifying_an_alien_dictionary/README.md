# Verifying an Alien Dictionary

Check whether the words appear in nondecreasing lexicographic order under a supplied permutation of the lowercase English alphabet. Each adjacent pair is decided by its first differing letter; if one word is a prefix of the other, the shorter word comes first. Equal words are accepted.

## Contract

- Input is `[word_count, 26 ASCII order bytes, (word_length, ASCII word bytes) * word_count]`.
- There are 1..100 words, each 1..20 bytes. Words contain lowercase ASCII letters, and the 26-byte order must be a permutation of `a` through `z`.
- Return `1` when sorted and `0` when not sorted. Invalid packed inputs return `-1`. Input is read only.
- Implementations build a fixed 26-entry rank table and compare adjacent words. Time is O(total characters); auxiliary space is O(26 + word count).

## Workload

[`workload.json`](workload.json) covers the published examples, both prefix orders, equal words, a first-letter decision where the left word is longer, a custom alphabet, and malformed order/word encodings. All nine ports pass 10,684 oracle cases and all 10 workload cases with [`verify_verifying_an_alien_dictionary.py`](../../verify_verifying_an_alien_dictionary.py).

## Upstream source

- [TheAlgorithms/C LeetCode 953 at the pinned revision](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/953.c)
- [LeetCode 953 statement and constraints](https://leetcode.com/problems/verifying-an-alien-dictionary/description/)
