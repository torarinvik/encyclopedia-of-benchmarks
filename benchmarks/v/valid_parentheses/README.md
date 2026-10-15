# Valid Parentheses

This benchmark checks whether a sequence of ASCII bracket code points is properly nested. Inputs contain 0 to 256 values from `()[]{}`. The ABI returns 1 for a valid sequence, 0 for an invalid sequence, and -1 for an unsupported value or an input longer than 256.

The pinned upstream candidates are [TheAlgorithms/C LeetCode 20](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/20.c) and [TheAlgorithms/Java ValidParentheses](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/stacks/ValidParentheses.java).

The nine portable implementations use the `i64_array_scalar` ABI and reside in the `v` folder of each language. The verifier exhausts all bracket strings through length six, checks maximum-length and invalid-input cases, and adds deterministic randomized inputs.

Build with `python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm valid_parentheses --language LANGUAGE` and record with `python3 benchmarks/run_i64_array_scalar.py --algorithm valid_parentheses`. Verify ports with `python3 benchmarks/verify_valid_parentheses.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1`.
