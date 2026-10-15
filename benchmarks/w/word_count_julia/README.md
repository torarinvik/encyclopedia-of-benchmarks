# Julia word count

Count regex-extracted words after lowercasing, following TheAlgorithms/Julia's `word_count` operation. This is distinct from the existing `word_count` benchmark, which splits on literal spaces and reports a total plus the frequency of one requested word.

## Contract

- Input is a raw byte sequence encoded as one integer per `i64`, with length from 0 through 1,000. The bounded domain accepts ASCII values 0 through 127.
- ASCII uppercase letters are lowercased. The Julia pattern `(\w+('\w)?)` is applied; over ASCII, `\w` is letters, digits, and underscore. A token is a maximal word run with an optional apostrophe and exactly one following word byte.
- Output lists each unique token once, sorted in ascending ASCII order, as `word=count` followed by line feed. Empty input or input with no tokens returns zero bytes.
- Invalid length or byte values return `-1`; insufficient output capacity returns `-2`. Output has no trailing NUL.

The sorted line encoding makes Julia's frequency dictionary deterministic across ports. The ASCII input bound preserves the pinned implementation's behavior on this defined subset while avoiding locale and Unicode-version differences among languages.

## Workload

[`workload.json`](workload.json) covers empty and delimiter-only input, mixed-case counting, apostrophe handling, underscores and digits, punctuation boundaries, maximum length, invalid byte values, and length overflow.

## Reviewed source

- [Julia `word_count.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/strings/word_count.jl)

Build with the `i64_array_bytes_output` ABI family and record with `benchmarks/run_i64_array_bytes_output.py`.
