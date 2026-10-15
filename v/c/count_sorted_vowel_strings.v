module count_sorted_vowel_strings

const max_input = i64(30_000)

// Count nondecreasing vowel strings via the pinned closed-form product.
@[export: 'count_sorted_vowel_strings']
pub fn count_sorted_vowel_strings(n i64) i64 {
	if n < 0 || n > max_input { return -1 }
	return (n + 4) * (n + 3) * (n + 2) * (n + 1) / 24
}
