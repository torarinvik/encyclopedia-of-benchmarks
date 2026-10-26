# Fibonacci universal integer code

This profile encodes each nonnegative input integer independently using the chapter’s Fibonacci code. For value `x`, form the Zeckendorf representation of `x+1` using weights `F0=1`, `F1=2`, `Fi=F(i-1)+F(i-2)`, emit its coefficient bits from lowest weight to highest, then append a sentinel `1`. The concatenated codewords are self-delimiting. The source examples include `0 -> 11`, `1 -> 011`, `2 -> 0011`, and `3 -> 1011`.

Input is `[n,values...]`, with `1<=n<=32` and values in `0..1,000,000`. Output is the concatenated ASCII bit string. Each codeword is at most 30 bytes, so output is at most 960 bytes; input is at most 33 words. Invalid input returns `-1`; null or short output returns `-2` without writing.

The package covers the Fibonacci code only. The chapter also discusses unary, binary, Elias, and byte-aligned codes, which are not included in this profile. It is distinct from local packages that compute Fibonacci numbers or search Fibonacci sequences.

## Implementations

| Language | Source |
|---|---|
| C | [`c/f/fibonacci_integer_code.c`](../../../c/f/fibonacci_integer_code.c) |
| C3 | [`c3/f/fibonacci_integer_code.c3`](../../../c3/f/fibonacci_integer_code.c3) |
| C++ | [`cpp/f/fibonacci_integer_code.cpp`](../../../cpp/f/fibonacci_integer_code.cpp) |
| Elisa | [`elisa/f/fibonacci_integer_code.elisa`](../../../elisa/f/fibonacci_integer_code.elisa) |
| Nim | [`nim/f/fibonacci_integer_code.nim`](../../../nim/f/fibonacci_integer_code.nim) |
| Odin | [`odin/f/fibonacci_integer_code.odin`](../../../odin/f/fibonacci_integer_code.odin) |
| Rust | [`rust/f/fibonacci_integer_code.rs`](../../../rust/f/fibonacci_integer_code.rs) |
| V | [`v/f/fibonacci_integer_code.v`](../../../v/f/fibonacci_integer_code.v) |
| Zig | [`zig/f/fibonacci_integer_code.zig`](../../../zig/f/fibonacci_integer_code.zig) |

Primary oracle: [`fibonacci_integer_code_oracle.py`](../../fibonacci_integer_code_oracle.py). Independent verifier: [`fibonacci_integer_code_verifier_oracle.py`](../../fibonacci_integer_code_verifier_oracle.py).

## Attribution and rights

Based on “Compressing Integer Sequences,” *Encyclopedia of Algorithms* (2016), DOI [10.1007/978-1-4939-2864-4_84](https://doi.org/10.1007/978-1-4939-2864-4_84). Implementations are independently written; no book prose, code, or figures are reproduced. The book remains copyrighted by Springer; attribution does not grant redistribution rights to its contents.
