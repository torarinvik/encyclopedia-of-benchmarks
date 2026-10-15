# Valid Anagram

This benchmark checks whether two lowercase ASCII strings contain the same letters with the same frequencies. It ports the frequency-table algorithm from [TheAlgorithms/C LeetCode 242](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/242.c), which counts both strings over the 26 lowercase English letters and compares those counts.

## Contract

- The packed input is `[first_length, second_length, first_ascii_values..., second_ascii_values...]`.
- Each string may contain 0 through 1,024 lowercase ASCII letters (`a` to `z`). The packed input length must match both declared lengths.
- Return `1` when the strings are anagrams, or `0` when their letter frequencies differ. Two empty strings are anagrams.
- Malformed lengths or out-of-domain characters return `-1`. The input is not modified.
- Runtime is O(n + m); the 26-entry frequency tables use O(1) extra space.

The numeric LeetCode source stem `242` is recorded as the algorithm name `valid_anagram` in the language folders and catalog.

Run `python3 benchmarks/verify_valid_anagram.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` from the repository root to check all nine ports against exhaustive short-string pairs, random inputs, boundaries, malformed inputs, and the published workload.

## Inspected upstream source

- [C — LeetCode `242.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/242.c)
- [Rust `anagram.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/string/anagram.rs), [Ruby array `anagram_checker.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/arrays/strings/anagram_checker.rb), and [Ruby hash-table `anagram_checker.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/hash_table/anagram_checker.rb) compare the same character multiset.
- The JavaScript [`CheckAnagram.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/CheckAnagram.js) and PHP [`CheckAnagram.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Strings/CheckAnagram.php) frequency predicates match this contract on lowercase ASCII inputs. The R [`is.anagram.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/string_manipulation/is.anagram.r) function lowercases and sorts characters, matching on the same domain.
- Nim [`check_anagram.nim`](https://github.com/TheAlgorithms/Nim/blob/63eec16614b46c91078653e8d3c049fe99ad36b3/strings/check_anagram.nim) also compares letter frequencies but requires an actual rearrangement; identical words and two empty strings return false. Its stricter rule has a separate [benchmark contract](../../c/check_anagram/README.md).
- [F# `CheckAnagrams.fs`](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/Strings/CheckAnagrams.fs) and [Python `check_anagrams.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/check_anagrams.py) also compare a pair of strings after case folding and whitespace removal.

The catalog records `anagram`, `anagram_checker`, `check_anagrams`, and `is_anagram` as aliases of this benchmark. The `check_anagram` candidate maps its JavaScript and PHP sources here and its Nim source to the stricter benchmark above. Case folding, whitespace handling, and broader character sets in some upstream sources are outside this lowercase ASCII contract.
