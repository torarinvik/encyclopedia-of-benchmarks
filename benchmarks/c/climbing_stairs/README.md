# Climbing stairs

The pinned Java, JavaScript, Python, and Ruby sources count ordered sequences of one-step and two-step moves that total a requested number of stairs. Their base-case and input-validation behavior differs. This benchmark uses one shared positive-input contract across all nine target languages.

## Contract

- Input is a signed 64-bit integer `n` from 1 through 45.
- Return the number of ordered sequences of moves of size 1 or 2 that total `n`, equal to Fibonacci number `F(n+1)` with `F(0)=0` and `F(1)=1`.
- Return `-1` when `n` is outside 1 through 45.
- The largest result, `F(46) = 1,836,311,903`, fits in signed 32-bit.

All nine ports use the same iterative recurrence with portable integer operations. The benchmark does not require CPU-specific instructions or architecture-specific compiler flags.

## Workload and verification

[`workload.json`](workload.json) includes short and larger valid inputs, the maximum input, and invalid values. [`benchmarks/verify_climbing_stairs.py`](../../verify_climbing_stairs.py) compares all valid inputs and signed-64-bit boundary cases against an independent binomial-coefficient oracle, then checks every published workload result through the benchmark recorder. All nine languages passed 54 oracle inputs and 20 workload records per language on macOS ARM64.

## Upstream sources

- [TheAlgorithms/Java ClimbingStairs.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/ClimbingStairs.java)
- [TheAlgorithms/JavaScript ClimbingStairs.js](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/ClimbingStairs.js)
- [TheAlgorithms/Python climbing_stairs.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/climbing_stairs.py)
- [TheAlgorithms/Ruby climbing_stairs.rb](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/dynamic_programming/climbing_stairs.rb)
