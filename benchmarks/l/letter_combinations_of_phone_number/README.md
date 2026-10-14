# Letter combinations of a phone number

This benchmark recursively enumerates the Cartesian product of phone keypad letters for a digit sequence. It uses the standard mappings for digits 2 through 9, with four letters for 7 and 9. It is cataloged under the algorithm name in `benchmarks/l/letter_combinations_of_phone_number/`.

## Contract

- Inputs contain at most six signed 64-bit values, each from 2 through 9.
- The result is the number of combinations. The empty input has zero combinations; invalid digits or inputs longer than six return `-1`.
- Each combination is written in lexicographic product order to a caller-provided byte buffer, with each combination occupying exactly `input_length` consecutive bytes. No separators or terminators are written.
- If the buffer is too small, the function returns `-2` without writing output.
- For an input of length `n`, the required buffer size is `combination_count * n`. The maximum is 24,576 bytes for six occurrences of digit 7 or 9.

The recursive implementation partitions the output into one contiguous block per letter at each digit, then fills that digit's position in every row of its block. This produces the same ordered Cartesian product without allocating a string list inside the timed function.

The JavaScript `LetterCombination.js` and Java `LetterCombinationsOfPhoneNumber.java` candidates implement this same keypad-product algorithm. The JavaScript filename is recorded as an alias of this canonical benchmark to avoid counting the same algorithm twice. The shared benchmark uses the standard 2–9 keypad domain and empty-input behavior.

## Workload and verification

`workload.json` defines valid and invalid boundary cases, including the maximum six-digit output. The verifier checks every digit sequence of lengths zero through four, deterministic longer sequences, invalid digits, and an overlength input against a Python Cartesian-product oracle.

Build using the `i64_array_bytes_output` ABI family. `benchmarks/run_i64_array_bytes_output.py` records workload measurements, and `benchmarks/verify_i64_array_bytes_output.py` checks the nine language ports and their records.
