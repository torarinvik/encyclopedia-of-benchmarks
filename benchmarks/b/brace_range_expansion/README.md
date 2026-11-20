# Bounded brace range expansion

This package expands one integer or letter sequence embedded in a printable
ASCII pattern. The supported grammar is:

    prefix{start..end[..step]}suffix

The pattern contains exactly one brace pair and one range. Prefix plus suffix
may contain at most 32 bytes. Endpoints are either unsigned decimal integers
of one to four digits or one ASCII letter each; letter endpoints must have the
same case. A range may produce at most 16 items.

The i64-array byte-output input is [length, ascii_byte...], with 1<=length<=64
and exact ABI length length+1. Integer endpoint values are in 0..9999. If
either endpoint starts with zero, generated integers are padded to the larger
endpoint width. A missing step is 1 or -1 according to endpoint direction.
An explicit step is a nonzero signed decimal integer; it must point toward the
endpoint. Step digits are bounded by the 64-byte pattern limit. A correctly
directed step larger in magnitude than every possible endpoint gap emits only
the start term.
The endpoint is included only
when the step reaches it. An equal-endpoint range produces one item for any
explicit nonzero step, whether positive or negative, because no movement is
needed.

Success emits the expanded words in sequence order, separated by NUL bytes
with no final terminator. The maximum is 16 words of 36 bytes each plus 15
separators, or 591 bytes. Invalid input or an expansion over 16 words returns
-1; null or insufficient output returns -2. Errors do not write.

The GNU Bash manual's sequence-expression description is method context for
integer and letter ranges, padding, direction, and left-to-right output. This
bounded profile accepts one range only and defines its own byte framing and
error contract; it does not invoke a shell.

## References and workload

- Primary reference: sequentially emits terms by adding the signed step.
- Independent reference: computes each term from its ordinal index and joins
  the generated words after determining the bounded range size.
- workload.json covers integer and letter ranges, padding, descending and
  omitted steps, a non-dividing step, 16-item output, output capacity, malformed
  expressions, an oversized step, and null input/output.
- Source description: [GNU Bash Reference Manual, Brace Expansion](https://www.gnu.org/software/bash/manual/html_node/Brace-Expansion.html).

## Complexity

For a pattern of `P` bytes producing `B` output bytes, parsing and expansion
take `O(P+B)` time. Staged output and parser state use `O(P+B)` scratch, bounded
to 4096 bytes by this profile.

## Native implementations

| Language | Source |
|---|---|
| C | [c/b/brace_range_expansion.c](../../../c/b/brace_range_expansion.c) |
| C3 | [c3/b/brace_range_expansion.c3](../../../c3/b/brace_range_expansion.c3) |
| C++ | [cpp/b/brace_range_expansion.cpp](../../../cpp/b/brace_range_expansion.cpp) |
| Elisa | [elisa/b/brace_range_expansion.elisa](../../../elisa/b/brace_range_expansion.elisa) |
| Mojo | [mojo/b/brace_range_expansion.mojo](../../../mojo/b/brace_range_expansion.mojo) |
| Nim | [nim/b/brace_range_expansion.nim](../../../nim/b/brace_range_expansion.nim) |
| Odin | [odin/b/brace_range_expansion.odin](../../../odin/b/brace_range_expansion.odin) |
| Rust | [rust/b/brace_range_expansion.rs](../../../rust/b/brace_range_expansion.rs) |
| V | [v/b/brace_range_expansion.v](../../../v/b/brace_range_expansion.v) |
| Zig | [zig/b/brace_range_expansion.zig](../../../zig/b/brace_range_expansion.zig) |

All artifacts are clean-room descriptions or implementations. The inventory
and package helpers are source-only and have not been executed.
