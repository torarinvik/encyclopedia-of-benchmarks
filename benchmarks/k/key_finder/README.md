# Key Finder

This package ports the heuristic in the pinned [TheAlgorithms/JavaScript `KeyFinder.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Ciphers/KeyFinder.js).

## Contract

The `i64_array_scalar` input is `[text_length, ASCII bytes...]`. Text length is 0–256 and the input must contain exactly one count followed by that many bytes. Bytes must be printable ASCII 32–126, excluding digits 48–57. This bounded domain avoids the source's browser-only DOM writes on digit wraparound and keeps JavaScript code units identical to input bytes.

The algorithm tries forward Caesar shifts from 0 through 25. It shifts ASCII uppercase and lowercase letters with wraparound and preserves every other admitted byte. For each shifted text, it scans for any exact, case-sensitive phrase from the source's word bank, in source order:

`I `, `You `, `We `, `They `, `He `, `She `, `It `, ` the `, `The `, ` of `, ` is `, `Is `, ` am `, `Am `, ` are `, `Are `, ` have `, `Have `, ` has `, `Has `, ` may `, `May `, ` be `, `Be `.

It returns the first matching shift. It returns 0 when no phrase matches, preserving the source's ambiguity between a no-match and a match at shift 0. Invalid framing, count, byte, or null input returns -1. The valid input has at most 257 values; ports accept one extra value (258 total) so trailing-payload cases are rejected explicitly.

This heuristic is distinct from `brute_force_caesar_cipher`, which emits all 26 candidate texts, and `decrypt_caesar_with_chi_squared`, which selects a candidate using letter-frequency scoring.

## Workload and oracle

[`workload.json`](workload.json) covers keys 0, 1, 12, and 25, no-match and empty inputs, case-sensitive phrases, maximum length, domain boundaries, and malformed framing. The independent oracle is [`key_finder_oracle.py`](../../key_finder_oracle.py).

## Language ports

- C: [`c/k/key_finder.c`](../../../c/k/key_finder.c)
- C3: [`c3/k/key_finder.c3`](../../../c3/k/key_finder.c3)
- C++: [`cpp/k/key_finder.cpp`](../../../cpp/k/key_finder.cpp)
- Elisa: [`elisa/k/key_finder.elisa`](../../../elisa/k/key_finder.elisa)
- Nim: [`nim/k/key_finder.nim`](../../../nim/k/key_finder.nim)
- Odin: [`odin/k/key_finder.odin`](../../../odin/k/key_finder.odin)
- Rust: [`rust/k/key_finder.rs`](../../../rust/k/key_finder.rs)
- V: [`v/k/key_finder.v`](../../../v/k/key_finder.v)
- Zig: [`zig/k/key_finder.zig`](../../../zig/k/key_finder.zig)
