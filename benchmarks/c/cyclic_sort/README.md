# Cyclic Sort

Cyclic sort places each value at index `value - 1`, repeating swaps at the current index until it holds the correct value. The pinned Python source validates that its input is a permutation of `1..n`, sorts it in place, and returns the same list. The shared ABI keeps the input read-only, so each port copies the validated array, applies cyclic sort to that copy, and returns the sorted values.

## Contract

- Input is a signed 64-bit integer array with length from 0 through 1,024.
- A valid array is a permutation of the integers from 1 through its length. The empty array is valid.
- Duplicate or out-of-range values return `-1` without producing output.
- The output is the sorted array encoded as little-endian signed 64-bit integers; the return value is the number of values. Insufficient output capacity returns `-2` without writing.
- The sort uses O(n) time and O(n) auxiliary space for the private copy and validation set.

The implementation uses ordinary integer operations, with no architecture-specific instructions or compiler flags.

## Source and verification

The source is [TheAlgorithms/Python `sorts/cyclic_sort.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/sorts/cyclic_sort.py). Its validation rejects repeated values and values outside `1..n` before the cyclic swaps. `workload.json` covers empty, singleton, sorted, reverse, mixed, maximum-length, and invalid inputs. The verifier compares all nine ports against an independent permutation/sort oracle.
