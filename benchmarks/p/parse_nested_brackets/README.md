# Parse nested brackets

## Contract

Input is `[text_length, ASCII bytes...]`, with at most 128 bytes. The parser uses fixed `<` and `>` delimiters, matching the pinned TypeScript defaults. The input must contain properly nested, matched brackets; other ASCII text is allowed and ignored outside tags. Malformed arrays, non-ASCII values, unmatched delimiters, or nesting errors return `-1`.

For each tag, the parser emits the whole matched substring first, then recursively emits tags inside its content. This gives outer-before-inner depth-first order, while sibling tags retain left-to-right order. The variable-length tag list is observed through a polynomial hash modulo 1,000,000,007: for each emitted byte, `h = (257*h + byte + 1) mod 1,000,000,007`, starting at zero. No tags produce zero.

## Source review

The pinned TypeScript `parseNestedBrackets` scans by nesting depth. When it closes a top-level bracket pair, it appends that entire tag and concatenates a recursive parse of its inner text. The benchmark fixes the default `<` and `>` delimiters and bounds text to ASCII, excluding malformed nesting behavior from the source's permissive scanner.

Pinned source: [TypeScript `parse_nested_brackets.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/other/parse_nested_brackets.ts).

## Workload and implementations

[`workload.json`](workload.json) includes empty input, a single tag, sibling tags, nested tags, surrounding text, deeper nesting, and malformed delimiter inputs. The [runtime oracle](../../parse_nested_brackets_oracle.py) follows the same traversal and encoding.

| Language | Port |
|---|---|
| C | [`c/p/parse_nested_brackets.c`](../../../c/p/parse_nested_brackets.c) |
| C3 | [`c3/p/parse_nested_brackets.c3`](../../../c3/p/parse_nested_brackets.c3) |
| C++ | [`cpp/p/parse_nested_brackets.cpp`](../../../cpp/p/parse_nested_brackets.cpp) |
| Elisa | [`elisa/p/parse_nested_brackets.elisa`](../../../elisa/p/parse_nested_brackets.elisa) |
| Nim | [`nim/p/parse_nested_brackets.nim`](../../../nim/p/parse_nested_brackets.nim) |
| Odin | [`odin/p/parse_nested_brackets.odin`](../../../odin/p/parse_nested_brackets.odin) |
| Rust | [`rust/p/parse_nested_brackets.rs`](../../../rust/p/parse_nested_brackets.rs) |
| V | [`v/p/parse_nested_brackets.v`](../../../v/p/parse_nested_brackets.v) |
| Zig | [`zig/p/parse_nested_brackets.zig`](../../../zig/p/parse_nested_brackets.zig) |
