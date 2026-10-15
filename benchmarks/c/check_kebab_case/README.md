# Check kebab case

Evaluate the pinned JavaScript `CheckKebabCase` predicate over a bounded printable-ASCII string.

## Contract

- The `i64_array_scalar` ABI encodes each input byte as an integer from 32 through 126; at most 4,096 values are accepted.
- Return `1` if the whole string contains no underscore and contains an unanchored `\\w+-\\w` match. Return `0` otherwise.
- For this ASCII domain, `\\w` is an ASCII letter or digit (underscore is excluded by the separate whole-string check). Thus a match exists when a hyphen has an ASCII letter or digit immediately on both sides.
- Return `-2` for a value outside printable ASCII or an input longer than 4,096.

The source uses `/(\\w+)-(\\w)([\\w-]*)/` without anchors, then rejects any string containing `_`. The workload preserves that permissive substring behavior, including digit and uppercase matches. [`workload.json`](workload.json) includes empty, matching, nonmatching, underscore, and invalid values.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/check_kebab_case.c`](../../../c/c/check_kebab_case.c) |
| C3 | [`c3/c/check_kebab_case.c3`](../../../c3/c/check_kebab_case.c3) |
| C++ | [`cpp/c/check_kebab_case.cpp`](../../../cpp/c/check_kebab_case.cpp) |
| Elisa | [`elisa/c/check_kebab_case.elisa`](../../../elisa/c/check_kebab_case.elisa) |
| Nim | [`nim/c/check_kebab_case.nim`](../../../nim/c/check_kebab_case.nim) |
| Odin | [`odin/c/check_kebab_case.odin`](../../../odin/c/check_kebab_case.odin) |
| Rust | [`rust/c/check_kebab_case.rs`](../../../rust/c/check_kebab_case.rs) |
| V | [`v/c/check_kebab_case.v`](../../../v/c/check_kebab_case.v) |
| Zig | [`zig/c/check_kebab_case.zig`](../../../zig/c/check_kebab_case.zig) |

## Upstream source

- [TheAlgorithms JavaScript `CheckKebabCase.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/CheckKebabCase.js)
