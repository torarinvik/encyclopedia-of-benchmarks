# Aho–Corasick

Search a text for several patterns in one pass using a trie and failure links. The nine ports use the shared `i64_array_bytes_output` ABI.

## Contract

- Input is `[pattern_count, text_length, pattern_length_0..pattern_length_(p-1), pattern_bytes..., text_bytes...]`.
- There are 1–16 patterns. Each pattern is 1–32 bytes; text is 0–256 bytes. All bytes are non-NUL 7-bit ASCII values (1–127), and pattern strings must be unique. The input must have exactly the declared shape.
- Matching is case-sensitive. Overlapping occurrences count, including patterns that are suffixes of other matched patterns.
- Return one signed 64-bit little-endian occurrence count per pattern, in input order. The return value is the output byte count. Malformed input returns `-1`; insufficient output capacity returns `-2`; allocation failure returns `-3`.
- Each implementation builds trie transitions and failure links, then follows terminal failure links while scanning the text. The bounded node table has at most 513 states.

## Source behavior and output normalization

The pinned Python source returns matched pattern keys mapped to start positions, omitting keys with no matches. Java returns all input patterns mapped to start positions. Rust returns matching substrings in text scan order without positions or pattern IDs. The benchmark adapts each source’s result shape to a count per input pattern; unique patterns make Rust substring counts unambiguous. ASCII keeps character indexing consistent across Python, Java, and Rust. Empty patterns are excluded because the three sources handle them differently, and duplicate patterns are excluded because Java, Python, and Rust retain them differently.

- [TheAlgorithms Java `AhoCorasick.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/AhoCorasick.java)
- [TheAlgorithms Python `aho_corasick.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/aho_corasick.py)
- [TheAlgorithms Rust `aho_corasick.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/string/aho_corasick.rs)

`workload.json` covers suffix matches, overlapping occurrences, no matches, empty text, the maximum text length, and invalid shapes or patterns. The shared byte-output runner includes a source oracle for the packed input and per-pattern count output. Build and record with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm aho_corasick --language LANGUAGE
python3 benchmarks/run_i64_array_bytes_output.py --algorithm aho_corasick
```
