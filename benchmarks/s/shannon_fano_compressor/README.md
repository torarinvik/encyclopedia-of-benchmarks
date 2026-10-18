# Shannon–Fano compressor

This benchmark preserves the pinned C# `ShannonFanoCompressor.Compress` pipeline. It is distinct from [`shannon_fano`](../shannon_fano/README.md): its injected splitter is the C# `NaiveKnapsackSolver`, which greedily selects a subset in first-occurrence order rather than balancing a frequency-sorted contiguous range.

## Contract

The ABI is `i64_array_bytes_output`. Input is `[text_length, ASCII codes...]`, with text length 0..16 and symbols in 0..127. The packed input length must equal `1 + text_length`. A null input pointer with length zero represents C# `null`; like an empty string, it produces an empty compressed string and empty decoding table. A null pointer with positive length is invalid. ASCII keeps each input value to one C# UTF-16 `char`.

For a nonempty input, count each distinct symbol in first-occurrence order. The pinned source targets .NET 8, and its dictionary enumeration supplies that insertion order. The pinned tests inject `NaiveKnapsackSolver<(char,double)>` and `Translator`. The solver walks each node's symbol array in order, keeps a running weight starting at `+0.0`, and includes an item exactly when `running_weight + frequency <= capacity`; it continues scanning after an item does not fit. The value selector passed by the compressor is always 1 and the solver ignores it. `Except(left)` preserves the remaining node-array order.

Each symbol frequency is computed as binary64 `1.0 * count / text_length`. For each recursive node, sum its frequencies from `+0.0` in node-array order, then set capacity to `0.5 * sum`. Apply the greedy solver above to form the left child; the right child is the original-order remainder. Recurse until each child has one symbol. The left path adds `0`, the right path adds `1`. The `<=` capacity comparison includes a symbol that exactly fills the remaining capacity. Tied frequencies are valid: first-occurrence order decides which symbols the greedy pass selects.

An empty string returns an empty compressed string and empty table. If all characters are the same, the source bypasses the tree and returns one bit `1` per input character, with decoding key `1` mapped to that character. Otherwise, `Translator.Translate` scans the input and replaces each one-character symbol key with its code. Its growing-substring loop matches at length one because every compression key is a single character.

Serialize results canonically as: one byte containing compressed-text length; the compressed bits as ASCII `0`/`1`; one byte containing decoding-table entry count; then entries sorted by ascending symbol byte, each encoded as symbol byte, code-length byte, and ASCII code bytes. Empty input serializes to two zero bytes. The bounds imply at most 16 symbols, a maximum tree code length of 15, at most 240 compressed bits, and a maximum serialized result of 514 bytes.

Malformed framing, lengths above 16, and symbols outside ASCII return `-1` before output checks. A null output or capacity below the actual serialized result length returns `-2`; any larger `size_t` capacity is accepted. Errors leave output untouched.

## Pinned source and dependencies

- Compressor: [TheAlgorithms/C-Sharp `ShannonFanoCompressor.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/DataCompression/ShannonFanoCompressor.cs)
- Injected heuristic: [TheAlgorithms/C-Sharp `NaiveKnapsackSolver.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Knapsack/NaiveKnapsackSolver.cs)
- Translator: [TheAlgorithms/C-Sharp `Translator.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/DataCompression/Translator.cs)
- Injection example: [TheAlgorithms/C-Sharp `ShannonFanoCompressorTests.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms.Tests/Compressors/ShannonFanoCompressorTests.cs)

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Independent oracle: [`benchmarks/shannon_fano_compressor_oracle.py`](../../shannon_fano_compressor_oracle.py)
