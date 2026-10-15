# Word Break

This benchmark checks whether a lowercase ASCII string can be segmented into dictionary words. A dictionary word can be reused any number of times.

## Contract

- The packed input is `[text_length, word_count, text_codes..., word_0, ...]`. Each word occupies a fixed-width slot: `[word_length, 32 letter codes]`, with unused positions set to zero. Letter codes are `1` for `a` through `26` for `z`.
- Text length is at most 64, there are at most 32 words, and each word is 1 through 32 letters. Malformed input returns `-1`; a segmentable string returns `1`; otherwise the result is `0`. The empty string is segmentable, including with an empty dictionary.
- The ports use a forward dynamic-programming table of reachable text positions. Fixed-width slots make the same packed input portable across all nine language ABIs.

## Inspected upstream sources

- [C++ `dynamic_programming/word_break.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/dynamic_programming/word_break.cpp)
- [C++1 `dynamic_programming/word_break.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/dynamic_programming/word_break.cpp)
- [Python `dynamic_programming/word_break.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/word_break.py)
- [Python `backtracking/word_break.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/backtracking/word_break.py)

The C++ source memoizes suffix results and tests growing prefixes. Python’s dynamic-programming source walks a trie while memoizing suffixes, and its backtracking source explores dictionary word boundaries. All allow word reuse. The shared contract treats empty text as segmentable, though the Python implementation rejects empty text as input. The candidate catalog also lists a Rust path that returns 404 at its pinned commit, so that reference was not used to define this contract.

## Workload and verification

`workload.json` covers reusable words, overlapping prefixes, dead ends, empty text, maximum text length, and malformed packed inputs. The verifier exhausts every binary-alphabet string through length six against every dictionary subset of six short words, adds deterministic longer inputs, and checks all published cases against an independent memoized recursive oracle in all nine languages.

```sh
python3 benchmarks/verify_word_break.py --elisa-compiler /absolute/path/to/elisac
```

Build and record with the `i64_array_scalar` ABI family. Source ports are in `w/` in all nine language directories.
