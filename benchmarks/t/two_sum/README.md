# Two sum

## Contract

The input is a signed 64-bit array packed as `[target, value_0, value_1, ...]`. The target and values must fit signed 32-bit integers, and there may be at most 256 values. Invalid input returns `-2`; a valid input with no pair returns `-1`.

Return the first matching pair found by scanning right indices in ascending order. For a given right index, use the earliest earlier left index with the needed value. The result packs the two zero-based indices as `left_index * 256 + right_index`, so both indices can be recovered from the scalar result. A position is never paired with itself.

The ports use one-pass open addressing. The table capacity is the smallest power of two at least twice the number of values, with 512 slots available at the maximum input length. The integer hash normalizes signed keys modulo `2,147,483,647`, multiplies by `48,271`, and reduces modulo that prime. This keeps all intermediate arithmetic in signed 64-bit range on every target.

The C ABI entry point is:

```c
int64_t two_sum(const int64_t *values, size_t length);
```

## Workload

[`workload.json`](workload.json) includes empty-value, duplicate, negative, signed 32-bit boundary, no-solution, maximum-length, and late-match inputs. Its longest cases exercise all 256 values, including a match at the final two positions.

Build and verify all nine ports with:

```sh
python3 benchmarks/verify_two_sum.py --elisa-compiler /absolute/path/to/elisac
```

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/t/two_sum.c`](../../../c/t/two_sum.c) | Independent portable implementation |
| C3 | [`c3/t/two_sum.c3`](../../../c3/t/two_sum.c3) | Local port |
| C++ | [`cpp/t/two_sum.cpp`](../../../cpp/t/two_sum.cpp) | Independent portable implementation |
| Elisa | [`elisa/t/two_sum.elisa`](../../../elisa/t/two_sum.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/t/two_sum.nim`](../../../nim/t/two_sum.nim) | Local port |
| Odin | [`odin/t/two_sum.odin`](../../../odin/t/two_sum.odin) | Local port |
| Rust | [`rust/t/two_sum.rs`](../../../rust/t/two_sum.rs) | Independent portable implementation |
| V | [`v/t/two_sum.v`](../../../v/t/two_sum.v) | Local port |
| Zig | [`zig/t/two_sum.zig`](../../../zig/t/two_sum.zig) | Local port |

## TheAlgorithms references

The inspected implementations use a hash table to find a complement while scanning the input. Their pair ordering differs: the Rust implementation returns the current index first, while Python and JavaScript return the earlier index first. This contract returns indices in ascending order and explicitly fixes the tie rule.

- [Rust `two_sum.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/general/two_sum.rs)
- [Python `two_sum.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/two_sum.py)
- [JavaScript `TwoSum.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/TwoSum.js)
