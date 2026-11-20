# Static package inventory

- Algorithm: brace_range_expansion
- ABI: i64_array_bytes_output
- Input: one printable ASCII expression, at most 64 pattern bytes and 65 i64 words including the length header.
- Grammar: prefix{start..end[..step]}suffix, exactly one brace pair and one range; numeric endpoints are at most four digits, letter endpoints are single same-case ASCII letters.
- Bounds: at most 16 output words, at most 32 combined prefix/suffix bytes, 36 bytes per word, and 591 output bytes including NUL separators.
- Numeric leading-zero padding uses the larger endpoint width when either endpoint begins with zero.
- Missing steps follow the endpoint direction. Explicit signed decimal steps must be nonzero and point toward the endpoint. Step text is bounded by the 64-byte pattern; parsers saturate its magnitude above 10,000 because no endpoint gap can exceed 9,999. Thus a correctly directed oversized step emits only the start term. Equal endpoints emit one item for either explicit sign.
- Invalid input or over-bound expansion returns -1. Null or insufficient output returns -2. Errors do not write.
- Primary reference: term-by-term addition of the signed increment.
- Independent reference: ordinal-index calculation of every term followed by ordered joining.
- Source context: GNU Bash Reference Manual, Brace Expansion. The bounded package is a single-range subset and does not implement or invoke Bash.

## Native paths

| Language | Path |
|---|---|
| C | c/b/brace_range_expansion.c |
| C3 | c3/b/brace_range_expansion.c3 |
| C++ | cpp/b/brace_range_expansion.cpp |
| Elisa | elisa/b/brace_range_expansion.elisa |
| Mojo | mojo/b/brace_range_expansion.mojo |
| Nim | nim/b/brace_range_expansion.nim |
| Odin | odin/b/brace_range_expansion.odin |
| Rust | rust/b/brace_range_expansion.rs |
| V | v/b/brace_range_expansion.v |
| Zig | zig/b/brace_range_expansion.zig |

## Package artifacts

- README.md, RIGHTS.md, INVENTORY.md, INVENTORY.json, workload.json
- primary_oracle.py, independent_oracle.py, verify_workload.py, check_inventory.py
- The shared `i64_array_bytes_output` runner and verifier register this package.

All package artifacts are clean-room source drafts. No programs, scripts,
tests, checkers, builds, compilers, profilers, or benchmarks have been run.
