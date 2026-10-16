# Palindrome with stack

## Contract

Input is `[byte_count, ASCII bytes...]` with 0–128 bytes in the range 0–127. The benchmark lowercases ASCII uppercase letters, then returns `1` if the resulting string equals its reverse and `0` otherwise. Malformed arrays, non-ASCII values, and inputs outside the bound return `-1`.

This follows the pinned Java method's sequence: lowercase the string, push each character, pop to build its reverse, then compare. Restricting to ASCII makes Java's locale-sensitive Unicode lowercase behavior portable. Spaces and punctuation remain significant.

## Source review

The pinned Java `checkPalindrome` lowercases every character, pushes it on an instance stack, pops the entire stack into a reverse string, and compares against the lowercase input. The implementation drains its stack on each call. The benchmark uses an explicit bounded byte stack and preserves the same ASCII behavior.

Pinned source: [Java `PalindromeWithStack.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/stacks/PalindromeWithStack.java).

## Workload and implementations

[`workload.json`](workload.json) includes empty and one-character strings, mixed-case and ordinary palindromes, a non-palindrome, significant punctuation, and malformed inputs. The [runtime oracle](../../palindrome_with_stack_oracle.py) implements the same bounded behavior.

| Language | Port |
|---|---|
| C | [`c/p/palindrome_with_stack.c`](../../../c/p/palindrome_with_stack.c) |
| C3 | [`c3/p/palindrome_with_stack.c3`](../../../c3/p/palindrome_with_stack.c3) |
| C++ | [`cpp/p/palindrome_with_stack.cpp`](../../../cpp/p/palindrome_with_stack.cpp) |
| Elisa | [`elisa/p/palindrome_with_stack.elisa`](../../../elisa/p/palindrome_with_stack.elisa) |
| Nim | [`nim/p/palindrome_with_stack.nim`](../../../nim/p/palindrome_with_stack.nim) |
| Odin | [`odin/p/palindrome_with_stack.odin`](../../../odin/p/palindrome_with_stack.odin) |
| Rust | [`rust/p/palindrome_with_stack.rs`](../../../rust/p/palindrome_with_stack.rs) |
| V | [`v/p/palindrome_with_stack.v`](../../../v/p/palindrome_with_stack.v) |
| Zig | [`zig/p/palindrome_with_stack.zig`](../../../zig/p/palindrome_with_stack.zig) |
