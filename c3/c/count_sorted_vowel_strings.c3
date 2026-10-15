module count_sorted_vowel_strings;

const long MAX_INPUT = 30000L;

// Count nondecreasing vowel strings via the pinned closed-form product.
fn long count_sorted_vowel_strings(long n) @export("count_sorted_vowel_strings") {
    if (n < 0L || n > MAX_INPUT) return -1L;
    return (n + 4L) * (n + 3L) * (n + 2L) * (n + 1L) / 24L;
}
