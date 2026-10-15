module is_square_free

// Return whether positive n has no repeated prime factor.
@[export: 'is_square_free']
pub fn is_square_free(n i64) i64 {
	if n < 1 || n > 1_000_000 { return -1 }
	mut remaining := n
	mut factor := i64(2)
	for factor <= remaining / factor {
		if remaining % factor == 0 {
			remaining /= factor
			if remaining % factor == 0 { return 0 }
		}
		factor++
	}
	return 1
}
