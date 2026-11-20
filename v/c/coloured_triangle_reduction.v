module coloured_triangle_reduction

fn triangle_binomial_mod_three(n i64, k i64) i64 {
	mut remaining_n := n
	mut remaining_k := k
	mut coefficient := i64(1)
	for remaining_n > 0 || remaining_k > 0 {
		n_digit := remaining_n % 3
		k_digit := remaining_k % 3
		if k_digit > n_digit { return 0 }
		if n_digit == 2 && k_digit == 1 { coefficient = (2 * coefficient) % 3 }
		remaining_n /= 3
		remaining_k /= 3
	}
	return coefficient
}

@[export: 'coloured_triangle_reduction']
pub fn coloured_triangle_reduction(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 258 { return -1 }
	n := unsafe { input[0] }
	if n < 1 || n > 256 || length != usize(n + 1) { return -1 }
	unsafe {
		for index in 0 .. int(n) {
			color := input[index + 1]
			if color < 0 || color > 2 { return -1 }
		}
	}

	rounds := n - 1
	mut total := i64(0)
	unsafe {
		for index in 0 .. int(n) {
			total = (total + triangle_binomial_mod_three(rounds, i64(index))
				* input[index + 1]) % 3
		}
	}
	return if rounds % 2 == 0 { total } else { (3 - total) % 3 }
}
