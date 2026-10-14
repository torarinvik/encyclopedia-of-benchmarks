# Fractional knapsack

The pinned sources implement fractional knapsack by choosing the most valuable items per unit of weight first, then taking a fraction of the final item if the remaining capacity is too small. The generic knapsack candidate also contains two C++ copies of this greedy algorithm; its other sources are primarily 0/1 knapsack, so those copies are cross-listed here. The Python `fractional_knapsack_2.py` filename is a second source for the same greedy algorithm.

## Contract

The i64_array_scalar input is [capacity, item_count, weight_0, value_0, ...]. Capacity is from 0 through 1,000,000. Item count is from 0 through 128. Every weight is from 1 through 1,000,000, and every value is from 0 through 1,000,000.

The result is floor(optimal fractional value times 1,000,000), which records six decimal places using integer arithmetic. Items are ordered by exact value-to-weight ratios, compared by cross multiplication. When capacity ends partway through an item, the port adds the truncated fixed-point value for that fraction. The maximum result is 128,000,000,000,000, within signed 64-bit range.

Malformed input, unequal packed item count and input length, nonpositive weights, negative values, or out-of-range values returns -1. An empty item list or zero capacity returns zero. Implementations use fixed-size arrays and portable integer operations.

workload.json publishes 25 cases for density order, fractional selection, exact and partial fits, equal ratios, zero values, maximum item count and output, and invalid inputs. benchmarks/verify_fractional_knapsack.py compares all nine ports with an exact rational oracle over 6,793 traces.

## Implementations

The nine portable implementations are [C](../../../c/f/fractional_knapsack.c), [C3](../../../c3/f/fractional_knapsack.c3), [C++](../../../cpp/f/fractional_knapsack.cpp), [Elisa](../../../elisa/f/fractional_knapsack.elisa), [Nim](../../../nim/f/fractional_knapsack.nim), [Odin](../../../odin/f/fractional_knapsack.odin), [Rust](../../../rust/f/fractional_knapsack.rs), [V](../../../v/f/fractional_knapsack.v), and [Zig](../../../zig/f/fractional_knapsack.zig).

## Upstream references

- [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/greedy_algorithms/knapsack.cpp)
- [Additional C++ copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/greedy_algorithms/knapsack.cpp)
- [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/greedyalgorithms/FractionalKnapsack.java)
- [Lua](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/knapsack/fractional_knapsack.lua)
- [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/greedy_methods/fractional_knapsack.py)
- [Additional Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/greedy_methods/fractional_knapsack_2.py)
- [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/dynamic_programming/fractional_knapsack.rs)
