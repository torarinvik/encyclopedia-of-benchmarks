# Boyer–Moore Majority Vote

This benchmark returns the value that occurs strictly more than half the time in an array. Inputs contain 1 to 256 signed 64-bit values; when no strict majority exists, the result is -1. The portable implementation uses Boyer–Moore cancellation and a verification pass.

The shared behavior matches [TheAlgorithms/C LeetCode 169](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/169.c) and [TheAlgorithms/C-Sharp BoyerMooreMajorityVote](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Other/BoyerMooreMajorityVote.cs). The generalized [Python majority vote](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/other/majority_vote_algorithm.py) is equivalent with its threshold parameter fixed at 2. Java's `MajorityElement` candidate uses a different `>= floor(n/2)` threshold and can return multiple elements, so it remains a separate algorithm candidate.

The nine portable ports use the `i64_array_scalar` ABI and reside in each language's `b` folder. The verifier checks exhaustive short arrays, generated majority and no-majority inputs, full signed 64-bit values, and length bounds against a frequency-count oracle.

Build with `python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm boyer_moore_majority_vote --language LANGUAGE` and record with `python3 benchmarks/run_i64_array_scalar.py --algorithm boyer_moore_majority_vote`. Verify with `python3 benchmarks/verify_boyer_moore_majority_vote.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1`.
