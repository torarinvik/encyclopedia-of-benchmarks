# Longest repeated substring

Return the length of the longest substring that appears at least twice in a single ASCII sequence. The two occurrences may overlap but must have different starting positions. The pinned Java source returns the substring found from a suffix array and Kasai LCP array; this benchmark compares its length, which is independent of tie-breaking among equal-length answers.

## Contract

Input is `[n, ascii_values...]`, with `0 <= n <= 127`, values in `0..127`, and exact length `n + 1`. Invalid input returns `-1`. Ports compute suffix LCP lengths and retain the maximum for distinct suffix starts. Empty and nonrepeating sequences return zero.

The benchmark uses the `i64_array_scalar` ABI family.
