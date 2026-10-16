# Jaro-Winkler similarity

Return the Jaro score with the pinned Python implementation’s common-prefix boost. Strings are packed as ASCII codepoints and bounded to 32 codepoints each.

## Contract

The packed input is `[n1, s1..., n2, s2...]`; both lengths are 0..32 and each codepoint is 0..127. Exact layout is required. Invalid packed input returns `-1e300`. The result is `jaro + 0.1 * prefix_length * (1 - jaro)`, where the matching window radius is `min(n1,n2)//2`, matched positions are consumed once, transpositions are mismatched paired matched characters divided by two with integer floor, and the common prefix is capped at four. Empty/empty returns 0 under the pinned Python code.

The pinned F# variant is not used as the semantic reference: its matcher uses the outer string length, replaces the first matching character even if outside the eligible window, and its transposition count compares whole matched strings as one item. The benchmark follows the pinned Python behavior.

This package uses the `i64_array_float64` ABI family.
