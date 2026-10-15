# Manacher's Algorithm

This benchmark finds the longest contiguous palindrome with Manacher's linear-time radius-reuse method. It is a separate package from [Longest Palindromic Substring](../../l/longest_palindromic_substring/README.md), which uses center expansion, and [Longest Palindromic Substring by Dynamic Programming](../../l/longest_palindromic_substring_dp/README.md), which fills a gap table. The output problem is shared, but the algorithms and their time/space costs differ.

## Contract

- Input is a nonempty array of 1–1,000 ASCII letters or digits.
- Return the longest contiguous palindromic substring. If several have equal maximum length, return the leftmost one.
- Return the substring's byte length and write exactly those bytes to the caller's output buffer, without a NUL terminator.
- Invalid input returns `-1`. Insufficient output capacity returns `-2` without writing.
- The implementation uses O(n) time and O(n) auxiliary space. Separator positions are represented by parity, so no input character can collide with an internal marker.

The workload includes ties to make the leftmost rule explicit, plus empty, invalid-character, and over-limit inputs. The benchmark ports normalize the Rust source's rightmost tie selection to this shared contract.

The shared byte-output runner validates this contract with an independent center-expansion oracle. It returns `-2` when the declared output capacity cannot hold the selected substring.

## Pinned source mapping

- [TheAlgorithms/F-Sharp `Manacher.fs`](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/Strings/Manacher.fs)
- [TheAlgorithms/Java `Manacher.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/Manacher.java)
- [TheAlgorithms/Python `manacher.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/manacher.py)
- [TheAlgorithms/Rust `manacher.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a4c939ec5163648458a8c2b46fd4c/src/string/manacher.rs)

The four sources all return a longest palindromic substring using transformed-string/radius reuse. The bounded alphanumeric domain avoids the F#/Python `|` and Rust `#` separator collisions and excludes empty inputs, which the F# and Python functions do not handle. The pinned F# function also prints its transformed input and has a faulty mirror initialization; the ports omit the debug output and use the standard mirror-radius bound. Java uses boundary sentinels. Rust selects the rightmost maximum on ties, while the other sources select the leftmost; the benchmark uses the leftmost rule consistently.

The inventory also contains same-method filename variants in [C-Plus-Plus](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/strings/manacher_algorithm.cpp), [C-Plus-Plus-1](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/strings/manacher_algorithm.cpp), [R](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/string_manipulation/manacher.longest.palindrome.r), and [C-Sharp](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Strings/ManachersAlgorithm.cs). The C++ variants and C# method use strict-greater updates; R's function uses `which.max`. Their result semantics fit this benchmark, with R's lowercasing confined to its command-line wrapper.

## ABI

Build with the `i64_array_bytes_output` ABI and function symbol `manacher`. The input is passed as signed 64-bit ASCII code points; output bytes are written to caller-provided storage.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm manacher --language rust
```
