# Find palindrome words

This benchmark reproduces the text branch of the pinned R `findPalindrome` routine on bounded printable ASCII input. It removes ASCII punctuation, splits on spaces, checks each token after ASCII case folding, and returns the original-case palindrome words in input order. Tokens shorter than two bytes are omitted.

## Contract

- Input is an ASCII byte array of length 0 through 4,096. Only printable bytes 32 through 126 are valid.
- Remove ASCII punctuation (`!` through `/`, `:` through `@`, `[` through `` ` ``, and `{` through `~`) from the input before splitting on spaces.
- Keep words longer than one byte when their ASCII case-folded form is a palindrome. Preserve each word's original case and order.
- The returned word vector is encoded as bytes with NUL separators and no trailing separator. An empty vector has zero output bytes. Invalid input returns -1; insufficient output capacity returns -2.
- The source also accepts numeric R inputs; digit strings are covered by the same text contract. Unicode and locale-specific behavior are outside this ASCII contract.

## Workload and build

[`workload.json`](workload.json) includes the pinned example sentence, mixed case, punctuation, digits, empty input, and invalid bytes. All nine ports use the `i64_array_bytes_output` ABI family.

| Language | Source |
| --- | --- |
| C | [c/f/findpalindrome.c](../../../c/f/findpalindrome.c) |
| C3 | [c3/f/findpalindrome.c3](../../../c3/f/findpalindrome.c3) |
| C++ | [cpp/f/findpalindrome.cpp](../../../cpp/f/findpalindrome.cpp) |
| Elisa | [elisa/f/findpalindrome.elisa](../../../elisa/f/findpalindrome.elisa) |
| Nim | [nim/f/findpalindrome.nim](../../../nim/f/findpalindrome.nim) |
| Odin | [odin/f/findpalindrome.odin](../../../odin/f/findpalindrome.odin) |
| Rust | [rust/f/findpalindrome.rs](../../../rust/f/findpalindrome.rs) |
| V | [v/f/findpalindrome.v](../../../v/f/findpalindrome.v) |
| Zig | [zig/f/findpalindrome.zig](../../../zig/f/findpalindrome.zig) |

## Pinned source

The pinned R [`findpalindrome.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/string_manipulation/findpalindrome.r) removes punctuation, splits text into words, compares each word case-insensitively, and returns matching words longer than one character.
