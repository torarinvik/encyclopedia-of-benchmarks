# Juggler sequence

The Java, JavaScript, and Python sources return the complete Juggler sequence for a positive starting value. The TypeScript source has a different API: it returns the term at a requested zero-based index. All four use the same recurrence: an even term is replaced by `floor(sqrt(n))`, and an odd term by `floor(sqrt(n^3))`.

## Contract

- Input is a signed 64-bit integer `n` from 1 through 25.
- Return the sequence starting with `n`, ending at the first 1, encoded as little-endian unsigned 32-bit values. The return value is the output byte length.
- Return `-1` outside the supported input range.
- Return `-2` if the output buffer is too small; do not write output bytes in that case.
- This bound keeps every intermediate term at or below 52,214, so values fit the Java source's signed `int`, JavaScript's exact integer range, and the output encoding. Sequences contain at most 12 terms, using at most 48 bytes.

The common sequence contract follows the three full-sequence APIs. The TypeScript indexed-term API can produce each position in this sequence by evaluating successive indices. Nonpositive inputs are excluded because the Python source rejects them, while Java and JavaScript can fail to reach the terminating value for zero or negative inputs.

## Workload

[`workload.json`](workload.json) covers the smallest input, known sequences, the upper bound, and invalid signed values. The expected-output oracle in `benchmarks/run_i64_scalar_bytes_output.py` computes each transition with integer square root.

## Upstream sources

- [TheAlgorithms/Java `JugglerSequence.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/JugglerSequence.java)
- [TheAlgorithms/JavaScript `JugglerSequence.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/JugglerSequence.js)
- [TheAlgorithms/Python `juggler_sequence.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/juggler_sequence.py)
- [TheAlgorithms/TypeScript `juggler_sequence.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/juggler_sequence.ts)
