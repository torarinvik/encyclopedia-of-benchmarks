package count_sorted_vowel_strings

MAX_INPUT :: i64(30_000)

// Count nondecreasing vowel strings via the pinned closed-form product.
@(export)
count_sorted_vowel_strings :: proc "c" (n: i64) -> i64 {
	if n < 0 || n > MAX_INPUT do return -1
	return ((n + 4) * (n + 3) * (n + 2) * (n + 1)) / 24
}
