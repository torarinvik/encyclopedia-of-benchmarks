# Strong Password Predicate

This package benchmarks the deterministic `is_strong_password` predicate in the pinned [TheAlgorithms/Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/other/password.py). The same file's password generators and command-line entry point are outside this package.

## Contract

The `i64_array_scalar` input is exactly `[min_length, text_length, ascii_bytes...]`. Both lengths are in `0..=256`, and the payload contains exactly `text_length` values, each in `0..=127`. Each byte represents one Python ASCII character; NUL and other control bytes are accepted and count toward the length.

Return `1` when the text length meets `min_length` and the text contains at least one ASCII uppercase letter, lowercase letter, digit, and punctuation character. Otherwise return `0`. These are the source's exact categories: `A..Z`, `a..z`, `0..9`, and the Python `string.punctuation` ranges 33–47, 58–64, 91–96, and 123–126. Invalid shape or values return `-1`. The maximum packed input is 258 signed i64 values.

The predicate's `min_length` parameter is explicit in this ABI, with the source default of 8 represented by an input value of 8. The bounded ASCII domain preserves Python's length and membership behavior one character per byte.

## Workload and oracle

[`workload.json`](workload.json) covers the default threshold, exact length boundaries, every missing character class, punctuation endpoints, NUL/control bytes, the 256-character maximum, and malformed inputs. The independent [`is_strong_password_oracle.py`](../../is_strong_password_oracle.py) defines the expected result.

## Language ports

- C: [`c/i/is_strong_password.c`](../../../c/i/is_strong_password.c)
- C3: [`c3/i/is_strong_password.c3`](../../../c3/i/is_strong_password.c3)
- C++: [`cpp/i/is_strong_password.cpp`](../../../cpp/i/is_strong_password.cpp)
- Elisa: [`elisa/i/is_strong_password.elisa`](../../../elisa/i/is_strong_password.elisa)
- Nim: [`nim/i/is_strong_password.nim`](../../../nim/i/is_strong_password.nim)
- Odin: [`odin/i/is_strong_password.odin`](../../../odin/i/is_strong_password.odin)
- Rust: [`rust/i/is_strong_password.rs`](../../../rust/i/is_strong_password.rs)
- V: [`v/i/is_strong_password.v`](../../../v/i/is_strong_password.v)
- Zig: [`zig/i/is_strong_password.zig`](../../../zig/i/is_strong_password.zig)
