# Collatz sequence values

Return the full Collatz trajectory for one positive starting value, including the start and the terminal `1`. This is distinct from [`collatz`](../collatz/README.md), which returns only the number of transitions.

## Contract

- Input is an array containing exactly one signed 64-bit integer in `[1, 1,000,000]`.
- For an even current value, the next term is `n / 2`; for an odd value, it is `3n + 1`.
- The output is the complete sequence `[start, ..., 1]`, encoded as consecutive little-endian signed 64-bit integers. The function returns the number of bytes written.
- Missing, nonpositive, or out-of-range starts return `-1`; insufficient output capacity returns `-2`.
- The positive bounded domain ensures every trajectory reaches `1` without signed 64-bit overflow, matching the established Collatz benchmark domain. The scan takes `O(k)` time for `k` terms and uses constant auxiliary space.

## Reviewed sources and semantic differences

The pinned Rust `sequence` returns `None` for zero and otherwise includes both the initial value and final `1`. The pinned Python and Julia sources also return full trajectories. The JavaScript source returns the final result separately and a `steps` array that omits the initial value; the shared contract normalizes that representation to the same full sequence. Nonpositive inputs are outside the shared domain because the pinned ports disagree: Rust/Python reject zero, while an unguarded zero trajectory does not progress.

This benchmark does not alias [`collatz`](../collatz/README.md): that benchmark returns a transition count, which is one less than the sequence length. The Java `collatz_conjecture` candidate returns the same full sequence and can map to this contract. The Ruby `3n_plus1` candidate formats the same positive sequence as text.

- [TheAlgorithms/Rust `collatz_sequence.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/collatz_sequence.rs)
- [TheAlgorithms/Python `collatz_sequence.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/collatz_sequence.py)
- [TheAlgorithms/Julia `collatz_sequence.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/collatz_sequence.jl)
- [TheAlgorithms/JavaScript `CollatzSequence.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/CollatzSequence.js)
- [TheAlgorithms/Java `CollatzConjecture.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/CollatzConjecture.java)
- [TheAlgorithms/Ruby `3nPlus1.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/maths/3nPlus1.rb)

## Workload and recording

The workload covers start `1`, even and odd transitions, the long trajectory from `837799`, the upper input boundary, and invalid starts. All nine ports use the shared `i64_array_bytes_output` ABI.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm collatz_sequence --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/c/collatz_sequence/rust/build.json
```
