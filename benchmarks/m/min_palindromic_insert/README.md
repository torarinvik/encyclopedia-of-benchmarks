# Minimum Palindromic Insertions

This package ports the pinned [TheAlgorithms/R routine](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/string_manipulation/min.palindromic.insert.r). It uses the source’s O(n²) dynamic-programming recurrence and reconstruction order. When the two endpoint choices tie, reconstruction takes the right endpoint, matching the source’s `else` branch. The source function itself is case-sensitive; its interactive CLI lowercases text before calling it, which is outside this package’s function contract.

The `i64_array_bytes_output` input is `[n, printable_ASCII_bytes...]`, where `n` is 1 through 256 and every byte is 32 through 126. The output contains signed little-endian i64 values for insertion count and palindrome length, followed by the reconstructed ASCII bytes. Maximum output capacity is 527 bytes. Invalid input returns `-1`; insufficient capacity returns `-2`; both errors write no bytes. A one-byte string returns itself with zero insertions, using the DP base case (the R source’s `2:n` loop range does not handle a singleton input as written).

See [`workload.json`](workload.json) for tie, case-sensitivity, bounds, malformed-input, and capacity cases. The independent oracle is [`min_palindromic_insert_oracle.py`](../../min_palindromic_insert_oracle.py).

## Language ports

- C: [`c/m/min_palindromic_insert.c`](../../../c/m/min_palindromic_insert.c)
- C3: [`c3/m/min_palindromic_insert.c3`](../../../c3/m/min_palindromic_insert.c3)
- C++: [`cpp/m/min_palindromic_insert.cpp`](../../../cpp/m/min_palindromic_insert.cpp)
- Elisa: [`elisa/m/min_palindromic_insert.elisa`](../../../elisa/m/min_palindromic_insert.elisa)
- Nim: [`nim/m/min_palindromic_insert.nim`](../../../nim/m/min_palindromic_insert.nim)
- Odin: [`odin/m/min_palindromic_insert.odin`](../../../odin/m/min_palindromic_insert.odin)
- Rust: [`rust/m/min_palindromic_insert.rs`](../../../rust/m/min_palindromic_insert.rs)
- V: [`v/m/min_palindromic_insert.v`](../../../v/m/min_palindromic_insert.v)
- Zig: [`zig/m/min_palindromic_insert.zig`](../../../zig/m/min_palindromic_insert.zig)
