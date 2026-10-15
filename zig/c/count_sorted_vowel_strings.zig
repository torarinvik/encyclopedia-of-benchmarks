const MAX_INPUT: i64 = 30_000;

/// Count nondecreasing vowel strings via the pinned closed-form product.
export fn count_sorted_vowel_strings(n: i64) i64 {
    if (n < 0 or n > MAX_INPUT) return -1;
    return @divTrunc((n + 4) * (n + 3) * (n + 2) * (n + 1), 24);
}
