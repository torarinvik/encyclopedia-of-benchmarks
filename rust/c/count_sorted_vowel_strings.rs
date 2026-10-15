const MAX_INPUT: i64 = 30_000;

/// Count nondecreasing vowel strings via the pinned closed-form product.
#[no_mangle]
pub extern "C" fn count_sorted_vowel_strings(n: i64) -> i64 {
    if !(0..=MAX_INPUT).contains(&n) {
        return -1;
    }
    (n + 4) * (n + 3) * (n + 2) * (n + 1) / 24
}
