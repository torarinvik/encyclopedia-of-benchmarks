# Naive shuffler

The naive shuffler visits every array position and swaps that item with a randomly selected item from the entire array. The selection range stays at `0..n-1` for every position, matching the loop in TheAlgorithms/C-Sharp's `NaiveShuffler<T>`. This is distinct from Fisher–Yates, which shrinks the range after each swap.

## Contract

- Input is `[seed, item_count, items...]` in the signed 64-bit array ABI. The seed is in `0..2,147,483,645`, the item count is in `0..256`, and each item is a byte value in `0..255`. Input length must equal `2 + item_count`.
- Each port initializes the same Park–Miller stream with state `seed + 1`, then updates it as `state = (state * 48,271) mod 2,147,483,647`. To choose an index, the implementation rejects the short excess tail of the stream's `0..2,147,483,645` sample range before taking modulo `item_count`.
- The result is the shuffled item sequence as bytes; the function returns the number of bytes written. A malformed input returns `-1`; insufficient output capacity returns `-2` without writing output. An empty array returns zero bytes.

The C# source accepts an optional seed and uses .NET `Random`. This benchmark requires an explicit seed and defines one portable pseudo-random stream so all nine implementations receive the same choices on every platform. The comparison measures the naive swap strategy over a bounded byte array.

## Workload

[`workload.json`](workload.json) includes empty and single-item arrays, repeated values, a fixed seeded example, the full byte range, and malformed inputs. It uses the `i64_array_bytes_output` ABI family.

## Implementations

The nine implementations are independent ports of the source loop. Each uses fixed stack storage and portable integer arithmetic; none requires architecture-specific instructions or flags.

## TheAlgorithms source

- [C# `NaiveShuffler.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Shufflers/NaiveShuffler.cs)

Build with `python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm naive_shuffler --language LANGUAGE` and record with `python3 benchmarks/run_i64_array_bytes_output.py --algorithm naive_shuffler`.
