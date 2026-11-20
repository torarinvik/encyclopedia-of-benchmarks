module polydivisible_prefix_search

fn polydivisible_extend(prefix i64, digits i64, base i64, max_digits i64) i64 {
	mut count := i64(1)
	if digits == max_digits { return count }
	next_length := digits + 1
	for digit in 0 .. int(base) {
		candidate := prefix * base + i64(digit)
		if candidate % next_length == 0 {
			count += polydivisible_extend(candidate, next_length, base, max_digits)
		}
	}
	return count
}

@[export: 'polydivisible_prefix_search']
pub fn polydivisible_prefix_search(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 2 { return -1 }
	base := unsafe { input[0] }
	max_digits := unsafe { input[1] }
	if base < 2 || base > 10 || max_digits < 1 || max_digits > 6 { return -1 }
	mut count := i64(0)
	for first_digit in 1 .. int(base) {
		count += polydivisible_extend(i64(first_digit), 1, base, max_digits)
	}
	return count
}
